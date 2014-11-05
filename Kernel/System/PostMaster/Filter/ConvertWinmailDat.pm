# --
# Kernel/System/PostMaster/Filter/ConvertWinmailDat.pm - the global PostMaster module for OTRS
# Copyright (C) 2011 - 2014 perl-services.de, http://perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PostMaster::Filter::ConvertWinmailDat;

use strict;
use Convert::TNEF;
use File::Temp;
use File::Basename;
use File::Spec;

our $VERSION = 0.02;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Encode
    Kernel::System::Main
    Kernel::System::DB
    Kernel::System::Ticket
    Kernel::System::ConvertWinmailDat::Utils
);

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    $Self->{Debug}   = $ConfigObject->Get('ConvertWinmailDat::Debug');

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $UtilsObject  = $Kernel::OM->Get('Kernel::System::ConvertWinmailDat::Utils');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    for my $Needed (qw(JobConfig GetParam TicketID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $MessageID = $Param{GetParam}->{'Message-Id'};

    if ( $Self->{Debug} ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => 'Run ConvertWinmailDat for Message ' . $MessageID,
        );
    }

    return 1 if !$MessageID;

    my $ArticleID = $UtilsObject->ArticleIDOfMessageIDGet(
        MessageID => $MessageID,
        TicketID  => $Param{TicketID},
    );

    return 1 if !$ArticleID;
   
    my $Attachments = $Param{GetParam}->{Attachment};
    for my $Attachment ( @{$Attachments} ) {
        if ( $Attachment->{Filename} =~ m{winmail\.dat\z}i ) {

            if ( $Self->{Debug} ) {
                $LogObject->Log(
                    Priority => 'notice',
                    Message  => 'Found winmail.dat',
                );
            }

            # save winmail.dat in a temp file
            my $FH = File::Temp->new();
            $MainObject->FileWrite(
                Location => $FH->filename,
                Content  => \($Attachment->{Content}),
                Mode     => 'binmode',
            );

            # create temp dir for attachments
            my $Dir = File::Temp->newdir( CLEANUP => 0 );

            # parse winmail.dat
            my $TNEF = Convert::TNEF->read_in(
                $FH->filename,
                {
                    output_dir => $Dir,
                },
            );

            # attach extracted mail parts
            my $Text         = $TNEF->message;
            my $InmailUserID = $ConfigObject->Get('InmailUserID') || 1;

            MESSAGE:
            for my $Message ( $TNEF->attachments, $Text ) {

                next MESSAGE if !$Message || !$Message->datahandle;

                if ( $Self->{Debug} ) {
                    $LogObject->Log(
                        Priority => 'notice',
                        Message  => "Attachment: " . $Message->name,
                    );
                }

                my $Path     = $Message->datahandle->path;

                my $MimeType;

                eval {
                    my $FileMinusI = qx{file -i $Path};
                    chomp $FileMinusI;

                    $MimeType      = (split /\s+/, $FileMinusI, 2)[1];
                    $MimeType      =~ s{ ; \s* charset=.* }{}xms;
                    1;
                };

                if ( !$MimeType ) {
                    my ($Suffix) = $Message->name =~ m{ \. (.*?) \z }xms;
                    $MimeType    = $UtilsObject->MimeTypeOf( Suffix => $Suffix );
                }

                if ( !$MimeType ) {
                    eval {
                        require File::MimeInfo;
                        $MimeType = File::MimeInfo::mimetype( $Path );
                    };
                }

                if ( $Self->{Debug} ) {
                    $LogObject->Log(
                        Priority => 'notice',
                        Message  => "$Path // $MimeType",
                    );
                }

                $TicketObject->ArticleWriteAttachment(
                    ArticleID   => $ArticleID,
                    Filename    => 
                        $Message->longname ||
                        $Message->name || 
                        'winmail.dat.txt',
                    Content     => $Message->data,
                    ContentType => $MimeType || 'application/octet-stream',
                    UserID      => $InmailUserID,
                );
            }
        }
    }

    return 1;
}

1;



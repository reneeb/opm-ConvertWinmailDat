# --
# Kernel/System/PostMaster/Filter/ConvertWinmailDat.pm - the global PostMaster module for OTRS
# Copyright (C) 2011 perl-services.de, http://perl-services.de/
# --
# $Id: ConvertWinmailDat.pm,v 1.4 2011/05/31 07:56:35 rb Exp $
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

use Kernel::System::ConvertWinmailDat::Utils;

use vars qw($VERSION);
$VERSION = '$Revision: 1.4 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

sub new {
    my $Type  = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Debug} = $Param{Debug} || 0;

    # get needed objects
    for my $Object (
        qw(ConfigObject LogObject DBObject TimeObject MainObject EncodeObject TicketObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    # create needed objects
    $Self->{UtilsObject} = Kernel::System::ConvertWinmailDat::Utils->new( %{$Self} );

    $Self->{Debug} = $Self->{ConfigObject}->Get('ConvertWinmailDat::Debug');

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(JobConfig GetParam TicketID)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my $MessageID = $Param{GetParam}->{'Message-Id'};

    if ( $Self->{Debug} ) {
        $Self->{LogObject}->Log(
            Priority => 'notice',
            Message  => 'Run ConvertWinmailDat for Message ' . $MessageID,
        );
    }

    return 1 if !$MessageID;

    my $ArticleID = $Self->{UtilsObject}->ArticleIDOfMessageIDGet(
        MessageID => $MessageID,
        TicketID  => $Param{TicketID},
    );

    return 1 if !$ArticleID;
   
    my $Attachments = $Param{GetParam}->{Attachment};
    for my $Attachment ( @{$Attachments} ) {
        if ( $Attachment->{Filename} =~ m{winmail\.dat\z}i ) {

            if ( $Self->{Debug} ) {
                $Self->{LogObject}->Log(
                    Priority => 'notice',
                    Message  => 'Found winmail.dat',
                );
            }

            # save winmail.dat in a temp file
            my $FH = File::Temp->new();
            $Self->{MainObject}->FileWrite(
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
            my $InmailUserID = $Self->{ConfigObject}->Get('InmailUserID') || 1;

            MESSAGE:
            for my $Message ( $TNEF->attachments, $Text ) {

                next MESSAGE if !$Message || !$Message->datahandle;

                if ( $Self->{Debug} ) {
                    $Self->{LogObject}->Log(
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
                    $MimeType    = $Self->{UtilsObject}->MimeTypeOf( Suffix => $Suffix );
                }

                if ( !$MimeType ) {
                    eval {
                        require File::MimeInfo;
                        $MimeType = File::MimeInfo::mimetype( $Path );
                    };
                }

                if ( $Self->{Debug} ) {
                    $Self->{LogObject}->Log(
                        Priority => 'notice',
                        Message  => "$Path // $MimeType",
                    );
                }

                $Self->{TicketObject}->ArticleWriteAttachment(
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



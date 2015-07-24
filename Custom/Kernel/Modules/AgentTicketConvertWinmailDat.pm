# --
# Kernel/Modules/AgentTicketConvertWinmailDat.pm - convert tnef attachments of an article
# Copyright (C) 2015 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketConvertWinmailDat;

use strict;
use warnings;

use File::Temp;
use Convert::TNEF;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::Output::HTML::Layout
    Kernel::System::Ticket
    Kernel::System::User
    Kernel::System::Log
    Kernel::System::Web::Request
    Kernel::System::ConvertWinmailDat::Utils
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $UtilsObject  = $Kernel::OM->Get('Kernel::System::ConvertWinmailDat::Utils');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');

    my @Params = (qw(ArticleID));
    my %GetParam;
    for (@Params) {
        $GetParam{$_} = $ParamObject->GetParam( Param => $_ ) || '';
    }

    my %Article = $TicketObject->ArticleGet(
        ArticleID => $GetParam{ArticleID},
        UserID    => $Self->{UserID},
    );

    my %Attachments = $TicketObject->ArticleAttachmentIndex(
        ArticleID => $GetParam{ArticleID},
        UserID    => $Self->{UserID},
    );

    my %AttachmentNamesMap = map{ $Attachments{$_}->{Filename} => $_ } keys %Attachments;

    for my $ID ( keys %Attachments ) {
        my $Attachment = $Attachments{$ID};

        if (
            $Attachment->{ContentType} =~ m{application/ms-tnef} ||
            lc $Attachment->{Filename} eq 'winmail.dat' ) {

            my %AttachmentInfo = $TicketObject->ArticleAttachment(
                ArticleID => $GetParam{ArticleID},
                FileID    => $ID,
                UserID    => $Self->{UserID},
            );

            my $FH = File::Temp->new();
            $MainObject->FileWrite(
                Location => $FH->filename,
                Content  => \($AttachmentInfo{Content}),
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
            my $Text = $TNEF->message;

            MESSAGE:
            for my $Message ( $TNEF->attachments, $Text ) {

                next MESSAGE if !$Message || !$Message->datahandle;

                my $Filename = $Message->longname || $Message->name || 'winmail.dat.txt';

                next MESSAGE if $AttachmentNamesMap{$Filename};

                $Filename = $MainObject->FilenameCleanUp(
                    Filename => $Filename,
                    Type     => 'Local',
                );

                utf8::upgrade( $Filename ) if !utf8::is_utf8( $Filename );

                if ( $Self->{Debug} ) {
                    $LogObject->Log(
                        Priority => 'notice',
                        Message  => "Attachment: " . $Message->name,
                    );
                }

                my $Path = $Message->datahandle->path;

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
                    ArticleID   => $GetParam{ArticleID},
                    Filename    => $Filename,
                    Content     => $Message->data,
                    ContentType => $MimeType || 'application/octet-stream',
                    UserID      => $Self->{UserID},
                );
            }
        }
    }

    my $Baselink  = $LayoutObject->{Baselink};
    my $SessionID = '';
    if ( ! $ConfigObject->Get('SessionUseCookie') ) {
        $SessionID = sprintf '&%s=%s', $LayoutObject->{SessionName}, $LayoutObject->{SessionID};
    }

    return $LayoutObject->Redirect(
        OP => sprintf '%sAction=AgentTicketZoom&TicketID=%s&ArticleID=%s%s',
            $Baselink,
            $Article{TicketID},
            $GetParam{ArticleID},
            $SessionID,
    );
}

1;

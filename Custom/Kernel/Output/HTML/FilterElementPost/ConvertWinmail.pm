# --
# Copyright (C) 2015 - 2022 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ConvertWinmail;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::Language
    Kernel::System::Log
    Kernel::System::Ticket
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Template = $Param{TemplateFile};
    return 1 if !$Template;
    return 1 if !$Param{Templates}->{$Template};

    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my $TicketObject   = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject  = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LogObject      = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');

    # check if article(s) have tnef attachments
    my @ArticleIDs = ${ $Param{Data} } =~ m{
        <a \s+ name="Article ([0-9]+) "
    }xmsg;

    my $Baselink   = $LayoutObject->{Baselink};
    my $ButtonText = $LanguageObject->Translate('Convert TNEF attachments');

    return if ${ $Param{Data} } =~ m{$ButtonText</a>};

    my $TicketID = $ParamObject->GetParam( Param => 'TicketID' );

    ARTICLEID:
    for my $ArticleID ( @ArticleIDs ) {
        my $BackendObject = $ArticleObject->BackendForArticle(
            ArticleID => $ArticleID,
            TicketID  => $TicketID,
        );

        next ARTICLEID if !$BackendObject->can('ArticleAttachmentIndex');

        my %Attachments = $BackendObject->ArticleAttachmentIndex(
            ArticleID        => $ArticleID,
            ExcludePlainText => 1,
            ExcludeHTMLBody  => 1,
            ExcludeInline    => 1,
        );

        next ARTICLEID if !%Attachments;

        my $AttachmentFound;
        for my $ID ( keys %Attachments ) {
            my $Attachment = $Attachments{$ID};

            if ( $Attachment->{ContentType} =~ m{application/ms-tnef} ) {
                $AttachmentFound++;
                last;
            }
            elsif ( lc $Attachment->{Filename} eq 'winmail.dat' ) {
                $AttachmentFound++;
                last;
            }
        }

        if ( !$AttachmentFound ) {
            next ARTICLEID;
        }

        # check if session cookies are used, append the session id otherwise
        my $SessionID = '';
        if ( ! $ConfigObject->Get('SessionUseCookie') ) {
            $SessionID = sprintf '&%s=%s', $LayoutObject->{SessionName}, $LayoutObject->{SessionID};
        }

        # show button in article menu
        my $Button = sprintf qq~
            <li>
                <a href="%sAction=AgentTicketConvertWinmailDat;ArticleID=%s%s" title="%s">%s</a>
            </li>
        ~,
            $Baselink,
            $ArticleID,
            $SessionID,
            $ButtonText,
            $ButtonText;
    
        ${ $Param{Data} } =~ s{
            <a \s+ name="Article $ArticleID" .*?
            <ul \s+ class="Actions"> \K 
        }{$Button}xms;
    }

    return ${ $Param{Data} };
}

1;

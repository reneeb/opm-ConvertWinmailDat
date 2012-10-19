# --
# Kernel/System/ConvertWinmailDat/Utils.pm - helper module for ConvertWinmailDat
# Copyright (C) 2012 Perl-Services.de, http://perl-services.de
# --
# $Id: Utils.pm,v 1.309 2012/03/01 13:40:57 ep Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ConvertWinmailDat::Utils;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.309 $) [1];

=head1 NAME

Kernel::System::ConvertWinmailDat - helper module for ConvertWinmailDat

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Time;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::ConvertWinmailDat::Utils;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $PostMasterObject = Kernel::System::ConvertWinmailDat::Utils->new(
        DBObject     => DBObject,
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        MainObject   => $MainObject,
        LogObject    => $LogObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(DBObject LogObject ConfigObject MainObject EncodeObject)) {
        die "Got no $Needed" if !$Param{$Needed};
    }

    return $Self;
}

=item ArticleIDOfMessageIDGet()

get article id of given message id

    my $ArticleID = $UtilsObject->ArticleIDOfMessageIDGet(
        MessageID=> '<13231231.1231231.32131231@example.com>',
    );

=cut

sub ArticleIDOfMessageIDGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{MessageID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need MessageID!',
        );

        return;
    }

    my $SQL  = 'SELECT id FROM article WHERE a_message_id = ?'; 
    my @Bind = ( \$Param{MessageID} );

    if ( $Param{TicketID} ) {
        $SQL .= ' AND ticket_id = ?';
        push @Bind, \$Param{TicketID};
    }

    # sql query
    return if !$Self->{DBObject}->Prepare(
        SQL   => $SQL,
        Bind  => \@Bind,
        Limit => 10,
    );

    my $ArticleID;
    my $Count = 0;

    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $Count++;
        $ArticleID = $Row[0];
    }

    # no reference found
    return if $Count == 0;

    # one found
    return $ArticleID if $Count == 1;

    # more then one found! that should not be, a message_id should be unique!
    $Self->{LogObject}->Log(
        Priority => 'notice',
        Message  => "The MessageID '$Param{MessageID}' is in your database "
            . "more then one time! That should not be, a message_id should be unique!",
    );

    return;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.309 $ $Date: 2012/03/01 13:40:57 $

=cut

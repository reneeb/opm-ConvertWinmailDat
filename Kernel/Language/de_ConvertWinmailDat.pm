# --
# Kernel/Language/de_ConvertWinmailDat.pm - the German translation of ConvertWinmailDat
# Copyright (C) 2015 - 2023 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_ConvertWinmailDat;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{'Convert TNEF attachments'} = 'Konvertiere TNEF-Anhänge';
    $Lang->{'Enable Debugging for ConvertWinmailDat.'} = 'Debug-Modus für ConvertWinmailDat einschalten.';
    $Lang->{'No'} = 'Nein';
    $Lang->{'Yes'} = 'Ja';
    $Lang->{'Module to convert winmail.dat attachments.'} = 'Modul zum umwandeln von winmail.dat-Anhängen';
    $Lang->{'Add "convert" button to article menu.'} = 'Fügt einen "umwandeln"-Button zum Artikel-Menü';
    $Lang->{'Frontend module registration for the AgentTicketConvertWinmailDat module.'} =
        'Frontendmodul-Registration für das AgentTicketConvertWinmailDat Modul.';
    $Lang->{'Convert winmail.dat attachment.'} = 'Wandele winmail.dat-Anhang um.';
    $Lang->{'Convert winmail.dat'} = 'Wandele winmail.dat um';

    return 1;
}

1;

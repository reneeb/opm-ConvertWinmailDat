# --
# Kernel/Language/hu_ConvertWinmailDat.pm - the Hungarian translation of ConvertWinmailDat
# Copyright (C) 2016 Perl-Services, http://www.perl-services.de
# Copyright (C) 2015 Balázs Úr, http://www.otrs-megoldasok.hu
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::hu_ConvertWinmailDat;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{'Convert TNEF attachments'} = 'TNEF-mellékletek átalakítása';
    $Lang->{'Enable Debugging for ConvertWinmailDat.'} = 'Hibakeresés engedélyezése a ConvertWinmailDat modulnál.';
    $Lang->{'No'} = 'Nem';
    $Lang->{'Yes'} = 'Igen';
    $Lang->{'Module to convert winmail.dat attachments.'} = 'Egy modul winmail.dat mellékletek átalakításához.';
    $Lang->{'Add "convert" button to article menu.'} = '„Átalakítás” gomb hozzáadása a bejegyzés menühöz.';
    $Lang->{'Frontend module registration for the AgentTicketConvertWinmailDat module.'} =
        'Előtétprogram-modul regisztráció az AgentTicketConvertWinmailDat modulhoz.';
    $Lang->{'Convert winmail.dat attachment.'} = 'A winmail.dat melléklet átalakítása.';
    $Lang->{'Convert winmail.dat'} = 'A winmail.dat átalakítása';

    return 1;
}

1;

# --
# Kernel/Language/de_ConvertWinmailDat.pm - the german translation of ConvertWinmailDat
# Copyright (C) 2015 Perl-Services, http://www.perl-services.de
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

    $Lang->{"Convert TNEF attachments"} = 'Konvertiere TNEF-Anhänge';

    return 1;
}

1;

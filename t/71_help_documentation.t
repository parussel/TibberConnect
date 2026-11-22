use strict;
use warnings;
use Test::More;

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    local $/;
    return <$fh>;
}

for my $file (qw(FHEM/70_TibberConnect.pm FHEM/70_TibberLive.pm)) {
    my $text = slurp($file);
    like($text, qr/<h4>Overview<\/h4>.*<h4>Definition<\/h4>.*<h4>Set commands<\/h4>.*<h4>Attributes<\/h4>.*<h4>Important readings<\/h4>/s,
        "$file has structured English help");
    like($text, qr/<h4>&Uuml;bersicht<\/h4>.*<h4>Definition<\/h4>.*<h4>Set-Befehle<\/h4>.*<h4>Attribute<\/h4>.*<h4>Wichtige Readings<\/h4>/s,
        "$file has structured German help");
}

my $connect = slurp('FHEM/70_TibberConnect.pm');
like($connect, qr/forecast snapshot.*actual price.*same plot/s,
    'English help explains parallel forecast and actual-price plot');
like($connect, qr/Prognose-Snapshot.*tats&auml;chlichen Preis.*demselben Plot/s,
    'German help explains parallel forecast and actual-price plot');

my $readme = slurp('README.md');
like($readme, qr/Prognose und tats..chlicher Preis.*parallel.*Plot-Datei/s,
    'dated README notice explicitly describes the parallel plot');

done_testing();

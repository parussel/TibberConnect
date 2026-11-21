use strict;
use warnings;
use lib 't/lib';
use File::Temp qw(tempdir);
use Test::More;

our (%defs, $readingFnAttributes, %attrs, %readings);

sub AttrVal {
    my ($name, $attribute, $default) = @_;
    return exists $attrs{$name}{$attribute}
      ? $attrs{$name}{$attribute}
      : $default;
}

sub ReadingsVal {
    my ($name, $reading, $default) = @_;
    return exists $readings{$name}{$reading}
      ? $readings{$name}{$reading}
      : $default;
}

sub readingsSingleUpdate {
    my ($hash, $reading, $value) = @_;
    $readings{$hash->{NAME}}{$reading} = $value;
}

my $module = $ENV{TIBBERCONNECT_MODULE} || 'FHEM/70_TibberConnect.pm';
my $loaded = do $module;
die "cannot load $module: $@ $!" if !defined $loaded;

sub forecast {
    my ($from, $until, $count) = @_;
    my @intervals;
    my $width = int(($until - $from) / $count);
    for my $index (0 .. $count - 1) {
        my $start = $from + $index * $width;
        my $end = $index == $count - 1 ? $until : $start + $width;
        push @intervals, {
            startsAt  => sprintf('2026-11-21T%02d:%02d:00+01:00',
                12 + int($index / 4), ($index % 4) * 15),
            startEpoch => $start,
            endEpoch   => $end,
            total      => sprintf('%.4f', 0.30 + $index / 100),
        };
    }
    return {
        state      => 'ready',
        startsAt   => $intervals[0]{startsAt},
        endsAt     => '2026-11-22T00:00:00+01:00',
        startEpoch => $from,
        endEpoch   => $until,
        intervals  => \@intervals,
    };
}

subtest 'snapshot path follows forecastLogFile location' => sub {
    is(TibberConnect_ForecastSnapshotPath('/mnt/data/TibberConnect_forecast.log'),
       '/mnt/data/TibberConnect_forecast_snapshot.log', 'suffix before extension');
    is(TibberConnect_ForecastSnapshotPath('./log.with.dots/forecast'),
       './log.with.dots/forecast_snapshot', 'path without extension');
    is(TibberConnect_ForecastSnapshotPath('relative.name.log'),
       'relative.name_snapshot.log', 'relative path remains relative');
    is(TibberConnect_ForecastSnapshotPath(''), undef, 'empty path disables snapshot');
};

subtest 'snapshot device is distinct and sanitized' => sub {
    is(TibberConnect_ForecastSnapshotLogDeviceName({ NAME => 'Tibber Preis' }),
       'Tibber_Preis_ForecastSnapshot', 'device name is FileLog-safe');
};

subtest 'snapshot is created once and survives moving forecast start' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = "$dir/forecast.log";
    my $snapshot = "$dir/forecast_snapshot.log";
    my $hash = { NAME => 'TibberConnect' };
    $attrs{TibberConnect}{forecastLogFile} = $path;

    my $first = forecast(1_000, 4_600, 4);
    my $result = TibberConnect_UpdateForecastSnapshot($hash, $first, 10_000);
    is($result->{fileStatus}, 'ready', 'first snapshot is written');
    ok(-f $snapshot, 'derived snapshot file exists');
    my $original = do { local (@ARGV, $/) = ($snapshot); <> };

    my $moving = forecast(1_900, 4_600, 3);
    $result = TibberConnect_UpdateForecastSnapshot($hash, $moving, 10_900);
    is($result->{state}, 'unchanged', 'same end does not replace snapshot');
    my $after = do { local (@ARGV, $/) = ($snapshot); <> };
    is($after, $original, 'old intervals remain in snapshot');
    is($result->{startEpoch}, 1_000, 'metadata is restored from file');
    is($result->{endEpoch}, 4_600, 'stored horizon is retained');
};

subtest 'later horizon atomically replaces snapshot' => sub {
    my $dir = tempdir(CLEANUP => 1);
    my $path = "$dir/prices.log";
    my $snapshot = "$dir/prices_snapshot.log";
    my $hash = { NAME => 'TibberConnect' };
    $attrs{TibberConnect}{forecastLogFile} = $path;

    TibberConnect_UpdateForecastSnapshot($hash, forecast(1_000, 4_600, 4), 10_000);
    my $result = TibberConnect_UpdateForecastSnapshot(
        $hash, forecast(2_800, 6_400, 4), 11_000);
    is($result->{state}, 'updated', 'later end replaces snapshot');
    is($result->{startEpoch}, 2_800, 'new start is published');
    is($result->{endEpoch}, 6_400, 'new end is published');
    is($result->{intervals}, 4, 'new interval count is published');
    ok(!-e "$snapshot.tmp.$$", 'temporary file is not left behind');
    my $content = do { local (@ARGV, $/) = ($snapshot); <> };
    like($content, qr/TibberConnect_ForecastSnapshot price:/,
        'snapshot uses distinct FileLog device');
};

subtest 'disabled and invalid files have explicit states' => sub {
    my $hash = { NAME => 'Disabled' };
    my $result = TibberConnect_UpdateForecastSnapshot(
        $hash, forecast(1_000, 4_600, 4), 10_000);
    is($result->{fileStatus}, 'disabled', 'missing forecastLogFile disables feature');

    my $dir = tempdir(CLEANUP => 1);
    $attrs{Broken}{forecastLogFile} = "$dir/base.log";
    open my $fh, '>', "$dir/base_snapshot.log" or die $!;
    print {$fh} "not a FileLog row\n";
    close $fh;
    $result = TibberConnect_UpdateForecastSnapshot(
        { NAME => 'Broken' }, forecast(1_000, 4_600, 4), 10_000);
    is($result->{state}, 'repaired', 'invalid snapshot is replaced from valid forecast');
    is($result->{fileStatus}, 'ready', 'repaired file becomes ready');
};

subtest 'module help and supplied plot explain snapshot comparison' => sub {
    open my $module_fh, '<', $module or die $!;
    my $module_text = do { local $/; <$module_fh> };
    close $module_fh;
    like($module_text,
        qr/forecastLogFile.*_snapshot/s,
        'embedded English help explains derived snapshot path');
    like($module_text,
        qr/forecastLogFile.*Prognose-Snapshot/s,
        'embedded German help explains snapshot path source');

    open my $example_fh, '<', 'examples/tibber-forecast.cfg' or die $!;
    my $example = do { local $/; <$example_fh> };
    close $example_fh;
    like($example, qr/FileLog_TibberForecastSnapshot.*_snapshot\.log/s,
        'example defines snapshot FileLog');
    like($example, qr/SVG_TibberPriceComparison/s,
        'example defines comparison SVG');
    like($example, qr/priceForecastSnapshotFrom.*3600/s,
        'fixed range begins one hour before snapshot');
    like($example, qr/priceForecastSnapshotUntil.*3600/s,
        'fixed range ends one hour after snapshot');

    ok(-f 'www/gplot/TibberConnect_PriceComparison.gplot',
        'comparison GPlot is supplied');
};

subtest 'GitHub documentation and update channel publish the tested addition' => sub {
    my %files;
    for my $path (qw(
        README.md
        docs/PRICE_PLANNING.md
        docs/VISUALIZATION.md
        CHANGELOG.md
        CHANGED
        controls_TibberConnect.txt
    )) {
        open my $fh, '<', $path or die $!;
        $files{$path} = do { local $/; <$fh> };
        close $fh;
    }
    like($files{'README.md'}, qr/21\.11\.2026.*Prognose-Snapshot/s,
        'README announces the dated snapshot addition');
    like($files{'docs/PRICE_PLANNING.md'}, qr/priceForecastSnapshotFrom/,
        'price planning documents snapshot readings');
    like($files{'docs/VISUALIZATION.md'}, qr/TibberConnect_PriceComparison/,
        'visualization documents the comparison plot');
    like($files{'CHANGELOG.md'}, qr/2\.1\.0.*2026-11-21/s,
        'changelog contains the new release section');
    like($files{'CHANGED'}, qr/^2026-11-21 TibberConnect 2\.1\.0/m,
        'FHEM change file contains the dated update');
    like($files{'controls_TibberConnect.txt'},
        qr{www/gplot/TibberConnect_PriceComparison\.gplot},
        'update channel delivers the new GPlot');
};

done_testing();

##############################################################################
# 70_TibberConnect.pm
# ----------------------------------------------------------------------------
# Independent FHEM community module initiated by Frank Parussel.
# Contributions and possible future adoption by the FHEM community are welcome.
# This is currently not an official FHEM module.
#
# Copyright (C) 2026 Frank Parussel.
# Project information: https://153er-netz.de/seiten/entwicklung.html
#
# TibberConnect – Stable REST Master Version
#
# Features:
# - Stable REST polling
# - Multi Home support
# - Clean FHEM integration
# - Stale detection
# - Improved readings
# - Robust error handling
# - No WebSocket yet
#
# Define:
# define meinTibber TibberConnect
# set meinTibber token <TOKEN>
# Project information: https://153er-netz.de/seiten/entwicklung.html
#
# Optional:
# attr meinTibber interval 300
# attr meinTibber staleTime 900
# attr meinTibber homeId <ID>
#
##############################################################################

package main;

use strict;
use warnings;
use HttpUtils;
use JSON;
use Time::Local qw(timegm);

our %defs;
our $readingFnAttributes;

#####################################
# Initialize
#####################################

sub TibberConnect_Initialize {
    my ($hash) = @_;

    $hash->{DefFn}    = "TibberConnect_Define";
    $hash->{UndefFn}  = "TibberConnect_Undef";
    $hash->{SetFn}    = "TibberConnect_Set";
    $hash->{GetFn}    = "TibberConnect_Get";
    $hash->{AttrFn}   = "TibberConnect_Attr";

    $hash->{AttrList} =
          "interval"
        . " staleTime"
        . " disable:0,1"
        . " homeId"
        . " priceWindowHours:1,2,3,4,5,6"
        . " $readingFnAttributes"; # includes event-on-change-reading/event-min-interval
}

#####################################
# Define
#####################################

sub TibberConnect_Define {
    my ($hash, $def) = @_;

    my @a = split("[ \t]+", $def);

    return "Usage: define <name> TibberConnect [<TOKEN>]"
      if (int(@a) < 2 || int(@a) > 3);

    my $name  = $a[0];

    $hash->{NAME} = $name;

    RemoveInternalTimer($hash);

    if (int(@a) == 3) {
        my $error = TibberConnect_StoreSecret($hash, $a[2]);
        return $error if defined $error;
        readingsSingleUpdate(
            $hash,
            "migrationNotice",
            "Legacy token copied to protected storage; run 'modify $name TibberConnect' and then save",
            1
        );
        Log3($name, 2, "$name: legacy token copied to protected storage; definition still requires manual cleanup");
    }

    my $token = TibberConnect_ReadSecret($hash);
    if (!defined $token || $token eq "") {
        readingsSingleUpdate($hash, "state", "missingToken", 1);
        readingsSingleUpdate($hash, "connection", "disconnected", 1);
        return undef;
    }

    readingsSingleUpdate($hash, "state", "initialized", 1);
    readingsSingleUpdate($hash, "connection", "starting", 1);

    InternalTimer(time() + 2, "TibberConnect_Start", $hash, 0);

    return undef;
}

#####################################
# Protected credentials
#####################################

sub TibberConnect_SecretKey {
    my ($hash) = @_;
    return "TibberConnect_" . $hash->{NAME} . "_token";
}

sub TibberConnect_StoreSecret {
    my ($hash, $token) = @_;
    return "Token must not be empty"
      if (!defined $token || $token !~ /\S/);

    my $error = setKeyValue(TibberConnect_SecretKey($hash), $token);
    return "Token storage failed" if defined $error && $error ne "";
    delete $hash->{TOKEN};
    return undef;
}

sub TibberConnect_ReadSecret {
    my ($hash) = @_;
    my ($error, $token) = getKeyValue(TibberConnect_SecretKey($hash));
    return undef if defined $error && $error ne "";
    return $token;
}

sub TibberConnect_DeleteSecret {
    my ($hash) = @_;
    my $error = setKeyValue(TibberConnect_SecretKey($hash), undef);
    return "Token deletion failed" if defined $error && $error ne "";
    delete $hash->{TOKEN};
    return undef;
}

sub TibberConnect_MaskSecret {
    my ($token) = @_;
    return "not set" if !defined $token || $token eq "";
    return "****" if length($token) < 9;
    return substr($token, 0, 4) . "..." . substr($token, -4);
}

sub TibberConnect_MaskHomeId {
    my ($home_id) = @_;
    return "not set" if !defined $home_id || $home_id eq "";
    return "****" if length($home_id) < 5;
    return substr($home_id, 0, 2) . "****" . substr($home_id, -2);
}

#####################################
# Start
#####################################

sub TibberConnect_Start {
    my ($hash) = @_;

    TibberConnect_GetHomes($hash);

    my $interval = AttrVal($hash->{NAME}, "interval", 300);

    InternalTimer(
        time() + $interval,
        "TibberConnect_Timer",
        $hash,
        0
    );
}

#####################################
# Timer
#####################################

sub TibberConnect_Timer {
    my ($hash) = @_;

    return if AttrVal($hash->{NAME}, "disable", 0);

    TibberConnect_CheckStale($hash);

    TibberConnect_UpdatePrices($hash, 0);
    TibberConnect_UpdateConsumption($hash, 0);

    my $interval = AttrVal($hash->{NAME}, "interval", 300);

    InternalTimer(
        time() + $interval,
        "TibberConnect_Timer",
        $hash,
        0
    );
}

#####################################
# Stale Detection
#####################################

sub TibberConnect_CheckStale {
    my ($hash) = @_;

    if (TibberConnect_CacheFresh($hash, time())
        && TibberConnect_CurrentInterval($hash->{helper}{priceCache}, time())) {
        readingsSingleUpdate($hash, "state", "active", 1)
          if ReadingsVal($hash->{NAME}, "state", "") ne "active";
        return;
    }

    my $last =
      ReadingsTimestamp(
        $hash->{NAME},
        "lastUpdate",
        0
      );

    return if (!$last);

    my $staleTime =
      AttrVal(
        $hash->{NAME},
        "staleTime",
        900
      );

    my $age =
      time() - time_str2num($last);

    if ($age > $staleTime) {

        readingsSingleUpdate(
            $hash,
            "state",
            "stale",
            1
        );
    }
}

#####################################
# Set
#####################################

sub TibberConnect_Set {
    my ($hash, @a) = @_;

    return "\"set\" needs argument"
      if (int(@a) < 2);

    my $name = shift @a;
    my $cmd  = shift @a;

    if ($cmd eq "token") {
        return "Usage: set $name token <TOKEN>" if int(@a) != 1;
        my $error = TibberConnect_StoreSecret($hash, $a[0]);
        return $error if defined $error;
        readingsSingleUpdate($hash, "state", "initialized", 1);
        readingsSingleUpdate($hash, "connection", "starting", 1);
        RemoveInternalTimer($hash);
        InternalTimer(time() + 1, "TibberConnect_Start", $hash, 0);
        return "Token stored; remove it from command history and save the configuration without plaintext secrets";
    }

    if ($cmd eq "deleteToken") {
        my $error = TibberConnect_DeleteSecret($hash);
        return $error if defined $error;
        RemoveInternalTimer($hash);
        readingsSingleUpdate($hash, "state", "missingToken", 1);
        readingsSingleUpdate($hash, "connection", "disconnected", 1);
        return "Stored token deleted";
    }

    #################################
    # refreshHomes
    #################################

    if ($cmd eq "refreshHomes") {

        TibberConnect_GetHomes($hash);

        return "Refreshing homes";
    }

    #################################
    # selectHome
    #################################

    if ($cmd eq "selectHome") {

        return "Usage: set $name selectHome <homeId>"
          if (int(@a) < 1);

        my $homeId = $a[0];
        my $available = ReadingsVal($name, "availableHomes", "");
        my %known = map { $_ => 1 } grep { $_ ne "" } split(/,/, $available);
        return "Unknown home selection" if !$known{$homeId};

        readingsSingleUpdate(
            $hash,
            "selectedHome",
            $homeId,
            1
        );

        CommandAttr(
            undef,
            "$name homeId $homeId"
        );

        TibberConnect_UpdatePrices($hash, 1);
        TibberConnect_UpdateConsumption($hash, 1);

        return "Home selected";
    }

    #################################
    # update
    #################################

    if ($cmd eq "update") {

        TibberConnect_UpdatePrices($hash, 1);
        TibberConnect_UpdateConsumption($hash, 1);

        return "Update started";
    }

    #################################
    # Set List
    #################################

    my $homeList =
      ReadingsVal(
        $name,
        "availableHomes",
        ""
      );

    return
"Unknown argument $cmd, choose one of refreshHomes:noArg selectHome:$homeList update:noArg token deleteToken:noArg";
}

#####################################
# Get
#####################################

sub TibberConnect_Get {
    my ($hash, @a) = @_;

    return "\"get\" needs argument"
      if (int(@a) < 2);

    my $cmd = $a[1];

    if ($cmd eq "homes") {

        return ReadingsVal(
            $hash->{NAME},
            "availableHomes",
            "none"
        );
    }

    return "Unknown argument $cmd, choose one of homes";
}

#####################################
# Get Homes
#####################################

sub TibberConnect_GetHomes {
    my ($hash) = @_;

    my $query = qq|
    {
      viewer {
        websocketSubscriptionUrl
        homes {
          id
          appNickname

          features {
            realTimeConsumptionEnabled
          }

          address {
            city
            country
          }
        }
      }
    }
    |;

    TibberConnect_SendQuery(
        $hash,
        "Homes",
        $query,
        {},
        \&TibberConnect_GetHomesDone
    );
}

#####################################
# Homes Callback
#####################################

sub TibberConnect_GetHomesDone {
    my ($hash, $json) = @_;

    my $homes =
      $json->{data}{viewer}{homes};

    return if (!$homes);

    my @homeIds;

    readingsBeginUpdate($hash);

    readingsBulkUpdate(
        $hash,
        "websocketSubscriptionUrl",
        $json->{data}{viewer}{websocketSubscriptionUrl}
    ) if defined $json->{data}{viewer}{websocketSubscriptionUrl};

    my $count = 0;

    foreach my $home (@{$homes}) {

        $count++;

        push @homeIds, $home->{id};

        readingsBulkUpdate(
            $hash,
            "home_${count}_id",
            $home->{id}
        );

        readingsBulkUpdate(
            $hash,
            "home_${count}_name",
            $home->{appNickname}
        );

        readingsBulkUpdate(
            $hash,
            "home_${count}_city",
            $home->{address}{city}
        );

        readingsBulkUpdate(
            $hash,
            "home_${count}_liveEnabled",
            $home->{features}{realTimeConsumptionEnabled} ? 1 : 0
        );
    }

    readingsBulkUpdate(
        $hash,
        "availableHomes",
        join(",", @homeIds)
    );

    if (!@homeIds) {
        readingsBulkUpdate($hash, "selectedHome", "");
        readingsBulkUpdate($hash, "connection", "connected");
        readingsBulkUpdate($hash, "state", "noHomes");
        readingsBulkUpdate($hash, "lastUpdate", FmtDateTime(time()));
        readingsEndUpdate($hash, 1);
        return;
    }

    #################################
    # Auto-select first home
    #################################

    my $selected =
      AttrVal($hash->{NAME}, "homeId", "");

    my %known_home = map { $_ => 1 } @homeIds;
    if ((!$selected || !$known_home{$selected}) && scalar(@homeIds) > 0) {

        $selected = $homeIds[0];

        CommandAttr(
            undef,
            "$hash->{NAME} homeId $selected"
        );
    }

    readingsBulkUpdate(
        $hash,
        "selectedHome",
        $selected
    );

    readingsBulkUpdate(
        $hash,
        "connection",
        "connected"
    );

    readingsBulkUpdate(
        $hash,
        "state",
        "connected"
    );

    readingsBulkUpdate(
        $hash,
        "lastUpdate",
        FmtDateTime(time())
    );

    readingsEndUpdate($hash, 1);

    TibberConnect_UpdatePrices($hash, 1);
    TibberConnect_UpdateConsumption($hash, 1);
}

sub TibberConnect_ResolveHome {
    my ($hash, $requested_home_id) = @_;
    return undef if ref($hash) ne "HASH";
    my $available = ReadingsVal($hash->{NAME}, "availableHomes", "");
    my %known = map { $_ => 1 } grep { $_ ne "" } split(/,/, $available);
    my $candidate = $requested_home_id
      || ReadingsVal($hash->{NAME}, "selectedHome", "")
      || AttrVal($hash->{NAME}, "homeId", "");
    return $known{$candidate} ? $candidate : undef;
}

#####################################
# Update Prices
#####################################

sub TibberConnect_ParseIsoEpoch {
    my ($value) = @_;
    return undef if !defined $value;
    my ($year, $month, $day, $hour, $minute, $second, $fraction, $zone, $sign, $offset_hour, $offset_minute) =
      $value =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(\.\d+)?(Z|([+-])(\d{2}):(\d{2}))$/;
    return undef if !defined $zone;
    my $epoch = eval { timegm($second, $minute, $hour, $day, $month - 1, $year) };
    return undef if $@;
    if ($zone ne "Z") {
        my $offset = (($offset_hour * 60) + $offset_minute) * 60;
        $epoch += $sign eq "+" ? -$offset : $offset;
    }
    return $epoch;
}

sub TibberConnect_NormalizePrices {
    my ($payload, $timezone) = @_;
    return [] if ref($payload) ne "HASH";
    my $price_info = ref($payload->{priceInfo}) eq "HASH"
      ? $payload->{priceInfo}
      : $payload;
    my @items;
    for my $bucket (qw(today tomorrow)) {
        push @items, @{$price_info->{$bucket}}
          if ref($price_info->{$bucket}) eq "ARRAY";
    }

    my %by_epoch;
    for my $item (@items) {
        next if ref($item) ne "HASH";
        next if !defined $item->{total} || !defined $item->{startsAt};
        my $epoch = TibberConnect_ParseIsoEpoch($item->{startsAt});
        next if !defined $epoch;
        $by_epoch{$epoch} ||= {%{$item}, startEpoch => $epoch};
    }

    my @intervals = map { $by_epoch{$_} } sort {$a <=> $b} keys %by_epoch;
    for my $index (0 .. $#intervals) {
        my $duration;
        $duration = $intervals[$index + 1]{startEpoch} - $intervals[$index]{startEpoch}
          if $index < $#intervals;
        $duration = $intervals[$index]{startEpoch} - $intervals[$index - 1]{startEpoch}
          if (!defined $duration && $index > 0);
        $duration = 900 if !defined $duration || ($duration != 900 && $duration != 3600);
        $intervals[$index]{durationSeconds} = $duration;
        $intervals[$index]{endEpoch} = $intervals[$index]{startEpoch} + $duration;
    }
    return \@intervals;
}

sub TibberConnect_CurrentInterval {
    my ($intervals, $epoch) = @_;
    return undef if ref($intervals) ne "ARRAY" || !defined $epoch;
    for my $interval (@{$intervals}) {
        return $interval
          if $epoch >= $interval->{startEpoch} && $epoch < $interval->{endEpoch};
        last if $epoch < $interval->{startEpoch};
    }
    return undef;
}

sub TibberConnect_CacheFresh {
    my ($hash, $epoch) = @_;
    $epoch = time() if !defined $epoch;
    return ref($hash->{helper}{priceCache}) eq "ARRAY"
      && @{$hash->{helper}{priceCache}}
      && ($hash->{helper}{priceCacheExpires} || 0) > $epoch;
}

sub TibberConnect_NextCacheExpiry {
    my ($epoch, $has_tomorrow, $random_fraction) = @_;
    $epoch = time() if !defined $epoch;
    $random_fraction = rand() if !defined $random_fraction;
    $random_fraction = 0 if $random_fraction < 0;
    $random_fraction = 1 if $random_fraction > 1;
    my $cycle = $has_tomorrow ? 21600 : 1800;
    return $epoch + $cycle + int(300 * $random_fraction);
}

sub TibberConnect_PublishPrice {
    my ($hash, $price) = @_;
    return if ref($price) ne "HASH";
    readingsBulkUpdate($hash, "current_price",  $price->{total});
    readingsBulkUpdate($hash, "priceEnergy",    $price->{energy});
    readingsBulkUpdate($hash, "priceTax",       $price->{tax});
    readingsBulkUpdate($hash, "priceStartsAt",  $price->{startsAt});
    readingsBulkUpdate($hash, "currency",       $price->{currency});
    readingsBulkUpdate($hash, "priceLevel",     $price->{level});
    readingsBulkUpdate($hash, "price.current",  $price->{total});
    readingsBulkUpdate($hash, "price.energy",   $price->{energy});
    readingsBulkUpdate($hash, "price.tax",      $price->{tax});
    readingsBulkUpdate($hash, "price.level",    $price->{level});
}

sub TibberConnect_FindCheapestWindow {
    my ($intervals, $duration_slots, $range_start, $range_end) = @_;
    return undef if ref($intervals) ne "ARRAY" || !$duration_slots || $duration_slots < 1;
    my $best;
    for my $start_index (0 .. $#{$intervals}) {
        my $last_index = $start_index + $duration_slots - 1;
        last if $last_index > $#{$intervals};
        my $first = $intervals->[$start_index];
        my $last = $intervals->[$last_index];
        next if defined $range_start && $first->{startEpoch} < $range_start;
        next if defined $range_end && $last->{endEpoch} > $range_end;

        my $contiguous = 1;
        my $total = 0;
        for my $index ($start_index .. $last_index) {
            my $item = $intervals->[$index];
            $total += $item->{total};
            if ($index > $start_index
                && $intervals->[$index - 1]{endEpoch} != $item->{startEpoch}) {
                $contiguous = 0;
                last;
            }
        }
        next if !$contiguous;
        next if defined $best && $total >= $best->{total};

        my $ends_at = ($last_index < $#{$intervals}
            && $intervals->[$last_index + 1]{startEpoch} == $last->{endEpoch})
          ? $intervals->[$last_index + 1]{startsAt}
          : $last->{endEpoch};
        $best = {
            startsAt  => $first->{startsAt},
            startEpoch => $first->{startEpoch},
            endsAt    => $ends_at,
            endEpoch  => $last->{endEpoch},
            total     => $total,
            average   => $total / $duration_slots,
            slots     => $duration_slots,
        };
    }
    return $best;
}

sub TibberConnect_FormatIsoEpochWithOffset {
    my ($epoch, $source) = @_;
    return undef if !defined $epoch || !defined $source;
    if ($source =~ /Z$/) {
        my @time = gmtime($epoch);
        return sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',
            $time[5] + 1900, $time[4] + 1, @time[3, 2, 1, 0]);
    }
    my ($sign, $hours, $minutes) = $source =~ /([+-])(\d{2}):(\d{2})$/;
    return undef if !defined $sign;
    my $offset = (($hours * 60) + $minutes) * 60;
    $offset *= -1 if $sign eq '-';
    my @time = gmtime($epoch + $offset);
    return sprintf('%04d-%02d-%02dT%02d:%02d:%02d%s%02d:%02d',
        $time[5] + 1900, $time[4] + 1, @time[3, 2, 1, 0],
        $sign, $hours, $minutes);
}

sub TibberConnect_FindCheapestWindowForDuration {
    my ($intervals, $duration_seconds, $range_start, $range_end) = @_;
    return undef
      if ref($intervals) ne 'ARRAY'
      || !defined $duration_seconds
      || $duration_seconds <= 0;

    my $best;
    for my $start_index (0 .. $#{$intervals}) {
        my $first = $intervals->[$start_index];
        next if defined $range_start && $first->{startEpoch} < $range_start;

        my ($elapsed, $weighted_sum, $last_index) = (0, 0, undef);
        for my $index ($start_index .. $#{$intervals}) {
            my $item = $intervals->[$index];
            last
              if $index > $start_index
              && $intervals->[$index - 1]{endEpoch} != $item->{startEpoch};
            my $item_duration = $item->{endEpoch} - $item->{startEpoch};
            last if $item_duration <= 0;
            $elapsed += $item_duration;
            last if $elapsed > $duration_seconds;
            $weighted_sum += $item->{total} * $item_duration;
            $last_index = $index;
            last if $elapsed == $duration_seconds;
        }
        next if $elapsed != $duration_seconds || !defined $last_index;

        my $last = $intervals->[$last_index];
        next if defined $range_end && $last->{endEpoch} > $range_end;
        my $average = $weighted_sum / $duration_seconds;
        next if defined $best && $average >= $best->{average};

        my $ends_at = ($last_index < $#{$intervals}
            && $intervals->[$last_index + 1]{startEpoch} == $last->{endEpoch})
          ? $intervals->[$last_index + 1]{startsAt}
          : TibberConnect_FormatIsoEpochWithOffset(
                $last->{endEpoch}, $last->{startsAt});
        $best = {
            startsAt       => $first->{startsAt},
            startEpoch     => $first->{startEpoch},
            endsAt         => $ends_at,
            endEpoch       => $last->{endEpoch},
            durationSeconds => $duration_seconds,
            average        => $average,
        };
    }
    return $best;
}

sub TibberConnect_IsoDate {
    my ($starts_at) = @_;
    return undef if !defined $starts_at;
    my ($date) = $starts_at =~ /^(\d{4}-\d{2}-\d{2})T/;
    return $date;
}

sub TibberConnect_NextCalendarDate {
    my ($date) = @_;
    return undef if !defined $date;
    my ($year, $month, $day) = $date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    return undef if !defined $year;
    my $epoch = eval { timegm(0, 0, 12, $day, $month - 1, $year) };
    return undef if $@;
    my @same = gmtime($epoch);
    return undef
      if $same[5] + 1900 != $year
      || $same[4] + 1 != $month
      || $same[3] != $day;
    my @next = gmtime($epoch + 86400);
    return sprintf('%04d-%02d-%02d',
        $next[5] + 1900, $next[4] + 1, $next[3]);
}

sub TibberConnect_PriceStatisticsForDate {
    my ($intervals, $date) = @_;
    return undef if ref($intervals) ne 'ARRAY' || !defined $date;
    my @selected = grep {
        my $item_date = TibberConnect_IsoDate($_->{startsAt});
        defined $item_date && $item_date eq $date;
    } @{$intervals};
    return TibberConnect_PriceStatistics(\@selected, undef, undef);
}

sub TibberConnect_PriceStatistics {
    my ($intervals, $range_start, $range_end) = @_;
    return undef if ref($intervals) ne "ARRAY";
    my @selected = grep {
        (!defined $range_start || $_->{startEpoch} >= $range_start)
          && (!defined $range_end || $_->{endEpoch} <= $range_end)
    } @{$intervals};
    return undef if !@selected;
    my ($sum, $minimum, $maximum, $negative_count) = (0, undef, undef, 0);
    for my $item (@selected) {
        my $value = $item->{total};
        $sum += $value;
        $minimum = $value if !defined $minimum || $value < $minimum;
        $maximum = $value if !defined $maximum || $value > $maximum;
        $negative_count++ if $value < 0;
    }
    return {
        minimum => $minimum, maximum => $maximum,
        average => $sum / @selected, negativeCount => $negative_count,
        count => scalar @selected,
    };
}

sub TibberConnect_FindNegativeWindows {
    my ($intervals) = @_;
    return [] if ref($intervals) ne "ARRAY";
    my @windows;
    my $open;
    for my $item (@{$intervals}) {
        if ($item->{total} < 0) {
            if (!$open || $open->{endEpoch} != $item->{startEpoch}) {
                push @windows, $open if $open;
                $open = {
                    startsAt => $item->{startsAt}, startEpoch => $item->{startEpoch},
                    endsAt => $item->{endEpoch}, endEpoch => $item->{endEpoch}, count => 0,
                };
            }
            $open->{endsAt} = $item->{endEpoch};
            $open->{endEpoch} = $item->{endEpoch};
            $open->{count}++;
        }
        elsif ($open) {
            $open->{endsAt} = $item->{startsAt}
              if $item->{startEpoch} == $open->{endEpoch};
            push @windows, $open;
            $open = undef;
        }
    }
    push @windows, $open if $open;
    return \@windows;
}

sub TibberConnect_PriceForecast {
    my ($intervals, $now) = @_;
    return undef if ref($intervals) ne "ARRAY" || !defined $now;

    my @future = grep {
        defined $_->{startEpoch}
          && defined $_->{endEpoch}
          && $_->{endEpoch} > $_->{startEpoch}
          && $_->{startEpoch} >= $now;
    } @{$intervals};
    return undef if !@future;

    my @contiguous;
    my $previous_end;
    for my $item (@future) {
        last if defined $previous_end && $item->{startEpoch} != $previous_end;
        push @contiguous, $item;
        $previous_end = $item->{endEpoch};
    }
    return undef if !@contiguous;

    my $first = $contiguous[0];
    my $last = $contiguous[-1];
    return {
        intervals       => scalar @contiguous,
        durationSeconds => $last->{endEpoch} - $first->{startEpoch},
        until           => TibberConnect_FormatIsoEpochWithOffset(
            $last->{endEpoch}, $last->{startsAt}),
    };
}

sub TibberConnect_PriceTrend {
    my ($intervals, $now) = @_;
    return undef if ref($intervals) ne "ARRAY" || !defined $now;

    my @future = grep {
        defined $_->{startEpoch}
          && defined $_->{endEpoch}
          && defined $_->{total}
          && $_->{endEpoch} > $_->{startEpoch}
          && $_->{startEpoch} >= $now;
    } @{$intervals};

    my @sample;
    my $previous_end;
    for my $item (@future) {
        last if defined $previous_end && $item->{startEpoch} != $previous_end;
        push @sample, $item;
        $previous_end = $item->{endEpoch};
        last if @sample == 10;
    }
    return undef if @sample != 10;

    my ($first_sum, $last_sum) = (0, 0);
    $first_sum += $sample[$_]{total} for 0 .. 4;
    $last_sum += $sample[$_]{total} for 5 .. 9;
    my $first_average = $first_sum / 5;
    my $last_average = $last_sum / 5;
    my $delta = $last_average - $first_average;
    my $direction = $delta >= 0.005 ? "rising"
      : $delta <= -0.005 ? "falling"
      : "steady";

    return {
        direction       => $direction,
        delta           => $delta,
        intervals       => scalar @sample,
        durationSeconds => $sample[-1]{endEpoch} - $sample[0]{startEpoch},
    };
}

sub TibberConnect_PublishPriceInsights {
    my ($hash, $intervals, $now, $window_hours_override) = @_;
    $now = time() if !defined $now;
    my $window_hours = defined $window_hours_override
      ? $window_hours_override
      : TibberConnect_PriceWindowHours($hash);
    my $current = TibberConnect_CurrentInterval($intervals, $now);
    my $range_start = $current ? $current->{startEpoch} : $now;
    my $range_end = @{$intervals} ? $intervals->[-1]{endEpoch} : $now;
    my $next = TibberConnect_FindCheapestWindowForDuration(
        $intervals, $window_hours * 3600, $range_start, $range_end);
    my $two_hour = TibberConnect_FindCheapestWindowForDuration(
        $intervals, 7200, $range_start, $range_end);
    my $stats = TibberConnect_PriceStatistics($intervals, $range_start, $range_end);
    my $negative = TibberConnect_FindNegativeWindows($intervals);
    my ($next_negative) = grep { $_->{endEpoch} > $now } @{$negative};
    my $forecast = TibberConnect_PriceForecast($intervals, $now);
    my $trend = TibberConnect_PriceTrend($intervals, $now);
    my $date_source = $current ? $current->{startsAt}
      : (@{$intervals} ? $intervals->[0]{startsAt} : undef);
    my $today_stamp = TibberConnect_FormatIsoEpochWithOffset($now, $date_source);
    my $today_date = TibberConnect_IsoDate($today_stamp);
    my $tomorrow_date = TibberConnect_NextCalendarDate($today_date);
    my $today_stats = TibberConnect_PriceStatisticsForDate($intervals, $today_date);
    my $tomorrow_stats = TibberConnect_PriceStatisticsForDate($intervals, $tomorrow_date);

    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "priceIsNegative",
        $current ? ($current->{total} < 0 ? 1 : 0) : "unknown");
    readingsBulkUpdate($hash, "nextCheapestWindowStart",
        $next ? $next->{startsAt} : "unknown");
    readingsBulkUpdate($hash, "nextCheapestWindowEnd",
        $next ? $next->{endsAt} : "unknown");
    readingsBulkUpdate($hash, "nextCheapestWindowAverage",
        $next ? $next->{average} : "unknown");
    readingsBulkUpdate($hash, "nextCheapestWindowHours", $window_hours);
    readingsBulkUpdate($hash, "cheapestWindow2hStart",
        $two_hour ? $two_hour->{startsAt} : "unknown");
    readingsBulkUpdate($hash, "cheapestWindow2hEnd",
        $two_hour ? $two_hour->{endsAt} : "unknown");
    readingsBulkUpdate($hash, "cheapestWindow2hAverage",
        $two_hour ? $two_hour->{average} : "unknown");
    readingsBulkUpdate($hash, "negativePriceIntervals",
        $stats ? $stats->{negativeCount} : "unknown");
    readingsBulkUpdate($hash, "negativePriceNextStart",
        $next_negative ? $next_negative->{startsAt} : "none");
    readingsBulkUpdate($hash, "priceMinimum", $stats ? $stats->{minimum} : "unknown");
    readingsBulkUpdate($hash, "priceMaximum", $stats ? $stats->{maximum} : "unknown");
    readingsBulkUpdate($hash, "priceAverage", $stats ? $stats->{average} : "unknown");
    readingsBulkUpdate($hash, "todayPriceMinimum",
        $today_stats ? $today_stats->{minimum} : "unknown");
    readingsBulkUpdate($hash, "todayPriceMaximum",
        $today_stats ? $today_stats->{maximum} : "unknown");
    readingsBulkUpdate($hash, "todayPriceAverage",
        $today_stats ? $today_stats->{average} : "unknown");
    readingsBulkUpdate($hash, "todayNegativePriceIntervals",
        $today_stats ? $today_stats->{negativeCount} : "unknown");
    readingsBulkUpdate($hash, "todayPriceState",
        $today_stats ? "ready" : "unavailable");
    readingsBulkUpdate($hash, "tomorrowPriceMinimum",
        $tomorrow_stats ? $tomorrow_stats->{minimum} : "unknown");
    readingsBulkUpdate($hash, "tomorrowPriceMaximum",
        $tomorrow_stats ? $tomorrow_stats->{maximum} : "unknown");
    readingsBulkUpdate($hash, "tomorrowPriceAverage",
        $tomorrow_stats ? $tomorrow_stats->{average} : "unknown");
    readingsBulkUpdate($hash, "tomorrowNegativePriceIntervals",
        $tomorrow_stats ? $tomorrow_stats->{negativeCount} : "unknown");
    readingsBulkUpdate($hash, "tomorrowPriceState",
        $tomorrow_stats ? "ready" : "pending");
    readingsBulkUpdate($hash, "priceForecastIntervals",
        $forecast ? $forecast->{intervals} : 0);
    readingsBulkUpdate($hash, "priceForecastDurationMinutes",
        $forecast ? int($forecast->{durationSeconds} / 60) : 0);
    readingsBulkUpdate($hash, "priceForecastUntil",
        $forecast ? $forecast->{until} : "unknown");
    readingsBulkUpdate($hash, "priceForecastState",
        $forecast ? "ready" : "expired");
    readingsBulkUpdate($hash, "priceTrendDirection",
        $trend ? $trend->{direction} : "unavailable");
    readingsBulkUpdate($hash, "priceTrendDelta",
        $trend ? sprintf("%.4f", $trend->{delta}) : "unknown");
    readingsBulkUpdate($hash, "priceTrendIntervals",
        $trend ? $trend->{intervals} : 0);
    readingsBulkUpdate($hash, "priceTrendHorizonMinutes",
        $trend ? int($trend->{durationSeconds} / 60) : 0);
    readingsBulkUpdate($hash, "priceWindowState", $next ? "ready" : "insufficient");
    readingsBulkUpdate($hash, "automationMode", "advisory");
    readingsBulkUpdate($hash, "automationDecision",
        $next ? "would_run:$next->{startsAt}" : "no_complete_window");
    readingsEndUpdate($hash, 1);
}

sub TibberConnect_PriceWindowHours {
    my ($hash) = @_;
    my $name = ref($hash) eq 'HASH' ? $hash->{NAME} : undef;
    return 2 if !defined $name;
    my $value = AttrVal($name, 'priceWindowHours', 2);
    return 2 if !defined $value || $value !~ /^[1-6]$/;
    return int($value);
}

sub TibberConnect_RecalculatePriceInsights {
    my ($hash, $now, $window_hours_override) = @_;
    return if ref($hash) ne 'HASH';
    my $intervals = $hash->{helper}{priceCache};
    return if ref($intervals) ne 'ARRAY' || !@{$intervals};
    TibberConnect_PublishPriceInsights($hash, $intervals,
        defined $now ? $now : time(), $window_hours_override);
}

sub TibberConnect_UpdatePrices {
    my ($hash, $force) = @_;

    if (!$force && TibberConnect_CacheFresh($hash, time())) {
        my $current = TibberConnect_CurrentInterval($hash->{helper}{priceCache}, time());
        if ($current) {
            readingsBeginUpdate($hash);
            TibberConnect_PublishPrice($hash, $current);
            readingsEndUpdate($hash, 1);
        }
        TibberConnect_RecalculatePriceInsights($hash, time());
        return;
    }

    my $homeId =
      AttrVal(
        $hash->{NAME},
        "homeId",
        ""
      );

    return if (!$homeId);

    my $query = q|
    query CurrentPrice($homeId: ID!) {
      viewer {

        home(id: $homeId) {

          appNickname

          address {
            city
            country
          }

          currentSubscription {

            status

            priceInfo(resolution: QUARTER_HOURLY) {

              current {
                total
                energy
                tax
                startsAt
                currency
                level
              }

              today {
                total
                energy
                tax
                startsAt
                currency
                level
              }

              tomorrow {
                total
                energy
                tax
                startsAt
                currency
                level
              }
            }
          }

        }
      }
    }
    |;

    TibberConnect_SendQuery(
        $hash,
        "CurrentPrice",
        $query,
        { homeId => $homeId },
        \&TibberConnect_UpdatePricesDone
    );
}

#####################################
# Update Callback
#####################################

sub TibberConnect_UpdatePricesDone {
    my ($hash, $json) = @_;

    my $home =
      $json->{data}{viewer}{home};

    return if (!$home);

    my $price_info =
      $home->{currentSubscription}{priceInfo};

    my $intervals = TibberConnect_NormalizePrices(
        {priceInfo => $price_info},
        AttrVal($hash->{NAME}, "timezone", "Europe/Berlin")
    );
    my $price = TibberConnect_CurrentInterval($intervals, time())
      || $price_info->{current};

    if (@{$intervals}) {
        $hash->{helper}{priceCache} = $intervals;
        my $has_tomorrow = ref($price_info->{tomorrow}) eq "ARRAY"
          && @{$price_info->{tomorrow}};
        $hash->{helper}{priceCacheExpires} =
          TibberConnect_NextCacheExpiry(time(), $has_tomorrow, undef);
    }

    readingsBeginUpdate($hash);

    #################################
    # Home
    #################################

    readingsBulkUpdate(
        $hash,
        "nickname",
        $home->{appNickname}
    );

    readingsBulkUpdate(
        $hash,
        "city",
        $home->{address}{city}
    );

    readingsBulkUpdate(
        $hash,
        "country",
        $home->{address}{country}
    );

    TibberConnect_PublishPrice($hash, $price);

    if (@{$intervals}) {
        my $duration = $intervals->[0]{durationSeconds};
        readingsBulkUpdate(
            $hash,
            "priceCacheSource",
            $duration == 3600 ? "hourly-fallback" : "quarter-hour"
        );
        readingsBulkUpdate($hash, "priceCacheIntervals", scalar @{$intervals});
        readingsBulkUpdate($hash, "priceCacheUpdated", FmtDateTime(time()));
    }

    #################################
    # System
    #################################

    readingsBulkUpdate(
        $hash,
        "subscriptionStatus",
        $home->{currentSubscription}{status}
    );

    readingsBulkUpdate(
        $hash,
        "connection",
        "connected"
    );

    readingsBulkUpdate(
        $hash,
        "state",
        "active"
    );

    readingsBulkUpdate(
        $hash,
        "lastUpdate",
        FmtDateTime(time())
    );

    readingsEndUpdate($hash, 1);

    TibberConnect_PublishPriceInsights($hash, $intervals, time())
      if @{$intervals};

    TibberConnect_UpdateConsumptionDone($hash, $json)
      if ref($home->{consumption}{nodes}) eq "ARRAY";
}

#####################################
# Consumption and cost
#####################################

sub TibberConnect_UpdateConsumption {
    my ($hash, $force) = @_;
    return if !$force && ($hash->{helper}{consumptionCacheExpires} || 0) > time();
    my $home_id = AttrVal($hash->{NAME}, "homeId", "");
    return if !$home_id;

    my $query = q|
    query Consumption($homeId: ID!) {
      viewer {
        home(id: $homeId) {
          consumption(resolution: DAILY, last: 2) {
            nodes {
              from
              to
              consumption
              cost
              currency
            }
          }
        }
      }
    }
    |;
    TibberConnect_SendQuery(
        $hash, "Consumption", $query, {homeId => $home_id},
        \&TibberConnect_UpdateConsumptionDone
    );
}

sub TibberConnect_UpdateConsumptionDone {
    my ($hash, $json) = @_;
    my $nodes = $json->{data}{viewer}{home}{consumption}{nodes};
    $nodes = [] if ref($nodes) ne "ARRAY";
    my @available = grep { ref($_) eq "HASH" && defined $_->{consumption} } @{$nodes};
    my ($node) = sort {
        ($b->{to} // "") cmp ($a->{to} // "")
          || ($b->{from} // "") cmp ($a->{from} // "")
    } @available;

    readingsBeginUpdate($hash);
    if (!$node) {
        readingsBulkUpdate($hash, "consumptionState", "unavailable");
        readingsBulkUpdate($hash, "consumptionUpdatedAt", FmtDateTime(time()));
        $hash->{helper}{consumptionCacheExpires} = time() + 3600;
        readingsEndUpdate($hash, 1);
        return;
    }

    my $complete = defined $node->{cost}
      && defined $node->{from} && defined $node->{to};
    readingsBulkUpdate($hash, "dailyConsumption", $node->{consumption});
    readingsBulkUpdate($hash, "dailyCost", sprintf("%.4f", $node->{cost}))
      if defined $node->{cost};
    readingsBulkUpdate($hash, "consumptionFrom", $node->{from}) if defined $node->{from};
    readingsBulkUpdate($hash, "consumptionTo", $node->{to}) if defined $node->{to};
    readingsBulkUpdate($hash, "consumptionCurrency", $node->{currency})
      if defined $node->{currency};
    readingsBulkUpdate($hash, "consumptionState", $complete ? "complete" : "partial");
    readingsBulkUpdate($hash, "consumptionUpdatedAt", FmtDateTime(time()));
    $hash->{helper}{consumptionCacheExpires} =
      TibberConnect_NextCacheExpiry(time(), 1, undef);
    readingsEndUpdate($hash, 1);
}

#####################################
# Send Query
#####################################

sub TibberConnect_NextRetryDelay {
    my ($attempt, $random_fraction) = @_;
    $attempt = 0 if !defined $attempt || $attempt < 0;
    $attempt = 8 if $attempt > 8;
    $random_fraction = rand() if !defined $random_fraction;
    $random_fraction = 0 if $random_fraction < 0;
    $random_fraction = 1 if $random_fraction > 1;
    my $base = 2 ** $attempt;
    my $delay = $base * (0.75 + (0.5 * $random_fraction));
    $delay = 1 if $delay < 1;
    $delay = 300 if $delay > 300;
    return $delay;
}

sub TibberConnect_SanitizeError {
    my ($hash, $message) = @_;
    $message = "Request failed" if !defined $message || $message eq "";
    my $token = TibberConnect_ReadSecret($hash);
    $message =~ s/\Q$token\E/[redacted]/g if defined $token && $token ne "";
    $message =~ s/[\r\n]+/ /g;
    return substr($message, 0, 200);
}

sub TibberConnect_RetryQuery {
    my ($context) = @_;
    my $hash = $context->{hash};
    if ($hash && ref($hash->{helper}{retryContexts}) eq "ARRAY") {
        @{$hash->{helper}{retryContexts}} =
          grep { $_ != $context } @{$hash->{helper}{retryContexts}};
    }
    return if !TibberConnect_IsActive($hash);
    TibberConnect_SendQuery(
        $hash, $context->{operation}, $context->{query},
        $context->{variables}, $context->{callback}, $context->{attempt}
    );
}

sub TibberConnect_IsActive {
    my ($hash) = @_;
    return 0 if !$hash || !defined $hash->{NAME};
    return 0 if !exists $defs{$hash->{NAME}} || $defs{$hash->{NAME}} != $hash;
    return AttrVal($hash->{NAME}, "disable", 0) ? 0 : 1;
}

sub TibberConnect_CancelRetryTimers {
    my ($hash) = @_;
    return if !$hash || ref($hash->{helper}{retryContexts}) ne "ARRAY";
    RemoveInternalTimer($_) for @{$hash->{helper}{retryContexts}};
    $hash->{helper}{retryContexts} = [];
}

sub TibberConnect_SendQuery {
    my ($hash, $operation, $query, $variables, $callback, $attempt) = @_;
    $variables ||= {};
    $attempt ||= 0;

    my $token = TibberConnect_ReadSecret($hash);

    if (!defined $token || $token eq "") {
        readingsSingleUpdate($hash, "lastError", "Authentication token is not configured", 1);
        readingsSingleUpdate($hash, "state", "missingToken", 1);
        return;
    }

    my $url =
      "https://api.tibber.com/v1-beta/gql";

    my $payload = {
        query     => $query,
        variables => $variables
    };
    $payload->{operationName} = $operation
      if $query =~ /^\s*(?:query|mutation|subscription)\s+\Q$operation\E\b/;
    my $data = encode_json($payload);

    HttpUtils_NonblockingGet({

        url         => $url,
        method      => "POST",
        timeout     => 15,
        data        => $data,
        hash        => $hash,

        header      => {
            "Authorization" => "Bearer $token",
            "Content-Type"  => "application/json",
            "User-Agent"    => "TibberConnect-FHEM/2.0"
        },

        callback    => sub {

            my ($param, $err, $data) = @_;

            #################################
            # HTTP Error
            #################################

            my $status = $param->{code} || 0;
            my $retryable = ($status == 429 || $status >= 500 || ($err ne "" && $status != 401 && $status != 403));

            if ($retryable && $attempt < 8 && TibberConnect_IsActive($hash)) {
                my $delay = TibberConnect_NextRetryDelay($attempt, undef);
                readingsSingleUpdate($hash, "transportState", "retrying", 1);
                readingsSingleUpdate($hash, "lastError", TibberConnect_SanitizeError($hash, $err || "HTTP $status"), 1);
                my $context = {
                    hash => $hash, operation => $operation, query => $query,
                    variables => $variables, callback => $callback, attempt => $attempt + 1
                };
                push @{$hash->{helper}{retryContexts}}, $context;
                InternalTimer(time() + $delay, "TibberConnect_RetryQuery", $context, 0);
                return;
            }

            if ($err ne "" || $status == 401 || $status == 403 || $status >= 400) {

                readingsSingleUpdate(
                    $hash,
                    "lastError",
                    TibberConnect_SanitizeError($hash, $err || "HTTP $status"),
                    1
                );

                readingsSingleUpdate(
                    $hash,
                    "transportState",
                    ($status == 401 || $status == 403) ? "authenticationError" : "error",
                    1
                );

                return;
            }

            #################################
            # JSON Decode
            #################################

            my $json;

            eval {
                $json = decode_json($data);
            };

            if ($@) {

                readingsSingleUpdate(
                    $hash,
                    "lastError",
                    "Invalid JSON response",
                    1
                );

                readingsSingleUpdate(
                    $hash,
                    "state",
                    "error",
                    1
                );

                return;
            }

            #################################
            # GraphQL Error
            #################################

            if ($json->{errors}) {

                my $msg = TibberConnect_SanitizeError($hash, $json->{errors}[0]{message});

                readingsSingleUpdate(
                    $hash,
                    "lastError",
                    $msg,
                    1
                );

                readingsSingleUpdate(
                    $hash,
                    "state",
                    "error",
                    1
                );

                return;
            }

            #################################
            # OK
            #################################

            readingsSingleUpdate(
                $hash,
                "lastError",
                "",
                1
            );

            readingsSingleUpdate($hash, "transportState", "ok", 1);

            $callback->($hash, $json);
        }
    });
}

#####################################
# Attr
#####################################

sub TibberConnect_Attr {
    my ($command, $name, $attribute, $value) = @_;
    my $hash = $defs{$name};

    if ($attribute eq 'priceWindowHours') {
        if ($command eq 'set'
            && (!defined $value || $value !~ /^[1-6]$/)) {
            return 'priceWindowHours must be an integer in the range 1..6';
        }
        my $effective_hours = $command eq 'set' ? int($value) : 2;
        TibberConnect_RecalculatePriceInsights(
            $hash, time(), $effective_hours) if $hash;
        return undef;
    }

    if ($attribute eq "disable") {
        if ($command eq "set" && $value) {
            RemoveInternalTimer($hash) if $hash;
            TibberConnect_CancelRetryTimers($hash);
        }
        elsif ($hash && defined TibberConnect_ReadSecret($hash)) {
            RemoveInternalTimer($hash);
            InternalTimer(time() + 1, "TibberConnect_Start", $hash, 0);
        }
    }
    return undef;
}

#####################################
# Undef
#####################################

sub TibberConnect_Undef {
    my ($hash, $arg) = @_;

    RemoveInternalTimer($hash);
    TibberConnect_CancelRetryTimers($hash);

    return undef;
}

1;

=pod

=begin html

<a id="TibberConnect"></a><h3>TibberConnect</h3>
<p>Define: <code>define TibberConnect TibberConnect</code>, then store the secret
with <code>set TibberConnect token &lt;TOKEN&gt;</code>. Use
<code>refreshHomes</code>, <code>selectHome</code>, and <code>update</code>.
The module caches quarter-hour prices and retrieves delayed consumption
separately. The token is not part of the definition.</p>
<p><code>attr TibberConnect priceWindowHours &lt;1..6&gt;</code> selects the exact
contiguous duration for <code>nextCheapestWindowStart</code>,
<code>nextCheapestWindowEnd</code>, and <code>nextCheapestWindowAverage</code>.
The default is two hours. Fixed <code>cheapestWindow2h...</code> readings remain
compatible. <code>todayPrice...</code> and <code>tomorrowPrice...</code> expose
separate calendar-day statistics. <code>priceForecast...</code> exposes the
contiguous remaining price horizon: interval count, duration in minutes, end,
and state. <code>priceTrend...</code> compares the next ten complete price
intervals without another API request. All planning output is advisory.</p>
<p>Community project information:
<a href="https://153er-netz.de/seiten/entwicklung.html">153er-netz.de / Development</a></p>

=end html

=begin html_DE

<a id="TibberConnect-DE"></a><h3>TibberConnect</h3>
<p>Definition: <code>define TibberConnect TibberConnect</code>. Danach das
Geheimnis mit <code>set TibberConnect token &lt;TOKEN&gt;</code> gesch&uuml;tzt
speichern. Verf&uuml;gbar sind <code>refreshHomes</code>,
<code>selectHome</code> und <code>update</code>. Viertelstundenpreise werden
gepuffert; verz&ouml;gerte Verbrauchsdaten werden getrennt abgerufen.</p>
<p><code>attr TibberConnect priceWindowHours &lt;1..6&gt;</code> w&auml;hlt die exakte,
zusammenh&auml;ngende Dauer f&uuml;r <code>nextCheapestWindowStart</code>,
<code>nextCheapestWindowEnd</code> und <code>nextCheapestWindowAverage</code>.
Ohne Attribut gelten zwei Stunden. Feste <code>cheapestWindow2h...</code>-Readings
bleiben kompatibel. <code>todayPrice...</code> und
<code>tomorrowPrice...</code> liefern getrennte Tagesstatistiken. Die Ausgabe
<code>priceForecast...</code> zeigt den zusammenh&auml;ngenden verbliebenen
Preisvorrat (Anzahl, Minuten, Ende und Status). Die Ausgabe ist ausschlie&szlig;lich
beratend. <code>priceTrend...</code> vergleicht ohne weitere API-Abfrage die
n&auml;chsten zehn vollst&auml;ndigen Preisintervalle.</p>
<p>Community-Projektinformationen:
<a href="https://153er-netz.de/seiten/entwicklung.html">153er-netz.de / Entwicklung</a></p>

=end html_DE

=cut

##############################################################################
# EOF
##############################################################################

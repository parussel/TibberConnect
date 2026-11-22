##############################################################################
# 70_TibberLive.pm - optional Tibber Pulse live measurements for FHEM
# Independent FHEM community module initiated by Frank Parussel.
# Contributions and possible future adoption by the FHEM community are welcome.
# This is currently not an official FHEM module.
#
# Copyright (C) 2026 Frank Parussel.
# Project information: https://153er-netz.de/seiten/entwicklung/fhem.html
##############################################################################

package main;

use strict;
use warnings;
use JSON;
use Time::Local qw(timegm);

our %defs;
our $readingFnAttributes;
our $TibberLive_VERSION = "2.0.1";

sub TibberLive_Initialize {
    my ($hash) = @_;
    $hash->{DefFn} = "TibberLive_Define";
    $hash->{UndefFn} = "TibberLive_Undef";
    $hash->{SetFn} = "TibberLive_Set";
    $hash->{AttrFn} = "TibberLive_Attr";
    $hash->{AttrList} = "disable:0,1 homeId batteryLifetimeDays batteryInstalledEpoch"
      . " liveEventMode:essential,all $readingFnAttributes";
}

sub TibberLive_Define {
    my ($hash, $definition) = @_;
    my @parts = split(/[ \t]+/, $definition);
    return "Usage: define <name> TibberLive <TibberConnect-device>"
      if @parts != 3;
    my ($name, undef, $connect_name) = @parts;
    $hash->{NAME} = $name;
    my $connect = $defs{$connect_name};
    return "TibberLive requires an existing TibberConnect device"
      if !$connect || ($connect->{TYPE} || "") ne "TibberConnect";
    $hash->{TYPE} = "TibberLive";
    $hash->{CONNECT_DEVICE} = $connect_name;
    my $requested_home = AttrVal($name, "homeId", "");
    my $home_id = TibberConnect_ResolveHome(
        $connect, $requested_home ne "" ? $requested_home : undef);
    if ($home_id) {
        $hash->{HOME_ID} = $home_id;
        readingsSingleUpdate($hash, "homeId", $home_id, 1);
        readingsSingleUpdate($hash, "liveStatus", "starting", 1);
        readingsSingleUpdate($hash, "state", "starting", 1);
    }
    else {
        readingsSingleUpdate($hash, "connection", "waitingForHome", 1);
        readingsSingleUpdate($hash, "liveStatus", "starting", 1);
        readingsSingleUpdate($hash, "state", "waitingForHome", 1);
    }
    TibberLive_InitializeBattery($hash);
    TibberLive_CancelTimers($hash);
    TibberLive_ScheduleReconnect($hash, 2);
    return undef;
}

sub TibberLive_ConnectHash {
    my ($hash) = @_;
    return undef if !defined $hash->{CONNECT_DEVICE};
    return $defs{$hash->{CONNECT_DEVICE}};
}

sub TibberLive_Set {
    my ($hash, @arguments) = @_;
    return '"set" needs argument' if @arguments < 2;
    my $name = shift @arguments;
    my $command = shift @arguments;
    if ($command eq "selectHome") {
        return "Usage: set $name selectHome <homeId>" if @arguments != 1;
        my $connect = TibberLive_ConnectHash($hash);
        my $home_id = TibberConnect_ResolveHome($connect, $arguments[0]);
        return "Unknown home" if !$home_id;
        TibberLive_Close($hash, 1000, "Home selection changed");
        $hash->{HOME_ID} = $home_id;
        CommandAttr(undef, "$name homeId $home_id");
        readingsSingleUpdate($hash, "homeId", $home_id, 1);
        TibberLive_ScheduleReconnect($hash, 1);
        return "Home selected";
    }
    if ($command eq "batteryAgeMonths") {
        return "Usage: set $name batteryAgeMonths 0..12" if @arguments != 1;
        my $error = TibberLive_SetBatteryAgeMonths($hash, $arguments[0], time());
        return $error if defined $error;
        return "Battery age recorded";
    }
    if ($command eq "batteryReplaced") {
        return "Usage: set $name batteryReplaced" if @arguments;
        TibberLive_RecordBatteryReplacement($hash, time());
        return "Battery replacement recorded";
    }
    return "Unknown argument $command, choose one of selectHome batteryAgeMonths:0,1,2,3,4,5,6,7,8,9,10,11,12 batteryReplaced:noArg";
}

sub TibberLive_SocketCapability {
    my ($hash) = @_;
    return "available" if ref($hash->{helper}{socketFactory}) eq "CODE";
    my $loaded = eval {
        require AnyEvent::WebSocket::Client;
        require EV;
        1;
    };
    if ($loaded) {
        $hash->{helper}{socketFactory} = sub {
            TibberLive_AnyEventConnect($_[0]);
        };
        readingsSingleUpdate($hash, "dependencyStatus", "available", 1);
        readingsSingleUpdate($hash, "dependencyRecommendation", "none", 1);
        readingsSingleUpdate($hash, "dependencyInstallCommand", "", 1);
        return "available";
    }
    readingsSingleUpdate($hash, "dependencyStatus", "missing", 1);
    readingsSingleUpdate($hash, "dependencyRecommendation",
        "install AnyEvent::WebSocket::Client and EV", 1);
    readingsSingleUpdate($hash, "dependencyInstallCommand",
        "sudo apt install libanyevent-websocket-client-perl", 1);
    return "optionalDependencyMissing";
}

sub TibberLive_SetState {
    my ($hash, $state) = @_;
    readingsSingleUpdate($hash, "state", $state, 1);
}

sub TibberLive_HomeLiveEnabled {
    my ($hash) = @_;
    my $connect = TibberLive_ConnectHash($hash);
    return 0 if !$connect;
    for my $index (1 .. 100) {
        my $id = ReadingsVal($connect->{NAME}, "home_${index}_id", "");
        last if $id eq "";
        return ReadingsVal($connect->{NAME}, "home_${index}_liveEnabled", 0) ? 1 : 0
          if $id eq $hash->{HOME_ID};
    }
    return 0;
}

sub TibberLive_ConnectionSlotAvailable {
    my ($hash) = @_;
    my $active = 0;
    for my $device (values %defs) {
        next if ref($device) ne "HASH" || ($device->{TYPE} || "") ne "TibberLive";
        next if $device == $hash;
        $active++ if $device->{helper}{socketActive};
    }
    return $active < 2 ? 1 : 0;
}

sub TibberLive_TimerContext {
    my ($hash, $kind) = @_;
    $hash->{helper}{timerContexts}{$kind} ||= {hash => $hash, kind => $kind};
    return $hash->{helper}{timerContexts}{$kind};
}

sub TibberLive_ScheduleReconnect {
    my ($hash, $delay) = @_;
    my $context = TibberLive_TimerContext($hash, "reconnect");
    RemoveInternalTimer($context);
    InternalTimer(time() + $delay, "TibberLive_ReconnectTimer", $context, 0);
}

sub TibberLive_ScheduleWatchdog {
    my ($hash, $when) = @_;
    my $context = TibberLive_TimerContext($hash, "watchdog");
    RemoveInternalTimer($context);
    InternalTimer($when, "TibberLive_WatchdogTimer", $context, 0);
}

sub TibberLive_ScheduleEventPump {
    my ($hash, $when) = @_;
    my $context = TibberLive_TimerContext($hash, "eventPump");
    RemoveInternalTimer($context);
    InternalTimer($when, "TibberLive_EventPumpTimer", $context, 0);
}

sub TibberLive_ScheduleHandshakeTimeout {
    my ($hash, $when) = @_;
    my $previous = $hash->{helper}{timerContexts}{handshake};
    RemoveInternalTimer($previous) if $previous;
    my $context = {hash => $hash, kind => "handshake"};
    $hash->{helper}{timerContexts}{handshake} = $context;
    $context->{generation} = $hash->{helper}{connectGeneration} || 0;
    InternalTimer($when, "TibberLive_HandshakeTimeoutTimer", $context, 0);
}

sub TibberLive_CancelHandshakeTimeout {
    my ($hash) = @_;
    my $context = $hash->{helper}{timerContexts}{handshake};
    RemoveInternalTimer($context) if $context;
}

sub TibberLive_InvalidatePendingConnect {
    my ($hash) = @_;
    my $pending = exists $hash->{helper}{connectCondition};
    delete $hash->{helper}{connectCondition};
    delete $hash->{helper}{socketClient};
    TibberLive_CancelHandshakeTimeout($hash);
    $hash->{helper}{connectGeneration} = ($hash->{helper}{connectGeneration} || 0) + 1
      if $pending;
}

sub TibberLive_CancelTimers {
    my ($hash) = @_;
    return if ref($hash->{helper}{timerContexts}) ne "HASH";
    RemoveInternalTimer($_) for values %{$hash->{helper}{timerContexts}};
}

sub TibberLive_ReconnectTimer {
    my ($context) = @_;
    RemoveInternalTimer($context);
    TibberLive_Start($context->{hash});
}

sub TibberLive_WatchdogTimer {
    my ($context) = @_;
    RemoveInternalTimer($context);
    TibberLive_Watchdog($context->{hash});
}

sub TibberLive_EventPumpTimer {
    my ($context) = @_;
    RemoveInternalTimer($context);
    my $hash = $context->{hash};
    return if AttrVal($hash->{NAME}, "disable", 0);
    my $ok = eval { EV::run(EV::RUN_NOWAIT()); 1 };
    if (!$ok) {
        my $error = TibberLive_SanitizeError($hash, $@);
        readingsSingleUpdate($hash, "lastError", $error, 1);
        TibberLive_OnClose($hash, 1006, "Event loop failure", undef);
        return;
    }
    TibberLive_ScheduleEventPump($hash, time() + 0.2)
      if $hash->{helper}{socketActive} || $hash->{helper}{connectCondition};
}

sub TibberLive_HandshakeTimeoutTimer {
    my ($context) = @_;
    RemoveInternalTimer($context);
    my $hash = $context->{hash};
    return if AttrVal($hash->{NAME}, "disable", 0);
    return if !exists $hash->{helper}{connectCondition};
    return if ($hash->{helper}{connectGeneration} || 0) != ($context->{generation} || 0);
    TibberLive_InvalidatePendingConnect($hash);
    TibberLive_OnClose($hash, 1006, "WebSocket handshake timeout", undef);
}

sub TibberLive_AnyEventConnect {
    my ($arguments) = @_;
    my $hash = $arguments->{hash};
    my $client = eval {
        AnyEvent::WebSocket::Client->new(
            timeout => 30,
            ssl_no_verify => 0,
            subprotocol => [$arguments->{protocol}],
            http_headers => $arguments->{headers},
        );
    };
    if (!$client) {
        readingsSingleUpdate($hash, "lastError",
            TibberLive_SanitizeError($hash, $@), 1);
        TibberLive_OnClose($hash, 1006, "WebSocket client initialization failed", undef);
        return;
    }
    my $condition = eval { $client->connect($arguments->{url}) };
    if (!$condition) {
        readingsSingleUpdate($hash, "lastError",
            TibberLive_SanitizeError($hash, $@), 1);
        TibberLive_OnClose($hash, 1006, "WebSocket connection failed", undef);
        return;
    }
    $hash->{helper}{socketClient} = $client;
    $hash->{helper}{connectCondition} = $condition;
    my $generation = ($hash->{helper}{connectGeneration} || 0) + 1;
    $hash->{helper}{connectGeneration} = $generation;
    TibberLive_ScheduleHandshakeTimeout($hash, time() + 45);
    TibberLive_ScheduleEventPump($hash, time() + 0.2);
    $condition->cb(sub {
        my ($completed) = @_;
        return if ($hash->{helper}{connectGeneration} || 0) != $generation;
        delete $hash->{helper}{connectCondition};
        TibberLive_CancelHandshakeTimeout($hash);
        my $connection = eval { $completed->recv };
        if (!$connection) {
            delete $hash->{helper}{socketClient};
            readingsSingleUpdate($hash, "lastError",
                TibberLive_SanitizeError($hash, $@), 1);
            TibberLive_OnClose($hash, 1006, "WebSocket handshake failed", undef);
            return;
        }
        if (!$hash->{helper}{socketActive}) {
            delete $hash->{helper}{socketClient};
            eval { $connection->close(1000, "No longer active") };
            return;
        }
        delete $hash->{helper}{socketClient};
        $hash->{helper}{socketConnection} = $connection;
        $hash->{helper}{socketClose} = sub {
            my ($code, $reason) = @_;
            $hash->{helper}{expectedClose} = 1;
            eval { $connection->close($code || 1000, $reason || "Closing") };
            delete $hash->{helper}{socketConnection};
        };
        $connection->on(each_message => sub {
            my (undef, $message) = @_;
            my $action = TibberLive_HandleMessage($hash, $message->body, time());
            $connection->send(encode_json($action->{send})) if ref($action->{send}) eq "HASH";
            TibberLive_SetState($hash, "receiving")
              if ($action->{state} || "") eq "receiving";
        });
        $connection->on(finish => sub {
            my (undef, $code, $reason) = @_;
            delete $hash->{helper}{socketConnection};
            delete $hash->{helper}{socketClose};
            if (delete $hash->{helper}{expectedClose}) {
                $hash->{helper}{socketActive} = 0;
                return;
            }
            $code = 1006 if !defined $code || $code !~ /^\d+$/;
            $reason = "WebSocket connection closed"
              if !defined $reason || $reason eq "";
            TibberLive_OnClose($hash, $code, $reason, undef);
        });
        $hash->{helper}{retryAttempt} = 0;
        readingsSingleUpdate($hash, "connection", "connected", 1);
        TibberLive_SetState($hash, "starting");
        $connection->send(TibberLive_ConnectionInit($hash));
    });
}

sub TibberLive_Start {
    my ($hash) = @_;
    return if AttrVal($hash->{NAME}, "disable", 0);
    TibberLive_ScheduleWatchdog($hash, time() + 60);
    my $connect = TibberLive_ConnectHash($hash);
    if (!$connect || !defined TibberConnect_ReadSecret($connect)) {
        readingsSingleUpdate($hash, "connection", "missingToken", 1);
        readingsSingleUpdate($hash, "liveStatus", "disabled", 1);
        return;
    }
    TibberLive_InitializeBattery($hash)
      if !defined $hash->{helper}{batteryInstalledEpoch}
      && AttrVal($hash->{NAME}, "batteryInstalledEpoch", "") =~ /^\d+$/;
    if (!$hash->{HOME_ID}) {
        my $requested_home = AttrVal($hash->{NAME}, "homeId", "");
        my $home_id = TibberConnect_ResolveHome(
            $connect, $requested_home ne "" ? $requested_home : undef);
        if (!$home_id) {
            readingsSingleUpdate($hash, "connection", "waitingForHome", 1);
            readingsSingleUpdate($hash, "liveStatus", "starting", 1);
            TibberLive_SetState($hash, "waitingForHome");
            TibberLive_ScheduleReconnect($hash, 5);
            return;
        }
        $hash->{HOME_ID} = $home_id;
        readingsSingleUpdate($hash, "homeId", $home_id, 1);
        TibberLive_SetState($hash, "starting");
    }
    my $capability = TibberLive_SocketCapability($hash);
    if ($capability ne "available") {
        readingsSingleUpdate($hash, "connection", $capability, 1);
        readingsSingleUpdate($hash, "liveStatus", "disabled", 1);
        TibberLive_SetState($hash, "dependencyMissing");
        return;
    }
    if (!TibberLive_HomeLiveEnabled($hash)) {
        readingsSingleUpdate($hash, "connection", "liveNotEnabled", 1);
        readingsSingleUpdate($hash, "liveStatus", "disabled", 1);
        return;
    }
    if (!TibberLive_ConnectionSlotAvailable($hash)) {
        readingsSingleUpdate($hash, "connection", "connectionLimit", 1);
        readingsSingleUpdate($hash, "liveStatus", "disabled", 1);
        return;
    }
    my $url = ReadingsVal($connect->{NAME}, "websocketSubscriptionUrl", "");
    if ($url !~ m{^wss://}i) {
        readingsSingleUpdate($hash, "connection", "missingWebSocketUrl", 1);
        return;
    }
    $hash->{helper}{socketUrl} = $url;
    $hash->{helper}{socketActive} = 1;
    readingsSingleUpdate($hash, "connection", "connecting", 1);
    $hash->{helper}{socketFactory}->({
        url => $url,
        protocol => "graphql-transport-ws",
        headers => {"User-Agent" => "TibberLive-FHEM/$TibberLive_VERSION"},
        hash => $hash,
    });
}

sub TibberLive_ConnectionInit {
    my ($hash) = @_;
    my $connect = TibberLive_ConnectHash($hash);
    my $token = $connect ? TibberConnect_ReadSecret($connect) : undef;
    return encode_json({type => "connection_init", payload => {token => $token}});
}

sub TibberLive_SubscribeMessage {
    my ($hash) = @_;
    my $query = q|subscription LiveMeasurement($homeId: ID!) {
      liveMeasurement(homeId: $homeId) {
        timestamp power lastMeterConsumption
        accumulatedConsumption accumulatedProduction
        accumulatedConsumptionLastHour accumulatedProductionLastHour
        accumulatedCost accumulatedReward currency
        minPower averagePower maxPower
        powerProduction powerReactive powerProductionReactive
        minPowerProduction maxPowerProduction lastMeterProduction powerFactor
        voltagePhase1 voltagePhase2 voltagePhase3
        currentL1 currentL2 currentL3 signalStrength
      }
    }|;
    return {
        id => "live-1", type => "subscribe",
        payload => {query => $query, variables => {homeId => $hash->{HOME_ID}}},
    };
}

sub TibberLive_SanitizeError {
    my ($hash, $message) = @_;
    $message = "WebSocket error" if !defined $message || $message eq "";
    my $connect = TibberLive_ConnectHash($hash);
    my $token = $connect ? TibberConnect_ReadSecret($connect) : undef;
    $message =~ s/\Q$token\E/[redacted]/g if defined $token && $token ne "";
    $message =~ s/[\r\n]+/ /g;
    return substr($message, 0, 200);
}

sub TibberLive_HandleMessage {
    my ($hash, $text, $now) = @_;
    $now = time() if !defined $now;
    my $message = eval { decode_json($text) };
    if ($@ || ref($message) ne "HASH" || !defined $message->{type}) {
        readingsSingleUpdate($hash, "lastError", "Invalid WebSocket message", 1);
        return {state => "protocolError"};
    }
    $hash->{helper}{lastProtocolFrame} = $now;
    my $type = $message->{type};
    if ($type eq "connection_ack") {
        readingsSingleUpdate($hash, "connection", "subscribed", 1);
        return {state => "subscribed", send => TibberLive_SubscribeMessage($hash)};
    }
    if ($type eq "ping") {
        return {send => {type => "pong", (exists $message->{payload} ? (payload => $message->{payload}) : ())}};
    }
    if ($type eq "next") {
        my $frame = $message->{payload}{data}{liveMeasurement};
        if (ref($frame) eq "HASH") {
            TibberLive_RecordFrame($hash, $frame, $now);
            return {state => "receiving", frame => $frame};
        }
        return {state => "protocolError"};
    }
    if ($type eq "complete") {
        readingsSingleUpdate($hash, "connection", "complete", 1);
        return {state => "complete"};
    }
    if ($type eq "error") {
        my $error = ref($message->{payload}) eq "ARRAY"
          ? $message->{payload}[0]{message} : "Subscription error";
        readingsSingleUpdate($hash, "lastError", TibberLive_SanitizeError($hash, $error), 1);
        return {state => "error"};
    }
    return {state => "ignored"};
}

sub TibberLive_RecordFrame {
    my ($hash, $frame, $now) = @_;
    $now = time() if !defined $now;
    return 0 if ref($frame) ne "HASH"
      || !defined $frame->{timestamp} || !defined $frame->{power};

    my @fields = qw(
      timestamp power lastMeterConsumption accumulatedConsumption accumulatedProduction
      accumulatedConsumptionLastHour accumulatedProductionLastHour accumulatedCost
      accumulatedReward currency minPower averagePower maxPower powerProduction
      powerReactive powerProductionReactive minPowerProduction maxPowerProduction
      lastMeterProduction powerFactor voltagePhase1 voltagePhase2 voltagePhase3
      currentL1 currentL2 currentL3 signalStrength
    );
    my @missing;
    readingsBeginUpdate($hash);
    for my $field (@fields) {
        if (defined $frame->{$field}) {
            if (AttrVal($hash->{NAME}, "liveEventMode", "essential") eq "essential"
                && $field ne "power" && $field ne "timestamp") {
                readingsBulkUpdateIfChanged($hash, $field, $frame->{$field});
            }
            else {
                readingsBulkUpdate($hash, $field, $frame->{$field});
            }
        }
        else {
            push @missing, $field;
        }
    }
    readingsBulkUpdate($hash, "powerUnit", "W");
    readingsBulkUpdate($hash, "energyUnit", "kWh");
    readingsBulkUpdate($hash, "reactivePowerUnit", "kVAr");
    readingsBulkUpdate($hash, "liveMissingFields", join(",", @missing));
    readingsBulkUpdate($hash, "lastLiveUpdate", FmtDateTime($now));
    readingsBulkUpdate($hash, "liveFrameAge", 0);
    readingsBulkUpdate($hash, "liveStatus", "receiving");
    readingsBulkUpdate($hash, "state", "receiving");
    readingsBulkUpdate($hash, "liveWarning", "");

    if (defined $hash->{helper}{lastLiveEpoch} && $now > $hash->{helper}{lastLiveEpoch}) {
        my $difference = $now - $hash->{helper}{lastLiveEpoch};
        push @{$hash->{helper}{cadenceSamples}}, $difference;
        shift @{$hash->{helper}{cadenceSamples}} while @{$hash->{helper}{cadenceSamples}} > 8;
        my @sorted = sort {$a <=> $b} @{$hash->{helper}{cadenceSamples}};
        my $cadence = $sorted[int($#sorted / 2)];
        $hash->{helper}{expectedFrameCadence} = $cadence;
        readingsBulkUpdate($hash, "expectedFrameCadence", $cadence);
    }
    $hash->{helper}{lastLiveEpoch} = $now;
    readingsEndUpdate($hash, 1);
    return 1;
}

sub TibberLive_EvaluateHealth {
    my ($hash, $now) = @_;
    $now = time() if !defined $now;
    return if defined $hash->{helper}{lastHealthCheck}
      && $now - $hash->{helper}{lastHealthCheck} < 60;
    $hash->{helper}{lastHealthCheck} = $now;
    my $last = $hash->{helper}{lastLiveEpoch};
    if (!defined $last) {
        readingsSingleUpdate($hash, "liveStatus", "starting", 1);
        readingsSingleUpdate($hash, "liveWarning", "noData", 1);
        TibberLive_EvaluateBattery($hash, $now);
        return;
    }
    my $age = $now - $last;
    my $cadence = $hash->{helper}{expectedFrameCadence} || 15;
    my $stale_after = 4 * $cadence;
    $stale_after = 60 if $stale_after < 60;
    my ($status, $warning) = ("receiving", "");
    ($status, $warning) = ("stale", "noData") if $age >= $stale_after;
    ($status, $warning) = ("offline", "noData") if $age >= 3600;
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "liveFrameAge", $age);
    readingsBulkUpdate($hash, "liveStatus", $status);
    readingsBulkUpdate($hash, "liveWarning", $warning);
    readingsEndUpdate($hash, 1);
    TibberLive_EvaluateBattery($hash, $now);
}

sub TibberLive_Watchdog {
    my ($hash, $now) = @_;
    return if AttrVal($hash->{NAME}, "disable", 0);
    $now = time() if !defined $now;
    if (!$hash->{helper}{socketActive}) {
        TibberLive_EvaluateBattery($hash, $now);
        TibberLive_ScheduleWatchdog($hash, $now + 60);
        return;
    }
    TibberLive_EvaluateHealth($hash, $now);
    my $silence = TibberLive_CheckProtocolSilence($hash, $now, 300);
    my $url_change = $silence->{action} eq "reconnect"
      ? {action => "none"} : TibberLive_CheckUrlChange($hash);
    if ($silence->{action} eq "reconnect") {
        TibberLive_OnClose($hash, 1006, "Protocol silence", undef);
    }
    elsif ($url_change->{action} eq "reconnect") {
        TibberLive_OnClose($hash, 1000, "WebSocket URL changed", undef);
    }
    TibberLive_ScheduleWatchdog($hash, $now + 60);
}

sub TibberLive_DaysInMonth {
    my ($year, $month) = @_;
    my $next_year = $month == 11 ? $year + 1 : $year;
    my $next_month = ($month + 1) % 12;
    return (timegm(0, 0, 0, 1, $next_month, $next_year)
      - timegm(0, 0, 0, 1, $month, $year)) / 86400;
}

sub TibberLive_ShiftCalendarMonths {
    my ($epoch, $months) = @_;
    my @parts = gmtime($epoch);
    my $absolute_month = ($parts[5] + 1900) * 12 + $parts[4] + $months;
    my $year = int($absolute_month / 12);
    my $month = $absolute_month % 12;
    my $day = $parts[3];
    my $last_day = TibberLive_DaysInMonth($year, $month);
    $day = $last_day if $day > $last_day;
    return timegm($parts[0], $parts[1], $parts[2], $day, $month, $year);
}

sub TibberLive_InitializeBattery {
    my ($hash) = @_;
    my $installed = AttrVal($hash->{NAME}, "batteryInstalledEpoch", "");
    if ($installed =~ /^\d+$/) {
        $hash->{helper}{batteryInstalledEpoch} = $installed;
        TibberLive_UpdateBatteryDue($hash);
        readingsSingleUpdate($hash, "batterySetup", "complete", 1);
        TibberLive_EvaluateBattery($hash, time());
        return;
    }
    readingsSingleUpdate($hash, "batterySetup", "required", 1);
    readingsSingleUpdate($hash, "batteryMaintenance", "unknown", 1);
    readingsSingleUpdate($hash, "batteryRecommendation", "setBatteryAge", 1);
}

sub TibberLive_UpdateBatteryDue {
    my ($hash) = @_;
    my $lifetime = AttrVal($hash->{NAME}, "batteryLifetimeDays", 365);
    $lifetime = 365 if $lifetime !~ /^\d+$/ || $lifetime < 1;
    $hash->{helper}{batteryDueEpoch} =
      $hash->{helper}{batteryInstalledEpoch} + ($lifetime * 86400);
    readingsSingleUpdate($hash, "batteryInstalledAt",
        FmtDateTime($hash->{helper}{batteryInstalledEpoch}), 1);
    readingsSingleUpdate($hash, "batteryReplacementDue",
        FmtDateTime($hash->{helper}{batteryDueEpoch}), 1);
}

sub TibberLive_SetBatteryAgeMonths {
    my ($hash, $months, $now) = @_;
    return "Battery age must be an integer from 0..12"
      if !defined $months || $months !~ /^\d+$/ || $months > 12;
    $now = time() if !defined $now;
    my $installed = TibberLive_ShiftCalendarMonths($now, -$months);
    $hash->{helper}{batteryInstalledEpoch} = $installed;
    readingsSingleUpdate($hash, "batteryAgeMonths", $months, 1);
    readingsSingleUpdate($hash, "batterySetup", "complete", 1);
    CommandAttr(undef, "$hash->{NAME} batteryInstalledEpoch $installed");
    TibberLive_UpdateBatteryDue($hash);
    TibberLive_EvaluateBattery($hash, $now);
    if ($months == 12) {
        readingsSingleUpdate($hash, "batteryMaintenance", "due", 1);
        readingsSingleUpdate($hash, "batteryRecommendation", "replaceAfterSetupTests", 1);
    }
    return undef;
}

sub TibberLive_EvaluateBattery {
    my ($hash, $now) = @_;
    return if !defined $hash->{helper}{batteryDueEpoch};
    $now = time() if !defined $now;
    my $remaining = $hash->{helper}{batteryDueEpoch} - $now;
    my ($state, $recommendation) = ("ok", "none");
    ($state, $recommendation) = ("dueSoon", "planReplacement")
      if $remaining <= 30 * 86400;
    ($state, $recommendation) = ("due", "replaceBattery") if $remaining == 0;
    ($state, $recommendation) = ("overdue", "replaceBattery") if $remaining < 0;
    readingsSingleUpdate($hash, "batteryMaintenance", $state, 1);
    readingsSingleUpdate($hash, "batteryRecommendation", $recommendation, 1);
}

sub TibberLive_RecordBatteryReplacement {
    my ($hash, $now) = @_;
    $now = time() if !defined $now;
    $hash->{helper}{batteryInstalledEpoch} = $now;
    readingsSingleUpdate($hash, "batteryAgeMonths", 0, 1);
    readingsSingleUpdate($hash, "batterySetup", "complete", 1);
    CommandAttr(undef, "$hash->{NAME} batteryInstalledEpoch $now");
    TibberLive_UpdateBatteryDue($hash);
    TibberLive_EvaluateBattery($hash, $now);
    return undef;
}

sub TibberLive_OnClose {
    my ($hash, $code, $reason, $random_fraction) = @_;
    $code = 1006 if !defined $code || $code !~ /^\d+$/;
    $reason = "WebSocket connection closed" if !defined $reason || $reason eq "";
    TibberLive_InvalidatePendingConnect($hash);
    $hash->{helper}{socketActive} = 0;
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "lastDisconnectAt", FmtDateTime(time()));
    readingsBulkUpdate($hash, "lastDisconnectReason",
        TibberLive_SanitizeError($hash, $reason));
    readingsEndUpdate($hash, 1);
    if ($code == 4401 || $code == 4403) {
        readingsSingleUpdate($hash, "connection", "authenticationError", 1);
        TibberLive_SetState($hash, "authenticationError");
        return {retry => 0};
    }
    $random_fraction = rand() if !defined $random_fraction;
    $random_fraction = 0 if $random_fraction < 0;
    $random_fraction = 1 if $random_fraction > 1;
    my $delay = $code == 1001
      ? 1 + int(59 * $random_fraction)
      : TibberConnect_NextRetryDelay($hash->{helper}{retryAttempt} || 0, $random_fraction);
    $hash->{helper}{retryAttempt} = ($hash->{helper}{retryAttempt} || 0) + 1;
    TibberLive_ScheduleReconnect($hash, $delay);
    readingsSingleUpdate($hash, "connection", "reconnecting", 1);
    TibberLive_SetState($hash, "reconnecting");
    return {retry => 1, retryDelay => $delay};
}

sub TibberLive_CheckProtocolSilence {
    my ($hash, $now, $timeout) = @_;
    return {action => "none"}
      if !$hash->{helper}{lastProtocolFrame}
      || $now - $hash->{helper}{lastProtocolFrame} <= $timeout;
    TibberLive_Close($hash, 1000, "Protocol silence");
    return {action => "reconnect"};
}

sub TibberLive_CheckUrlChange {
    my ($hash) = @_;
    my $connect = TibberLive_ConnectHash($hash);
    my $current = $connect
      ? ReadingsVal($connect->{NAME}, "websocketSubscriptionUrl", "") : "";
    return {action => "none"} if !$current || $current eq ($hash->{helper}{socketUrl} || "");
    TibberLive_Close($hash, 1000, "WebSocket URL changed");
    return {action => "reconnect", url => $current};
}

sub TibberLive_Close {
    my ($hash, $code, $reason) = @_;
    TibberLive_InvalidatePendingConnect($hash);
    $hash->{helper}{socketClose}->($code || 1000, $reason || "Closing")
      if ref($hash->{helper}{socketClose}) eq "CODE";
    $hash->{helper}{socketActive} = 0;
}

sub TibberLive_Attr {
    my ($command, $name, $attribute, $value) = @_;
    my $hash = $defs{$name};
    return undef if !$hash;
    if ($attribute eq "batteryLifetimeDays") {
        return "batteryLifetimeDays must be a positive integer"
          if $command eq "set" && (!defined $value || $value !~ /^\d+$/ || $value < 1);
        return undef;
    }
    return undef if $attribute ne "disable";
    if ($command eq "set" && $value) {
        TibberLive_CancelTimers($hash);
        TibberLive_Close($hash, 1000, "Disabled");
        readingsSingleUpdate($hash, "liveStatus", "disabled", 1);
    }
    elsif ($command eq "del" || !$value) {
        TibberLive_ScheduleReconnect($hash, 1);
    }
    return undef;
}

sub TibberLive_Undef {
    my ($hash, $argument) = @_;
    TibberLive_CancelTimers($hash);
    TibberLive_Close($hash, 1000, "Undefined");
    return undef;
}

1;

=pod

=begin html

<a id="TibberLive"></a><h3>TibberLive</h3>
<h4>Overview</h4>
<p>TibberLive is the optional Pulse/Watty live module. It uses the token, home
information and dynamic WebSocket URL supplied by one existing TibberConnect
device. One TibberLive instance belongs to one verified home. Tibber allows at
most two simultaneous live sockets. The module publishes measurements and
health information but never sends notifications or switches actuators.</p>

<h4>Definition</h4>
<p><code>define &lt;name&gt; TibberLive &lt;TibberConnect-device&gt;</code><br>
The referenced TibberConnect device must already exist. If only one verified
home is available it is selected automatically; otherwise use
<code>selectHome</code>. TibberLive does not store a separate access token.</p>

<h4>Set commands</h4>
<ul>
<li><code>selectHome &lt;homeId&gt;</code> &ndash; selects a home known and verified by TibberConnect and reconnects.</li>
<li><code>batteryAgeMonths 0..12</code> &ndash; records the current Pulse battery age as the initial maintenance baseline.</li>
<li><code>batteryReplaced</code> &ndash; records a battery replacement at the current time.</li>
</ul>

<h4>Attributes</h4>
<ul>
<li><code>disable 0|1</code> &ndash; closes or enables the live connection.</li>
<li><code>homeId</code> &ndash; selected home; normally maintained by <code>selectHome</code>.</li>
<li><code>batteryLifetimeDays</code> &ndash; expected battery life used for the maintenance due date.</li>
<li><code>batteryInstalledEpoch</code> &ndash; stored installation time of the battery.</li>
<li><code>liveEventMode essential|all</code> &ndash; <code>essential</code> emits regular events for power/timestamp and only changed events for other live fields; <code>all</code> emits every received value.</li>
</ul>

<h4>Important readings</h4>
<ul>
<li><code>state</code>, <code>connection</code>, <code>liveStatus</code>, <code>liveWarning</code> &ndash; connection and health state.</li>
<li><code>power</code>, <code>powerProduction</code>, <code>minPower</code>, <code>averagePower</code>, <code>maxPower</code> &ndash; live power values.</li>
<li><code>accumulatedConsumption</code>, <code>accumulatedProduction</code>, <code>lastMeterConsumption</code>, <code>lastMeterProduction</code> &ndash; live energy/meter values when supplied by Tibber.</li>
<li><code>voltagePhase1..3</code>, <code>currentL1..3</code>, <code>powerFactor</code>, <code>signalStrength</code> &ndash; electrical and radio values when available.</li>
<li><code>lastLiveUpdate</code>, <code>liveFrameAge</code>, <code>expectedFrameCadence</code>, <code>liveMissingFields</code> &ndash; data freshness and completeness.</li>
<li><code>lastDisconnectAt</code>, <code>lastDisconnectReason</code>, <code>lastError</code> &ndash; reconnect diagnostics without exposing the token.</li>
<li><code>batterySetup</code>, <code>batteryAgeMonths</code>, <code>batteryInstalledAt</code>, <code>batteryReplacementDue</code>, <code>batteryMaintenance</code>, <code>batteryRecommendation</code> &ndash; battery maintenance.</li>
</ul>

<h4>Dependencies and reconnect behaviour</h4>
<p><code>AnyEvent::WebSocket::Client</code> and a usable <code>EV</code> module
are required. They are detected but never installed automatically. If missing,
only TibberLive remains disabled; <code>dependencyStatus</code>,
<code>dependencyRecommendation</code> and <code>dependencyInstallCommand</code>
explain the condition. On Debian/Raspberry Pi OS an administrator may use
<code>sudo apt install libanyevent-websocket-client-perl</code> after verifying
package availability. Each WebSocket handshake is limited to 45 seconds. A
stalled attempt is detached and retried with controlled backoff. Protocol
silence and a changed Tibber WebSocket URL also trigger a controlled reconnect;
authentication errors are not retried indefinitely with the same token.</p>

<h4>Notes</h4>
<p>Live fields depend on the meter, Pulse/Watty hardware and Tibber service.
Missing optional fields are listed in <code>liveMissingFields</code>. Battery
maintenance is advisory only.</p>
<p>Community project information:
<a href="https://153er-netz.de/seiten/entwicklung/fhem.html">153er-netz.de / Development</a></p>

=end html

=begin html_DE

<a id="TibberLive-DE"></a><h3>TibberLive</h3>
<h4>&Uuml;bersicht</h4>
<p>TibberLive ist das optionale Pulse-/Watty-Livemodul. Es verwendet Token,
Home-Informationen und dynamische WebSocket-Adresse eines vorhandenen
TibberConnect-Ger&auml;ts. Eine TibberLive-Instanz geh&ouml;rt zu genau einem
gepr&uuml;ften Home. Tibber erlaubt h&ouml;chstens zwei gleichzeitige Live-Sockets.
Das Modul ver&ouml;ffentlicht Mess- und Zustandswerte, versendet aber keine
Nachrichten und schaltet keinen Aktor.</p>

<h4>Definition</h4>
<p><code>define &lt;Name&gt; TibberLive &lt;TibberConnect-Geraet&gt;</code><br>
Das referenzierte TibberConnect-Ger&auml;t muss bereits vorhanden sein. Bei nur
einem gepr&uuml;ften Home erfolgt die Auswahl automatisch, andernfalls mit
<code>selectHome</code>. TibberLive speichert keinen eigenen Zugriffstoken.</p>

<h4>Set-Befehle</h4>
<ul>
<li><code>selectHome &lt;homeId&gt;</code> &ndash; w&auml;hlt ein TibberConnect bekanntes und gepr&uuml;ftes Home und verbindet neu.</li>
<li><code>batteryAgeMonths 0..12</code> &ndash; erfasst das aktuelle Alter der Pulse-Batterie als Ausgangspunkt der Wartung.</li>
<li><code>batteryReplaced</code> &ndash; protokolliert einen Batteriewechsel zum aktuellen Zeitpunkt.</li>
</ul>

<h4>Attribute</h4>
<ul>
<li><code>disable 0|1</code> &ndash; schlie&szlig;t oder aktiviert die Live-Verbindung.</li>
<li><code>homeId</code> &ndash; ausgew&auml;hltes Home; normalerweise durch <code>selectHome</code> gepflegt.</li>
<li><code>batteryLifetimeDays</code> &ndash; erwartete Batterielebensdauer f&uuml;r den Wartungstermin.</li>
<li><code>batteryInstalledEpoch</code> &ndash; gespeicherter Einbauzeitpunkt der Batterie.</li>
<li><code>liveEventMode essential|all</code> &ndash; <code>essential</code> erzeugt regelm&auml;&szlig;ige Events f&uuml;r Leistung/Zeitstempel und f&uuml;r andere Livefelder nur bei &Auml;nderung; <code>all</code> erzeugt jedes empfangene Event.</li>
</ul>

<h4>Wichtige Readings</h4>
<ul>
<li><code>state</code>, <code>connection</code>, <code>liveStatus</code>, <code>liveWarning</code> &ndash; Verbindung und Gesundheitszustand.</li>
<li><code>power</code>, <code>powerProduction</code>, <code>minPower</code>, <code>averagePower</code>, <code>maxPower</code> &ndash; Live-Leistungswerte.</li>
<li><code>accumulatedConsumption</code>, <code>accumulatedProduction</code>, <code>lastMeterConsumption</code>, <code>lastMeterProduction</code> &ndash; Live-Energie-/Z&auml;hlerwerte, soweit Tibber sie liefert.</li>
<li><code>voltagePhase1..3</code>, <code>currentL1..3</code>, <code>powerFactor</code>, <code>signalStrength</code> &ndash; elektrische und Funkwerte, soweit vorhanden.</li>
<li><code>lastLiveUpdate</code>, <code>liveFrameAge</code>, <code>expectedFrameCadence</code>, <code>liveMissingFields</code> &ndash; Aktualit&auml;t und Vollst&auml;ndigkeit.</li>
<li><code>lastDisconnectAt</code>, <code>lastDisconnectReason</code>, <code>lastError</code> &ndash; Wiederverbindungsdiagnose ohne Preisgabe des Tokens.</li>
<li><code>batterySetup</code>, <code>batteryAgeMonths</code>, <code>batteryInstalledAt</code>, <code>batteryReplacementDue</code>, <code>batteryMaintenance</code>, <code>batteryRecommendation</code> &ndash; Batteriepflege.</li>
</ul>

<h4>Abh&auml;ngigkeiten und Wiederverbindung</h4>
<p><code>AnyEvent::WebSocket::Client</code> und ein nutzbares <code>EV</code>-Modul
sind erforderlich. Sie werden erkannt, aber niemals automatisch installiert.
Fehlen sie, bleibt nur TibberLive deaktiviert; die Readings
<code>dependencyStatus</code>, <code>dependencyRecommendation</code> und
<code>dependencyInstallCommand</code> erkl&auml;ren den Zustand. Unter
Debian/Raspberry Pi OS kann ein Administrator nach Pr&uuml;fung der
Paketverf&uuml;gbarkeit
<code>sudo apt install libanyevent-websocket-client-perl</code> verwenden. Jeder
WebSocket-Handshake ist auf 45 Sekunden begrenzt. Ein h&auml;ngender Versuch wird
sauber gel&ouml;st und mit kontrollierter Wartezeit wiederholt. Auch Protokollstille
oder eine ge&auml;nderte Tibber-WebSocket-Adresse l&ouml;sen eine kontrollierte
Wiederverbindung aus; Authentifizierungsfehler werden mit demselben Token nicht
endlos wiederholt.</p>

<h4>Hinweise</h4>
<p>Die vorhandenen Livefelder h&auml;ngen von Z&auml;hler, Pulse-/Watty-Hardware und
Tibber-Dienst ab. Fehlende optionale Felder stehen in
<code>liveMissingFields</code>. Die Batteriepflege ist ausschlie&szlig;lich
beratend.</p>
<p>Community-Projektinformationen:
<a href="https://153er-netz.de/seiten/entwicklung/fhem.html">153er-netz.de / Entwicklung</a></p>

=end html_DE

=cut

# Replace only the TibberOverview subroutine in an existing 99_myUtils.pm.
# This helper reads local FHEM readings only and performs no switching.
package main;

use strict;
use warnings;

# Required when this example is copied as FHEM/99_myUtils.pm.
sub
myUtils_Initialize($$)
{
  my ($hash) = @_;
}

sub TibberOverview {
  my $r = sub { ReadingsVal($_[0], $_[1], (defined $_[2] ? $_[2] : q{})) };
  my $h = sub {
    my $v = defined $_[0] ? $_[0] : q{};
    $v =~ s/&(?!(?:amp|lt|gt|uuml|auml|ouml|szlig);)/&amp;/g;
    $v =~ s/</&lt;/g; $v =~ s/>/&gt;/g;
    return $v;
  };
  my $s = sub {
    my $v = defined $_[0] ? $_[0] : q{};
    return q{} if $v eq q{};
    return $1 if $v =~ /T(\d\d:\d\d)/;
    return $1 if $v =~ /\b(\d\d:\d\d)/;
    return $v;
  };
  my $p    = $r->('TibberConnect','current_price');
  my $pl   = $r->('TibberConnect','priceLevel');
  my $w    = $r->('TibberLive','power');
  my $from = $s->($r->('TibberConnect','nextCheapestWindowStart'));
  my $until= $s->($r->('TibberConnect','nextCheapestWindowEnd'));
  my $fi   = $r->('TibberConnect','priceForecastIntervals','0');
  my $ci   = $r->('TibberConnect','priceCacheIntervals','0');
  my $tr   = $r->('TibberConnect','priceTrendDirection','unavailable');
  my $to   = $r->('TibberConnect','tomorrowPriceState');
  my $li   = $r->('TibberLive','liveStatus');

  my ($pc,$pt) = ('#facc15','Preisniveau normal');
  if ($p =~ /^-?\d+(?:\.\d+)?$/) {
    if    ($p <= 0)                   { ($pc,$pt) = ('#22c55e','Kostenloser oder negativer Strompreis') }
    elsif ($pl =~ /VERY_CHEAP|CHEAP/) { ($pc,$pt) = ('#22c55e','G&uuml;nstige Preisphase') }
    elsif ($pl =~ /VERY_EXPENSIVE/)   { ($pc,$pt) = ('#ff5a5f','Sehr hohe Preisphase') }
    elsif ($pl =~ /EXPENSIVE/)        { ($pc,$pt) = ('#ff5a5f','Hochpreisphase') }
  }
  my ($tc,$tt) = ('#facc15','Tendenz nicht verf&uuml;gbar');
  if    ($tr eq 'falling') { ($tc,$tt) = ('#22c55e','&darr; Preis f&auml;llt') }
  elsif ($tr eq 'steady')  { ($tc,$tt) = ('#facc15','&rarr; Preis bleibt etwa gleich') }
  elsif ($tr eq 'rising')  { ($tc,$tt) = ('#ff5a5f','&uarr; Preis steigt') }
  my ($lc,$lt) = ($li eq 'receiving' ? ('#22c55e','Verbunden') : ('#ff5a5f','Nicht verbunden: '.$li));
  my $tom = ($to eq 'ready'   ? 'bereit'
           : $to eq 'pending' ? 'noch nicht verf&uuml;gbar'
           : $to eq 'unknown' ? 'unbekannt'
           : $to eq 'unavailable' ? 'nicht verf&uuml;gbar'
           : $to);
  my $px  = ($p =~ /^-?\d+(?:\.\d+)?$/) ? sprintf('%.3f EUR/kWh',$p) : $p;
  my $wx  = ($w =~ /^-?\d+(?:\.\d+)?$/) ? sprintf('%.0f W',$w) : $w;
  my $vc  = '#cfe8ff';

  return '<table style="border-collapse:collapse;min-width:720px;color:#f4f4f4;font-size:18px;line-height:1.35;font-weight:600">'
    .'<tr><th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">Aktueller Preis</th>'
    .'<td style="padding:8px;color:'.$pc.'"><b>'.$h->($px).'</b><br><span style="font-size:0.9em;font-weight:700">Preisampel: '.$pt.'</span></td>'
    .'<th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">Aktuelle Leistung</th>'
    .'<td style="padding:8px;color:'.$vc.'"><b>'.$h->($wx).'</b></td></tr>'
    .'<tr><th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">G&uuml;nstigstes Zeitfenster</th>'
    .'<td style="padding:8px;color:'.$vc.'" colspan="3"><b>'.$h->($from).' bis '.$h->($until).'</b></td></tr>'
    .'<tr><th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">Preisvorschau</th>'
    .'<td style="padding:8px;color:'.$vc.'"><b>'.$h->($fi).' von '.$h->($ci).' Viertelstunden</b></td>'
    .'<th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">Preistendenz</th>'
    .'<td style="padding:8px;color:'.$tc.'"><b>'.$tt.'</b></td></tr>'
    .'<tr><th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">Preise morgen</th>'
    .'<td style="padding:8px;color:'.$vc.'"><b>'.$h->($tom).'</b></td>'
    .'<th style="text-align:left;padding:8px;color:#f0f0f0;font-weight:700">Tibber Pulse IR</th>'
    .'<td style="padding:8px;color:'.$lc.'"><b>'.$h->($lt).'</b></td></tr>'
    .'</table>';
}

1;

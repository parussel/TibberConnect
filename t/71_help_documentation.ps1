$ErrorActionPreference = 'Stop'

function Need([string]$Path, [string]$Pattern, [string]$Message) {
    $text = Get-Content -Raw -LiteralPath $Path
    if ($text -notmatch $Pattern) { throw $Message }
}

foreach ($file in 'FHEM/70_TibberConnect.pm','FHEM/70_TibberLive.pm') {
    Need $file '(?s)<h4>Overview</h4>.*<h4>Definition</h4>.*<h4>Set commands</h4>.*<h4>Attributes</h4>.*<h4>Important readings</h4>' "$file lacks structured English help"
    Need $file '(?s)<h4>&Uuml;bersicht</h4>.*<h4>Definition</h4>.*<h4>Set-Befehle</h4>.*<h4>Attribute</h4>.*<h4>Wichtige Readings</h4>' "$file lacks structured German help"
}

Need 'FHEM/70_TibberConnect.pm' '(?s)forecast snapshot.*actual price.*same plot' 'English comparison-plot explanation is missing'
Need 'FHEM/70_TibberConnect.pm' '(?s)Prognose-Snapshot.*tats&auml;chlichen Preis.*demselben Plot' 'German comparison-plot explanation is missing'
Need 'README.md' '(?s)Prognose und tatsächlicher Preis.*parallel.*Plot-Datei' 'README parallel-plot notice is missing'

$controls = Get-Content -LiteralPath 'controls_TibberConnect.txt'
foreach ($file in 'FHEM/70_TibberConnect.pm','FHEM/70_TibberLive.pm') {
    $size = (Get-Item -LiteralPath $file).Length
    $escaped = [regex]::Escape($file)
    if (-not ($controls -match "^UPD 2026-11-22_00:00:00 $size $escaped$")) {
        throw "controls_TibberConnect.txt does not match $file ($size bytes)"
    }
}

'HELP_DOCUMENTATION_OK'

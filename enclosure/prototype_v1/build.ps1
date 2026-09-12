param([string]$OpenSCAD = 'C:\Program Files (x86)\OpenSCAD\openscad.com')
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'mini_tv.scad'
$parts = [ordered]@{ housing='housing'; back_cover='back'; knobs='knobs'; antennas='antennas'; fit_coupon='fit_coupon' }
foreach ($name in $parts.Keys) {
    $destination = Join-Path $PSScriptRoot ($name + '.stl')
    $define = 'part="' + $parts[$name] + '"'
    & $OpenSCAD -o $destination -D $define $source
    if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $destination)) {
        throw "Export failed: $name"
    }
}

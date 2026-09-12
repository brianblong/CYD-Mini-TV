param(
    [string]$OpenSCAD = 'C:\Program Files (x86)\OpenSCAD\openscad.com',
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$parts = [ordered]@{ test_nut='test'; nuts_m3_set_of_8='eight' }
foreach ($name in $parts.Keys) {
    $define = 'part="' + $parts[$name] + '"'
    & $OpenSCAD -o (Join-Path $PSScriptRoot ($name+'.stl')) -D $define (Join-Path $PSScriptRoot 'printed_nuts.scad')
    if ($LASTEXITCODE -ne 0) { throw "Nut export failed: $name" }
}
& $Python (Join-Path $PSScriptRoot 'finish_stls.py') test_nut nuts_m3_set_of_8
if ($LASTEXITCODE -ne 0) { throw 'Nut mesh finishing failed' }
& $Python (Join-Path $PSScriptRoot 'verify_nuts.py')
if ($LASTEXITCODE -ne 0) { throw 'Nut verification failed' }

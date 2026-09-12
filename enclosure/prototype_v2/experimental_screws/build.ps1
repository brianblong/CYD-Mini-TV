param(
    [string]$OpenSCAD = 'C:\Program Files (x86)\OpenSCAD\openscad.com',
    [string]$Python = 'python'
)
$ErrorActionPreference='Stop'
$source=Join-Path $PSScriptRoot 'printed_screws.scad'
$parts=[ordered]@{ test_screw='test'; pcb_screws_m3x4='pcb'; back_screws_m3x10='back' }
foreach ($name in $parts.Keys) {
    $destination=Join-Path $PSScriptRoot ($name+'.stl')
    $define='part="'+$parts[$name]+'"'
    & $OpenSCAD -o $destination -D $define $source
    if ($LASTEXITCODE -ne 0) { throw "Export failed: $name" }
}
& $Python (Join-Path $PSScriptRoot 'finish_stls.py')
if ($LASTEXITCODE -ne 0) { throw 'Mesh finishing failed' }
& $Python (Join-Path $PSScriptRoot 'verify_screws.py')
if ($LASTEXITCODE -ne 0) { throw 'Screw verification failed' }

param(
    [string]$OpenSCAD='C:\Program Files (x86)\OpenSCAD\openscad.com',
    [string]$Python='python'
)
$ErrorActionPreference='Stop'
$parts=[ordered]@{test_screw='test';pcb_screws_m3x4='pcb';back_screws_m3x10='back'}
foreach($name in $parts.Keys) {
    $define='part="'+$parts[$name]+'"'
    & $OpenSCAD -o (Join-Path $PSScriptRoot ($name+'.stl')) -D $define (Join-Path $PSScriptRoot 'screws.scad')
    if($LASTEXITCODE -ne 0) { throw "Export failed: $name" }
}
& $Python (Join-Path $PSScriptRoot 'verify.py')
if($LASTEXITCODE -ne 0) { throw 'Screw finishing or verification failed' }

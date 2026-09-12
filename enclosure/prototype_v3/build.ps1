param(
    [string]$OpenSCAD = 'C:\Program Files (x86)\OpenSCAD\openscad.com',
    [string]$Python = 'python'
)
$ErrorActionPreference='Stop'
$parts=[ordered]@{housing='housing';fit_coupon='fit_coupon';test_spacers='spacers'}
foreach ($name in $parts.Keys) {
    $define='part="'+$parts[$name]+'"'
    & $OpenSCAD -o (Join-Path $PSScriptRoot ($name+'.stl')) -D $define (Join-Path $PSScriptRoot 'mini_tv.scad')
    if ($LASTEXITCODE -ne 0) { throw "Export failed: $name" }
}
# Reuse physically tested accessories and the enlarged 13.4 x 8.4 rear opening.
foreach ($name in @('back_cover','knobs','antennas')) {
    Copy-Item (Join-Path $PSScriptRoot ('../prototype_v2/'+$name+'.stl')) (Join-Path $PSScriptRoot ($name+'.stl'))
}
foreach ($script in @('finish_meshes.py','verify_meshes.py','verify_threads.py')) {
    & $Python (Join-Path $PSScriptRoot $script)
    if ($LASTEXITCODE -ne 0) { throw "Check failed: $script" }
}

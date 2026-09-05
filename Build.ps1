[CmdletBinding()]
param(
    [ValidateSet('Check', 'Debug', 'Release', 'AppBundle')]
    [string]$Target = 'Debug',
    [switch]$Demo
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location $PSScriptRoot
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter is not on PATH. Install Flutter 3.44.9 and reopen PowerShell.' }
function Invoke-Flutter {
    param([string[]]$Arguments)
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Flutter failed: $($Arguments -join ' ')" }
}
if ($Demo -and $Target -in @('Release', 'AppBundle')) { throw 'Release builds must not start in demo mode. Use the in-app demo button instead.' }
Invoke-Flutter @('--version')
Invoke-Flutter @('pub', 'get')
Invoke-Flutter @('analyze')
Invoke-Flutter @('test')
if ($Target -eq 'Check') { return }
if ($Target -in @('Release', 'AppBundle') -and -not (Test-Path 'android/key.properties')) { throw 'Create android/key.properties from the example and configure your private release key. No debug key will be used for release.' }
$arguments = if ($Target -eq 'AppBundle') { @('build', 'appbundle', '--release') } elseif ($Target -eq 'Release') { @('build', 'apk', '--release') } else { @('build', 'apk', '--debug') }
if ($Demo) { $arguments += '--dart-define=DEMO_MODE=true' }
Invoke-Flutter $arguments
Write-Host 'Build finished. Outputs are in build/app/outputs/.'

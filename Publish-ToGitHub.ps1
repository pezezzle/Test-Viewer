[CmdletBinding()]
param([string]$RepositoryName = 'Test-Viewer')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Set-Location $PSScriptRoot
if ($RepositoryName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]+$') { throw 'Invalid repository name.' }
foreach ($command in @('git', 'gh')) { if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Install $command and reopen PowerShell." } }
function Invoke-Git {
    param([string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments -join ' ')" }
}
& gh auth status --hostname github.com 2>$null
if ($LASTEXITCODE -ne 0) { & gh auth login --hostname github.com --git-protocol https --web; if ($LASTEXITCODE -ne 0) { throw 'GitHub login failed.' } }
$account = (& gh api user --jq .login).Trim()
if ($LASTEXITCODE -ne 0 -or $account -ne 'pezezzle') { throw "Expected GitHub account pezezzle, received $account. Switch accounts before publishing." }
$repository = "$account/$RepositoryName"
& gh repo view $repository --json name 1>$null 2>$null
if ($LASTEXITCODE -eq 0) { throw "Repository $repository already exists. Nothing was changed. Use another name or update the existing repository manually." }
$hadRepository = Test-Path '.git'
if (-not $hadRepository) { Invoke-Git @('init', '-b', 'main') }
# Stage only source roots. Ignored keys, databases and generated outputs stay private.
$allowed = @('.github', '.metadata', '.fvmrc', '.gitattributes', '.gitignore', '.vscode', 'analysis_options.yaml', 'android', 'assets', 'ios', 'lib', 'test', 'integration_test', 'tool', 'docs', 'example', 'pubspec.yaml', 'README.md', 'CHANGELOG.md', 'Build.ps1', 'Publish-ToGitHub.ps1', 'SECURITY.md')
if (Test-Path 'pubspec.lock') { $allowed += 'pubspec.lock' }
Invoke-Git (@('add', '--') + $allowed)
$tracked = @(& git ls-files)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the Git index.' }
$forbidden = @($tracked | Where-Object { $_ -match '(?i)(\.(p12|pfx|jks|keystore|pem|key|sqlite3?|db|apk|aab|ipa|zip|bundle|mobileprovision)$|(^|/)(key\.properties|\.env)(/|$)|(^|/)signing/|PRIVAT|password)' })
if ($forbidden.Count -gt 0) { throw "Refusing to publish sensitive files: $($forbidden -join ', ')" }
# Refuse pre-existing history; this prevents publishing an old secret that was later deleted.
& git rev-parse --verify HEAD 1>$null 2>$null
if ($LASTEXITCODE -eq 0) { throw 'This script publishes a fresh clean source folder only. Existing commit history was detected. Use a newly extracted ZIP or inspect and push the history yourself.' }
Invoke-Git @('-c', "user.name=$account", '-c', "user.email=30518204+$account@users.noreply.github.com", 'commit', '-m', 'Initial Test Viewer 2.0.0')
& gh repo create $repository --private --source . --remote origin --push --description 'Private offline companion viewer for Test-Master inspection data'
if ($LASTEXITCODE -ne 0) { throw 'GitHub publication failed. No force push was attempted. Inspect gh repo view and git status before retrying.' }
Write-Host "Published: https://github.com/$repository"

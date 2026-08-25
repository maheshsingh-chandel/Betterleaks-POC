$ErrorActionPreference = "Stop"

function Require-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "$Name is required but was not found on PATH."
    }
}

function Get-EnvOrDefault {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Default
    )
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $Default
    }
    return $value
}

function Is-ZeroSha {
    param([string]$Sha)
    return [string]::IsNullOrWhiteSpace($Sha) -or $Sha -match '^0+$'
}

Require-Command "git"
Require-Command "betterleaks"

$repoRoot = git rev-parse --show-toplevel
Set-Location $repoRoot

$configPath = Get-EnvOrDefault "BETTERLEAKS_CONFIG" "betterleaks.toml"
$confidence = Get-EnvOrDefault "BETTERLEAKS_CONFIDENCE" "low"
$reportPath = Get-EnvOrDefault "BETTERLEAKS_REPORT_PATH" "betterleaks-report.json"
$scanMode = (Get-EnvOrDefault "BETTERLEAKS_SCAN_MODE" "changed").ToLowerInvariant()

if (-not (Test-Path $configPath)) {
    throw "Betterleaks config not found: $configPath"
}

if ($scanMode -eq "repo") {
    Write-Host "Running Betterleaks full repository scan..."
    betterleaks dir . --config $configPath --redact --confidence $confidence --report-path $reportPath --report-format json
    exit $LASTEXITCODE
}

if ($scanMode -ne "changed") {
    throw "Unsupported BETTERLEAKS_SCAN_MODE '$scanMode'. Use 'changed' or 'repo'."
}

$headSha = Get-EnvOrDefault "CI_COMMIT_SHA" ""
if ([string]::IsNullOrWhiteSpace($headSha)) {
    $headSha = git rev-parse HEAD
}

$baseSha = Get-EnvOrDefault "CI_MERGE_REQUEST_DIFF_BASE_SHA" ""
if (Is-ZeroSha $baseSha) {
    $baseSha = Get-EnvOrDefault "CI_COMMIT_BEFORE_SHA" ""
}
if (Is-ZeroSha $baseSha) {
    $baseSha = "$headSha~1"
}

Write-Host "Betterleaks changed-file scan"
Write-Host "Base: $baseSha"
Write-Host "Head: $headSha"

$changedFiles = git diff --name-only --diff-filter=ACMR $baseSha $headSha
if ($LASTEXITCODE -ne 0) {
    throw "Unable to compute changed files between $baseSha and $headSha. Ensure GIT_DEPTH is 0."
}

$changedFiles = @($changedFiles | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($changedFiles.Count -eq 0) {
    Write-Host "No changed files to scan."
    "{}" | Set-Content -Encoding ascii $reportPath
    exit 0
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("betterleaks-ci-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
    foreach ($file in $changedFiles) {
        $target = Join-Path $tempRoot $file
        $targetDir = Split-Path -Parent $target
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
        }

        $content = git show "$headSha`:$file"
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to read staged/head content for changed file: $file"
        }
        $content | Set-Content -Encoding utf8 $target
    }

    Write-Host "Scanning $($changedFiles.Count) changed file(s) with Betterleaks..."
    betterleaks dir $tempRoot --config $configPath --redact --confidence $confidence --report-path $reportPath --report-format json
    exit $LASTEXITCODE
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

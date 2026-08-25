$ErrorActionPreference = "Stop"

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

if (Test-Command "betterleaks") {
    Write-Host "betterleaks is already available:"
    betterleaks --version
    exit 0
}

if ($env:BETTERLEAKS_PATH -and (Test-Path $env:BETTERLEAKS_PATH)) {
    $binDir = Split-Path -Parent $env:BETTERLEAKS_PATH
    $env:PATH = "$binDir;$env:PATH"
    Write-Host "Using betterleaks from BETTERLEAKS_PATH=$env:BETTERLEAKS_PATH"
    & $env:BETTERLEAKS_PATH --version
    exit 0
}

if (Test-Command "go") {
    Write-Host "betterleaks not found. Installing with go install..."
    go install github.com/betterleaks/betterleaks@latest
    $goBin = Join-Path $env:USERPROFILE "go\bin"
    $env:PATH = "$goBin;$env:PATH"
    betterleaks --version
    exit 0
}

throw @"
betterleaks is not installed and Go is not available on this runner.

Fix one of these ways:
1. Preinstall Betterleaks on the custom GitLab runner and add it to PATH.
2. Set a CI/CD variable BETTERLEAKS_PATH pointing to betterleaks.exe.
3. Install Go on the runner so this job can run:
   go install github.com/betterleaks/betterleaks@latest
"@

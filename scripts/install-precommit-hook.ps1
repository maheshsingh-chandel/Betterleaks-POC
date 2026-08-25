$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
    throw "Run this from inside the POC repository."
}

Set-Location $repoRoot

if (-not (Test-Path ".githooks/pre-commit")) {
    throw "Missing .githooks/pre-commit."
}

git config core.hooksPath .githooks

if (-not (Get-Command betterleaks -ErrorAction SilentlyContinue)) {
    Write-Warning "betterleaks is not on PATH yet. The hook is installed, but commits will fail until Betterleaks is installed."
}

Write-Host "Installed Git hooks from .githooks."
Write-Host "Test with: powershell -ExecutionPolicy Bypass -File .\scripts\test-precommit-block.ps1"

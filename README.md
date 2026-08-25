# Betterleaks POC Dummy Repo

This repository is intentionally seeded with fake custom credentials so you can
test Betterleaks locally without exposing real secrets or triggering GitHub push
protection.

## Install the pre-commit POC

Install Betterleaks first:

```powershell
go install github.com/betterleaks/betterleaks@latest
```

Make sure your Go bin directory is on PATH:

```powershell
$env:PATH += ";$env:USERPROFILE\go\bin"
```

Then enable the repo-local Git hook:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-precommit-hook.ps1
```

The hook runs:

```powershell
betterleaks git . --pre-commit --config betterleaks.toml --redact --confidence low
```

## Prove it blocks staged leaks

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-precommit-block.ps1
```

The test script stages a fake internal token, attempts a commit, and expects the
Betterleaks hook to block it. It then unstages and removes the generated test
file.

## Manual scan commands

```powershell
betterleaks dir . -v --redact
betterleaks git . -v --redact
betterleaks dir . --report-path findings.json --report-format json
betterleaks git . --report-path history-findings.json --report-format json
```

Expected behavior:

- `betterleaks dir .` should flag fake custom secrets that still exist in the
  current working tree.
- `betterleaks git .` should scan repository history.

Do not run validation for this POC. These are fake values.

## Custom rules

`betterleaks.toml` extends the bundled Betterleaks rules and adds:

- `poc-internal-service-token`: catches organization-specific token prefixes
  such as `poc_live_` and `poc_prod_`.
- `poc-jwt-signing-secret`: catches hardcoded JWT/session signing secrets.
- `poc-terraform-sensitive-default`: catches Terraform variables with sensitive
  names and hardcoded defaults.

For teams, replace the `poc_*` prefixes with your real internal token prefixes
or service-specific naming conventions.

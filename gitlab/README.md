# Betterleaks GitLab CI POC

This folder contains a GitLab CI implementation for running Betterleaks on a
custom GitLab runner.

## Implementation plan

1. Make Betterleaks available on the runner.
2. Add the pipeline config from `gitlab/.gitlab-ci.yml`.
3. Run Betterleaks in `changed` mode for merge request and branch pipelines.
4. Store a JSON report as a GitLab job artifact.
5. Optionally run `repo` mode on schedules or manually for full repository
   scanning.

## Files

- `.gitlab-ci.yml`: GitLab job definition.
- `scripts/install-betterleaks.ps1`: checks for Betterleaks, uses
  `BETTERLEAKS_PATH` if provided, or installs with `go install` if Go exists.
- `scripts/run-betterleaks.ps1`: runs the scan and writes
  `betterleaks-report.json`.

## Required runner setup

The custom runner needs:

- Git
- PowerShell
- Betterleaks on PATH, or `BETTERLEAKS_PATH` set to `betterleaks.exe`
- Optional: Go, if you want the pipeline to install Betterleaks automatically

Recommended runner approach:

```powershell
go install github.com/betterleaks/betterleaks@latest
$env:PATH += ";$env:USERPROFILE\go\bin"
betterleaks --version
```

For a persistent Windows runner, add this to the machine/user PATH:

```text
%USERPROFILE%\go\bin
```

## Add to GitLab

Copy or move this file to the repository root:

```powershell
Copy-Item gitlab\.gitlab-ci.yml .gitlab-ci.yml
git add .gitlab-ci.yml gitlab
git commit -m "Add Betterleaks GitLab CI POC"
git push origin main
```

If your custom runner uses a different tag, update this section in
`.gitlab-ci.yml`:

```yaml
tags:
  - windows
```

## CI variables

Optional GitLab CI/CD variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `BETTERLEAKS_PATH` | unset | Absolute path to `betterleaks.exe` when it is not on PATH. |
| `BETTERLEAKS_CONFIG` | `betterleaks.toml` | Config file used by the scan. |
| `BETTERLEAKS_CONFIDENCE` | `low` | Minimum confidence threshold. |
| `BETTERLEAKS_REPORT_PATH` | `betterleaks-report.json` | JSON artifact path. |
| `BETTERLEAKS_SCAN_MODE` | `changed` | Use `changed` or `repo`. |

## Verify in GitLab

Create a branch:

```powershell
git checkout -b test/betterleaks-ci
```

Add a fake custom secret:

```powershell
"internal_service_token=poc_live_gitlabci0123456789abcdef01234567" | Out-File -Encoding ascii gitlab-ci-leak.env
git add gitlab-ci-leak.env
git commit --no-verify -m "Test Betterleaks GitLab CI block"
git push origin test/betterleaks-ci
```

Open a merge request. The `betterleaks:scan` job should fail and upload
`betterleaks-report.json` as an artifact.

Clean up the test file after verifying:

```powershell
git rm gitlab-ci-leak.env
git commit -m "Remove Betterleaks CI test secret"
git push origin test/betterleaks-ci
```

The follow-up pipeline should pass.

## Full repository scan

To scan the whole checkout, run the pipeline manually or on a schedule with:

```text
BETTERLEAKS_SCAN_MODE=repo
```

The POC repository intentionally contains fake custom secrets, so full-repo mode
is expected to fail until those samples are removed or moved to test fixtures
that your policy allows.

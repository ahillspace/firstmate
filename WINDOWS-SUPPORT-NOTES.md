# Windows support checkpoints

## 2026-08-23

- Routed OpenCode watcher-arm shell-script launch and handling-delivery confirmation through the established Git Bash discovery contract.
- `FM_GIT_BASH` remains the explicit override, followed by the standard Git for Windows installation paths.
- Missing Git Bash now produces a failed watcher status instead of attempting a bare Windows `bash` executable.
- Validation: `node --check .opencode/plugins/fm-primary-watch-arm.js` passed.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Made OpenCode harness detection case-insensitive for Windows process names and interpreter arguments.
- Added a portable MSYS regression through `tests/fm-supervision-instructions.test.sh` using a simulated `OpenCode.exe` process listing.
- Validation: `bash tests/fm-supervision-instructions.test.sh` passed with 10 ok lines.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash -n bin/fm-harness.sh tests/fm-supervision-instructions.test.sh` and `git diff --check` passed.
- Validation: `bash bin/fm-lint.sh` is pending because ShellCheck 0.11.0 is not installed.
- Added `tests/fm-opencode-plugins.test.sh` with native Windows coverage for OpenCode watcher-arm Git Bash routing.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash -n tests/fm-opencode-plugins.test.sh` and `git diff --check` passed.

- Added `docs/windows.md` with Git Bash installation, `jq` via winget, the official treehouse release zip and running-session `PATH` caveat, Herdr selection, and known Windows limits.
- Linked the Windows guide from the README Documentation table and registered it as an `operator-current` setup surface.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `node` parsed `docs/documentation-audiences.json` and confirmed the Windows setup target and surface classification.
- Validation blocked: `bin/fm-doc-audience-check.sh` requires unavailable Python 3, and `bash bin/fm-lint.sh` requires unavailable ShellCheck 0.11.0.
- Repeated validation confirms ShellCheck 0.11.0 remains unavailable on `PATH` after more than two iterations.
- Recorded the blocker in `BLOCKERS.md` and moved on to delivery prerequisites.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `git diff --check` passed.
- Iteration 6 recorded the delivery report and reran the focused Windows-support suites.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-supervision-instructions.test.sh` passed.
- Validation blocked: `bash bin/fm-lint.sh` stopped because ShellCheck 0.11.0 is unavailable on `PATH`.

## 2026-08-23 iteration 10

- Revalidated the Windows-support focused suites after the prior delivery checkpoint.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation blocked: `bash bin/fm-lint.sh` stopped before linting because ShellCheck 0.11.0 is unavailable.
- `winget` reports no installed ShellCheck package, and the repository installer does not support the Windows host.

## 2026-08-23 iteration 11

- Added the native Windows setup guide to the README Documentation table.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-supervision-instructions.test.sh` passed.
- Validation blocked: `bash bin/fm-lint.sh` stopped because ShellCheck 0.11.0 is unavailable.

## 2026-08-23 iteration 25

- Revalidated the remaining Windows-support delivery gates without changing product files.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: the required headings in `docs/windows.md` and its `README.md` Documentation table link are present.
- Validation blocked: `bash bin/fm-lint.sh` stopped before linting because ShellCheck 0.11.0 is unavailable on `PATH`.
- `WINDOWS-SUPPORT-REPORT.md` is present, but `WINDOWS-SUPPORT-PR.txt` remains absent because PR creation is deferred until the lint gate passes.

## 2026-08-23 iteration 21

- Revalidated the Windows-support focused suites after session reconciliation timed out without producing a digest.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-supervision-instructions.test.sh` passed.
- Validation blocked: `bash bin/fm-lint.sh` stopped because ShellCheck 0.11.0 is unavailable.
- The branch remains clean and synchronized with `origin/windows-support`; `WINDOWS-SUPPORT-PR.txt` is still absent.

## 2026-08-23 iteration 26

- Revalidated the completed Windows-support suites without changing product files.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-supervision-instructions.test.sh` passed.
- Validation blocked: `bash bin/fm-lint.sh` stopped before linting because ShellCheck 0.11.0 is unavailable on `PATH`.
- `WINDOWS-SUPPORT-PR.txt` remains absent, so PR creation remains deferred until the lint gate passes.

## 2026-08-23 iteration 29

- Revalidated the Windows-support delivery gates after a complete session-start reconciliation.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.
- Validation: `bash tests/fm-opencode-plugins.test.sh` passed.
- Validation: `bash tests/fm-supervision-instructions.test.sh` passed.
- Validation blocked: `bash bin/fm-lint.sh` stopped because ShellCheck 0.11.0 is unavailable on `PATH`.
- The branch remains clean and synchronized with `origin/windows-support`.

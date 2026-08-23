# Blockers

None open.

## Resolved 2026-08-23

- ShellCheck 0.11.0 unavailable: installed from the official Windows release
  asset (sha256 8a4e35ab0b331c85d73567b12f2a444df187f483e5079ceffa6bda1faa2e740e)
  into `~/bin`; `bin/fm-install-shellcheck.sh` now supports MINGW64 directly.
- actionlint 1.7.12 unavailable: installed the official windows_amd64 zip
  (sha256 6e7241b51e6817ea6a047693d8e6fed13b31819c9a0dd6c5a726e1592d22f6e9);
  `bin/fm-install-actionlint.sh` now supports MINGW64 directly.
- Python 3 absent for `bin/fm-doc-audience-check.sh`: Python 3.12 was present
  but shadowed by the Microsoft Store `python3` stub; real executables placed
  in `~/bin` (`python3`, `python`) resolve first.
- CRLF checkout made every shell script fail shellcheck SC1017: this clone is
  pinned to LF (`core.autocrlf=false`, `core.eol=lf`) and re-checked out.
- Harness detection returned `unknown` on Git Bash: `detect_own` in
  `bin/fm-harness.sh` now uses the win32 ancestry walker on MSYS-family hosts;
  live verification reports `opencode`.
- `bash bin/fm-lint.sh` exits 0; all three touched test suites pass.

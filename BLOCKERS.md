# Blockers

## ShellCheck 0.11.0 unavailable

- First observed: 2026-08-23.
- The required command `bash bin/fm-lint.sh` exits before linting because `ShellCheck not found`.
- `Get-Command shellcheck` confirms that ShellCheck is not on `PATH`.
- The focused OpenCode plugin, supervision, and session ancestry tests pass without this dependency.
- Resolve by installing ShellCheck 0.11.0 and placing it on `PATH`, then rerun `bash bin/fm-lint.sh`.

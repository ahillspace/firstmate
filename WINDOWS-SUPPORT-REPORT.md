# Native Windows support report

## Delivered

Firstmate now supports native Windows operation through Git Bash.

OpenCode watcher-arm shell-script execution discovers Git Bash through `FM_GIT_BASH` and standard Git for Windows locations.

OpenCode supervision detection recognizes Windows process names on MSYS hosts.

The OpenCode plugin regression suite covers Git Bash routing through the public watcher behavior.

The Windows setup guide documents Git Bash, `jq`, treehouse installation, Herdr selection, and known limits.

## Verification

`bash tests/fm-session-lock-ancestry.test.sh` passes with 8 ok lines.

`bash tests/fm-opencode-plugins.test.sh` passes.

`bash tests/fm-supervision-instructions.test.sh` passes.

`bash bin/fm-lint.sh` remains pending because ShellCheck 0.11.0 is unavailable on the current PATH.

## Remaining risks

Windows watch-arm process-parent traversal still has the documented ppid walk gap.

Windows supervision detection depends on the documented MSYS process listing behavior.

WMI process snapshots may be stale, as documented in the Windows guide.

The pull request URL is pending completion of the lint gate.

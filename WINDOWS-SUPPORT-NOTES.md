# Windows support checkpoints

## 2026-08-23

- Routed OpenCode watcher-arm shell-script launch and handling-delivery confirmation through the established Git Bash discovery contract.
- `FM_GIT_BASH` remains the explicit override, followed by the standard Git for Windows installation paths.
- Missing Git Bash now produces a failed watcher status instead of attempting a bare Windows `bash` executable.
- Validation: `node --check .opencode/plugins/fm-primary-watch-arm.js` passed.
- Validation: `bash tests/fm-session-lock-ancestry.test.sh` passed with 8 ok lines.

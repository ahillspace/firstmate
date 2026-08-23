# Windows

Firstmate runs on Windows through Git Bash.
The supported setup uses Git for Windows with a Bash environment, rather than PowerShell or Command Prompt as the primary shell.

## Install

1. Install [Git for Windows](https://git-scm.com/download/win) and launch Git Bash.
2. Install `jq` from an elevated PowerShell prompt:

```powershell
winget install jqlang.jq
```

3. Install the official `treehouse` release zip from the [treehouse releases page](https://github.com/kunchenguid/treehouse/releases), extract it, and add the directory containing `treehouse.exe` to your Windows `PATH`.
4. Restart Git Bash after changing `PATH`.

The `PATH` used by a running Git Bash session is fixed when that session starts.
If you install or move a tool while Firstmate is running, close and reopen Git Bash so Firstmate and its spawned sessions can discover the updated `PATH`.

Complete the remaining universal tool setup in [`docs/configuration.md`](configuration.md), then authenticate GitHub with `gh auth login`.

## Runtime backend

The default `tmux` backend is not available on native Windows.
Use the experimental Herdr backend from Git Bash instead.

Herdr is selected automatically when the current environment sets `HERDR_ENV=1`.
To select it explicitly, put `herdr` on the first line of the local, gitignored `config/backend` file.
You can also export `FM_BACKEND=herdr` for one shell session.

Herdr requires `jq` and `treehouse` in addition to the universal toolchain.
See [`docs/herdr-backend.md`](herdr-backend.md) for backend-specific behavior and limits.

## Known limits

- The OpenCode watcher-arm process cannot reliably walk a native Windows parent-process chain through the MSYS boundary, so Git Bash routing is required for its shell scripts.
- Supervision harness detection on Windows depends on the process and environment signals available through the current Git Bash session.
- Windows Management Instrumentation (WMI) process snapshots can be stale, so process-based liveness and ancestry checks may lag behind the actual process state.


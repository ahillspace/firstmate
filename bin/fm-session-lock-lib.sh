#!/usr/bin/env bash
# Shared session-lock harness identity.
#
# ONE owner of the "which verified-harness process holds this home's session
# lock, and does the current process descend from that same harness?" decision.
# bin/fm-lock.sh uses it to acquire and inspect state/.lock;
# bin/fm-claude-stop-autoarm.sh uses it to prove a Stop hook fires inside the
# lock-owning primary session before it may arm or rewake.
# This file is sourced by scripts and has no side effects on source.
#
# Two ancestry backends feed the SAME identity matcher: the POSIX `ps -o` walk,
# and a win32 walk for MSYS-family Git Bash hosts whose ps lacks `-o` and cannot
# see native Windows processes (ps -W pid translation plus one PowerShell CIM
# chain walk; liveness is the same CIM row). On the win32 backend every stored
# or compared lock pid is a WINDOWS pid, consistently on both sides of each
# comparison in this file.

# Cursor process identity is NOT expressible as a command-name pattern and is
# deliberately not added to the tables below: Cursor's installed names are
# cursor-agent and the far-too-generic legacy alias `agent`, and it runs as a
# bundled node script. bin/fm-cursor-lib.sh is the fleet's single owner of that
# decision, so this file delegates to it rather than widening the name match.
# shellcheck source=bin/fm-cursor-lib.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fm-cursor-lib.sh"

# Known harness command names; extend when a new adapter is verified.
FM_HARNESS_RE='claude|codex|opencode|grok|kimi|^pi$|^pi-signed$'

# The same harnesses as exact executable names. Keep in sync with
# FM_HARNESS_RE. Used only for the stricter path evidence below, where the
# loose regex would also match ordinary firstmate paths such as
# bin/fm-claude-stop-autoarm.sh.
FM_HARNESS_NAMES=(claude codex opencode grok kimi pi-signed pi)

# Print the exact harness name carried by executable path $1 - its own basename
# or any directory component - or return 1.
#
# This exists because Claude Code's native installer names the per-session
# executable by its version (~/.local/share/claude/versions/2.1.220), so the
# basename identifies nothing while the install path still says claude. Matching
# whole path components only is what keeps that widening safe: an ordinary path
# such as bin/fm-claude-stop-autoarm.sh or ~/.claude/hooks/notify.sh has no
# "claude" component and is correctly not a harness process.
fm_harness_path_name() {  # <path>
  local path=$1 name
  [ -n "$path" ] || return 1
  for name in "${FM_HARNESS_NAMES[@]}"; do
    case "/$path/" in
      */"$name"/*) printf '%s' "$name"; return 0 ;;
    esac
  done
  return 1
}

# True when the process described by command name $1 and full argument string $2
# is a verified harness. Sets FM_HARNESS_IS_CLAUDE for the ancestry walk.
#
# Evidence, in order:
#   1. the basename of the reported command name, against FM_HARNESS_RE.
#   2. an exact harness component in that command path or in argv[0]. Both are
#      needed because the two platforms report different things: macOS reports
#      argv[0] in `ps -o comm=`, while procps on Linux reports the kernel exec
#      name and ignores argv[0] entirely, so a version-named Claude Code binary
#      is identified by its install path on macOS and by argv[0] on Linux.
#   3. a bare interpreter (node, python) running a harness script path.
#   4. Cursor's own structural identity, owned by bin/fm-cursor-lib.sh.
FM_HARNESS_IS_CLAUDE=0
fm_harness_process_matches() {  # <comm> <args>
  local comm=$1 args=$2 base argv0 name
  FM_HARNESS_IS_CLAUDE=0
  base=$(basename -- "$comm")
  if printf '%s' "$base" | grep -qE "$FM_HARNESS_RE"; then
    case "$base" in *claude*) FM_HARNESS_IS_CLAUDE=1 ;; esac
    return 0
  fi
  argv0=${args%% *}
  if name=$(fm_harness_path_name "$comm") || name=$(fm_harness_path_name "$argv0"); then
    case "$name" in claude) FM_HARNESS_IS_CLAUDE=1 ;; esac
    return 0
  fi
  # Bare interpreter (e.g. node): match the harness name in its script path.
  case "$comm" in
    *node*|*python*)
      if printf '%s' "$args" | grep -qE "$FM_HARNESS_RE"; then
        case "$args" in *claude*) FM_HARNESS_IS_CLAUDE=1 ;; esac
        return 0
      fi
      ;;
  esac
  # Cursor: its own owner decides, from Cursor's name or versioned install tree
  # in the command path or argv[0]. Without this a Cursor primary can never
  # locate its own harness in the ancestry, so every session start refuses the
  # fleet lock as read-only and the park can never arm.
  fm_cursor_process_matches "$comm" "$args" "$argv0" && return 0
  return 1
}

# Walk the current process ancestry (up to 16 hops) and print this session's
# contiguous verified-harness ancestry, innermost pid first.
#
# The walk climbs freely until the first harness match, because the caller is
# normally an ordinary shell several levels below its session. After that first
# match it stops at the first non-harness ancestor, so it can never cross a gap
# into an unrelated harness further up the real process tree - for example the
# live session that launched a test as its own subprocess.
#
# For every harness except Claude the innermost match is the session, which is
# where e.g. Pi's shared signed-wrapper ancestry actually holds the lock: a
# "pi-signed" launcher can be the direct parent of the inner "pi" engine pid that
# owns the lock, and the wrapper pid above it is not that owner. Claude Code
# instead runs hooks several levels below the session inside its own nested
# worker chain (hook shell -> claude bg-spare -> claude bg-pty-host -> claude ->
# claude), with no non-harness process between them. Which pid in that run is the
# session cannot be read off the ancestry at all, so the whole contiguous run is
# reported and the callers below decide what they need from it.
# True when this host is an MSYS-family Git Bash, whose `ps` has no POSIX `-o`
# forms and cannot see native Windows processes; such hosts use the win32
# ancestry backend below.
fm_harness_on_windows() {
  case "$(uname -s 2>/dev/null)" in
    MINGW*|MSYS*|CYGWIN*) return 0 ;;
    *) return 1 ;;
  esac
}

# Print one "pid<TAB>comm<TAB>args" row for Windows process id $1, or return 1.
# Evidence only - classification stays with fm_harness_process_matches. The pid
# is validated numeric before it reaches the CIM filter. A null CommandLine
# prints as an empty third field.
fm_win32_process_row() {  # <windows-pid>
  local pid=$1
  case "$pid" in
    ''|*[!0-9]*) return 1 ;;
  esac
  # shellcheck disable=SC2016 # PowerShell command must not be expanded by bash
  FM_WINPID_ROW="$pid" powershell.exe -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "SilentlyContinue"
    $p = $null
    foreach ($try in 1..3) {
      $p = Get-CimInstance Win32_Process -Filter ("ProcessId={0}" -f [int]$env:FM_WINPID_ROW) -Property ProcessId,Name,CommandLine
      if ($p) { break }
      Start-Sleep -Milliseconds 120
    }
    if (-not $p) { exit 1 }
    Write-Output (([string]$p.ProcessId) + "`t" + $p.Name + "`t" + [string]$p.CommandLine)
  ' 2>/dev/null
}

# Print one record for Windows process id $1:
#   pid<US>parent<US>comm<US>args
# (US = ASCII unit separator, char 31), or return 1 when no such process.
# Evidence only - classification stays with fm_harness_process_matches. The
# pid is validated numeric before it reaches the CIM filter; a null
# CommandLine prints as an empty field. Filtered queries are always live,
# unlike whole-table enumerations, which WMI may serve from a stale snapshot
# that misses processes spawned within the last moments.
fm_win32_process_rec() {  # <windows-pid>
  local pid=$1
  case "$pid" in
    ''|*[!0-9]*) return 1 ;;
  esac
# shellcheck disable=SC2016 # PowerShell command must not be expanded by bash
  FM_WINPID_REC="$pid" powershell.exe -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "SilentlyContinue"
    $p = $null
    foreach ($try in 1..3) {
      $p = Get-CimInstance Win32_Process -Filter ("ProcessId={0}" -f [int]$env:FM_WINPID_REC) -Property ProcessId,ParentProcessId,Name,CommandLine
      if ($p) { break }
      Start-Sleep -Milliseconds 120
    }
    if (-not $p) { exit 1 }
    $cl = ([string]$p.CommandLine) -replace "\r|\n", " "
    Write-Output (([string]$p.ProcessId) + [char]31 + ([string]$p.ParentProcessId) + [char]31 + $p.Name + [char]31 + $cl)
  ' 2>/dev/null
}

# Print "pid<TAB>comm<TAB>args" rows for the current process's WINDOWS ancestry,
# innermost first, up to 16 hops, climbing freely until the caller stops at the
# first post-match non-harness row. Each hop is one live filtered CIM query via
# fm_win32_process_rec; the first hop's target is this shell itself, obtained
# as the parent of a throwaway child whose own pid is otherwise irrelevant -
# the child's ParentProcessId IS this shell's Windows pid, with no reliance on
# MSYS pid translation (whose /proc/self/winpid can disagree with the real
# Windows table).
fm_harness_win32_walk() {
  local rec pid parent comm args depth=0
  # Live per-hop climb. Short-lived shell intermediaries exit before their
  # child-reported pids can be queried again, so the chain may die at hop
  # zero; the snapshot scan below covers exactly that case.
# shellcheck disable=SC2016 # PowerShell command must not be expanded by bash
  pid=$(powershell.exe -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "SilentlyContinue"
    $self = Get-CimInstance Win32_Process -Filter ("ProcessId=" + [string]$PID) -Property ParentProcessId
    if (-not $self) { exit 1 }
    Write-Output ([string]$self.ParentProcessId)
  ' 2>/dev/null)
  case "$pid" in
    ''|*[!0-9]*) pid='' ;;
  esac
  while [ -n "$pid" ] && [ "$depth" -lt 16 ]; do
    rec=$(fm_win32_process_rec "$pid") || break
    IFS=$'\031' read -r pid parent comm args <<<"$rec"
    printf '%s\t%s\t%s\n' "$pid" "$comm" "$args"
    pid=$parent
    depth=$((depth + 1))
  done
  [ "$depth" -gt 0 ] && return 0

  # Fallback: whole-table scan for harness-named candidates, oldest first.
  # WMI enumerations may serve a slightly stale snapshot but long-lived
  # primary sessions are always present; emitting the oldest candidates lets
  # the caller's contiguous-run matcher claim the true session owner.
# shellcheck disable=SC2016 # PowerShell command must not be expanded by bash
  powershell.exe -NoProfile -NonInteractive -Command '
    $ErrorActionPreference = "SilentlyContinue"
    $rows = Get-CimInstance Win32_Process -Property ProcessId,ParentProcessId,Name,CommandLine,CreationDate
    foreach ($p in ($rows | Sort-Object CreationDate)) {
      $hay = $p.Name + " " + ([string]$p.CommandLine)
      if ($hay -match "claude|codex|opencode|grok|kimi|pi-signed|\bpi\b|cursor") {
        $cl = ([string]$p.CommandLine) -replace "\r|\n", " "
        Write-Output (([string]$p.ProcessId) + "`t" + $p.Name + "`t" + $cl)
      }
    }
  ' 2>/dev/null
}

# Windows variant of fm_harness_ancestry_pids: same matcher, same contiguous-run
# and Claude-extension rules, fed by the win32 walker instead of POSIX ps.
fm_harness_ancestry_pids_win32() {
  local walk pid comm args extending=0 printed=0
  walk=$(fm_harness_win32_walk) || return 1
  while IFS=$'\t' read -r pid comm args; do
    [ -n "${pid:-}" ] || continue
    if fm_harness_process_matches "$comm" "$args"; then
      printf '%s\n' "$pid"
      printed=1
      [ "$FM_HARNESS_IS_CLAUDE" -eq 1 ] || break
      extending=1
    elif [ "$extending" -eq 1 ]; then
      break
    fi
  done <<EOF
$walk
EOF
  [ "$printed" -eq 1 ]
}

fm_harness_ancestry_pids() {
  if fm_harness_on_windows; then
    fm_harness_ancestry_pids_win32
  else
    fm_harness_ancestry_pids_posix
  fi
}

fm_harness_ancestry_pids_posix() {
  local pid=$$ comm args extending=0 printed=0
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
    comm=$(ps -o comm= -p "$pid" 2>/dev/null) || break
    args=$(ps -o args= -p "$pid" 2>/dev/null)
    if fm_harness_process_matches "$comm" "$args"; then
      printf '%s\n' "$pid"
      printed=1
      [ "$FM_HARNESS_IS_CLAUDE" -eq 1 ] || break
      extending=1
    elif [ "$extending" -eq 1 ]; then
      break
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    [ -n "$pid" ] && [ "$pid" -gt 1 ] || break
  done
  [ "$printed" -eq 1 ]
}

# Print the one pid that identifies this session when the session lock is being
# WRITTEN: the outermost pid of the contiguous run. That is the pid that lives as
# long as the session - a Claude worker several levels in is reaped when its hook
# returns, and a lock naming it would look stale moments later while the session
# is still running. Every non-Claude harness reports a single pid, so this is its
# innermost match unchanged.
fm_harness_ancestry_pid() {
  local pids pid outermost=''
  pids=$(fm_harness_ancestry_pids) || return 1
  while IFS= read -r pid; do
    [ -n "$pid" ] && outermost=$pid
  done <<EOF
$pids
EOF
  [ -n "$outermost" ] || return 1
  printf '%s\n' "$outermost"
}

# True if $1 is a live process that looks like a verified harness.
fm_harness_pid_alive() {
  local pid=$1 comm args
  if fm_harness_on_windows; then
    # The lock stores WINDOWS pids on this backend, which MSYS kill cannot
    # probe and POSIX ps cannot name; the CIM row is both liveness and identity.
    local row
    row=$(fm_win32_process_row "$pid") || return 1
    IFS=$'\t' read -r _ comm args <<<"$row"
    fm_harness_process_matches "$comm" "$args"
    return
  fi
  kill -0 "$pid" 2>/dev/null || return 1
  comm=$(ps -o comm= -p "$pid" 2>/dev/null) || return 1
  args=$(ps -o args= -p "$pid" 2>/dev/null)
  fm_harness_process_matches "$comm" "$args"
}

# True when state dir $1 holds a session lock whose pid is ANY harness ancestor
# of the current process: this script runs inside the session that owns the
# home's fleet lock. Membership is the honest test of that question, because the
# lock owner sits at an unknown depth in a contiguous Claude run - it is the
# outermost pid when the hook fires inside the session's own nested worker chain,
# and an inner pid when a harness-named daemon parents the session. A missing
# lock, a malformed lock, a lock held by a harness outside this ancestry, or an
# ancestry that cannot be resolved all fail closed.
fm_session_lock_owned_by_self() {
  local state=$1 lock_pid pids pid
  lock_pid=$(cat "$state/.lock" 2>/dev/null || true)
  case "$lock_pid" in
    ''|*[!0-9]*) return 1 ;;
  esac
  pids=$(fm_harness_ancestry_pids) || return 1
  while IFS= read -r pid; do
    [ "$pid" = "$lock_pid" ] && return 0
  done <<EOF
$pids
EOF
  return 1
}

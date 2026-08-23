#!/usr/bin/env bash
# run-windows-support-gnhf.sh - overnight GNHF run: finish native Windows support.
#
# Committed launcher (gnhf skill contract): every guardrail flag present.
# Continue on the windows-support branch; push each iteration; open ONE PR;
# never merge.
set -u
cd "$(dirname "$0")" || exit 1

PROMPT=$(cat <<'EOF'
You are continuing a native-Windows support effort for the firstmate repo (you are inside it). First read AGENTS.md, then load the firstmate-coding-guidelines skill from .agents/skills/, then read WINDOWS-SUPPORT-NOTES.md if it exists and trust its checkpoints.

ALREADY DONE - do not redo:
- .opencode/plugins/*.js: Windows EFTYPE fix (Git Bash routing for .sh checks, sync-throw guards) across all five plugins.
- bin/fm-session-lock-lib.sh: win32 ancestry backend (live filtered CIM per-hop walk + oldest-harness fallback scan), fm_harness_on_windows dispatcher, win32 liveness via CIM row.
- bin/fm-wake-lib.sh: MSYS mkdir-based lock fallback (fm_lock_on_msys branch in fm_lock_try_create, fm_lock_owned_here for steal validation, release discards owner dir).
- tests/fm-session-lock-ancestry.test.sh: 8/8 green incl. portable win32 unit cases (fake uname pins backend per fixture).

REMAINING WORK, priority order:
1. fm-primary-watch-arm.js still spawns bare "bash" (spawnArm, confirmHandlingDelivery). Route through the same Git Bash discovery pattern the sibling plugins use (windowsBashForScripts / FM_GIT_BASH env override).
2. Harness detection for supervision instructions prints "primary harness: unknown" for opencode on MSYS. Find the detector (see bin/fm-supervision-instructions.sh and its harness detection path) and make opencode recognized on MINGW/MSYS hosts without weakening other platforms.
3. Add a portable regression test for the plugin runProcess shim: new tests/fm-opencode-plugins.test.sh following existing suite conventions (fm_test_tmproot, fm_fakebin, pass/fail helpers); exercise the Git Bash routing decision logic by extracting it or by invoking node against the plugin file with fixtures. Tests must never assert implementation-source bytes.
4. Write docs/windows.md: setup guide covering Git Bash requirement, jq install (winget), treehouse install (official windows zip; note PATH caveat for already-running sessions), herdr backend selection (HERDR_ENV auto-detect or config/backend), and a Known limits section listing: watch-arm ppid walk gaps, supervision unknown-fallback status, WMI snapshot staleness rationale. Follow docs/documentation-audiences.md classification; add one link line to the README Documentation table.
5. Run bash bin/fm-lint.sh and fix any findings your changes introduced. Do not reformat unrelated code.
6. Only if everything above passes: update README platform badge to macOS | Linux | Windows (Git Bash).

HARD RULES:
- Work ONLY inside this repository tree.
- NEVER merge a PR, never force-push, never delete branches or worktrees, no destructive git commands.
- Do not touch projects/, data/captain*, data/projects.md, or anything outside repo scope except reading.
- No npm global installs; no network calls beyond git push and gh pr create.
- If blocked on one item for more than 2 iterations: record the blocker in BLOCKERS.md with evidence and move on.
- Keep commits small and one-topic; never add AI co-author trailers.
- After each item run the touched suites plus bash tests/fm-session-lock-ancestry.test.sh; checkpoint progress by appending to WINDOWS-SUPPORT-NOTES.md and committing.

DELIVERY: single PR at the end via gh pr create --base main --head windows-support (title "Add native Windows support"); write the PR URL to WINDOWS-SUPPORT-PR.txt; summarize changes and remaining risks in WINDOWS-SUPPORT-REPORT.md.
EOF
)

exec gnhf \
  --agent codex \
  --current-branch \
  --push \
  --prevent-sleep on \
  --max-tokens 200000000 \
  --max-iterations 60 \
  --stop-when "ALL of: (1) bash tests/fm-session-lock-ancestry.test.sh exits 0 with 8 ok lines; (2) tests/fm-opencode-plugins.test.sh exists and exits 0; (3) bash bin/fm-lint.sh exits 0; (4) docs/windows.md exists containing sections Install, Runtime backend, Known limits; (5) README Documentation table links docs/windows.md; (6) all work committed and pushed to origin/windows-support; (7) PR URL recorded in WINDOWS-SUPPORT-PR.txt; (8) WINDOWS-SUPPORT-REPORT.md written" \
  "$PROMPT"

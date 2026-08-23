#!/usr/bin/env bash
# resume-windows-support-gnhf.sh - RESUME of interrupted overnight run
# (.gnhf/runs/you-are-continuing-a-728815 aborted on push 403; origin now
# points at the ahillspace fork and windows-support is pushed there).
# Same caps and stop condition; DONE vs REMAINING stated explicitly.
set -u
cd "$(dirname "$0")" || exit 1

PROMPT=$(cat <<'EOF'
RESUME of an interrupted GNHF run on firstmate's native Windows support. You are inside the repo on branch windows-support. First read AGENTS.md, then load the firstmate-coding-guidelines skill from .agents/skills/, then read WINDOWS-SUPPORT-NOTES.md if present and trust checkpoints. Pushes now work (origin = ahillspace/firstmate fork).

DONE - do not redo:
- All baseline Windows fixes committed at 7e63c3f (plugins EFTYPE shims, win32 ancestry backend in bin/fm-session-lock-lib.sh, MSYS mkdir lock fallback in bin/fm-wake-lib.sh, extended tests/fm-session-lock-ancestry.test.sh, 8/8 green).
- Item 1 COMMITTED at 8c4a70a: fm-primary-watch-arm.js spawns route through discovered Git Bash with clear missing-Bash failure path.
- Branch pushed to origin (fork).

REMAINING, priority order:
2. Harness detection for supervision instructions prints "primary harness: unknown" for opencode on MSYS hosts. Find the detector behind bin/fm-supervision-instructions.sh and make opencode recognized on MINGW/MSYS without weakening other platforms. Add or extend a portable test for it.
3. tests/fm-opencode-plugins.test.sh: portable regression suite for the plugin runProcess Git-Bash routing shim, following existing conventions (fm_test_tmproot/fm_fakebin/pass/fail). Never assert implementation-source bytes.
4. docs/windows.md setup guide: Git Bash requirement, jq via winget, treehouse official zip plus PATH caveat for running sessions, herdr backend selection (HERDR_ENV auto-detect or config/backend), Known limits (watch-arm ppid walk gap, supervision detection status, WMI snapshot staleness). Follow docs/documentation-audiences.md; add one link line to README Documentation table.
5. Run bash bin/fm-lint.sh; fix only findings your changes introduced.
6. Only if all above pass: flip README platform badge to macOS | Linux | Windows (Git Bash).

HARD RULES:
- Work ONLY inside this repository tree.
- NEVER merge a PR; never force-push; never delete branches/worktrees; no destructive git.
- Do not modify projects/, data/captain*, data/projects.md.
- No npm global installs; network limited to git push and gh pr create.
- Blocked more than 2 iterations on one item: record in BLOCKERS.md with evidence, move on.
- Small single-topic commits; never add AI co-author trailers.
- After each item run touched suites plus tests/fm-session-lock-ancestry.test.sh; append checkpoint to WINDOWS-SUPPORT-NOTES.md and commit.

DELIVERY: when stop conditions are met, open ONE PR: gh pr create --repo kunchenguid/firstmate --base main --head ahillspace:windows-support --title "Add native Windows support"; write its URL to WINDOWS-SUPPORT-PR.txt; write WINDOWS-SUPPORT-REPORT.md summarizing changes and remaining risks.
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

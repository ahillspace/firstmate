#!/usr/bin/env bash
# Portable regression coverage for OpenCode plugin process routing on Windows.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT=$(fm_test_tmproot fm-opencode-plugins)

test_watch_arm_uses_discovered_git_bash_on_windows() {
  local fixture="$TMP_ROOT/windows-routing.mjs"
  local log="$TMP_ROOT/git-bash.log"
  local home="$TMP_ROOT/home"
  local repo="$TMP_ROOT/repo"
  local out
  local root_win plugin_win home_win bash_win log_win

  if [ "$(node -p 'process.platform')" != win32 ]; then
    pass "OpenCode Windows Git Bash routing fixture skipped on non-Windows hosts"
    return 0
  fi
  root_win=$(cygpath -w "$repo" 2>/dev/null || printf '%s' "$repo")
  plugin_win=$(cygpath -w "$ROOT/.opencode/plugins/fm-primary-watch-arm.js" 2>/dev/null || printf '%s' "$ROOT/.opencode/plugins/fm-primary-watch-arm.js")
  home_win=$(cygpath -w "$home" 2>/dev/null || printf '%s' "$home")
  bash_win=$(cygpath -w "$(command -v bash)" 2>/dev/null || command -v bash)
  log_win=$(cygpath -w "$log" 2>/dev/null || printf '%s' "$log")

  mkdir -p "$home/state" "$home/config"
  mkdir -p "$repo/bin"
  git init -q "$repo"
  : > "$repo/AGENTS.md"
  printf '1\n' > "$home/state/opencode.meta"
  printf '%s\n' "$$" > "$home/state/.lock"

  cat > "$repo/bin/fm-watch-arm.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${FM_TEST_GIT_BASH_LOG:?}"
printf 'watcher: started pid=%s recovery-generation=test-generation\n' "$$"
SH
  chmod +x "$repo/bin/fm-watch-arm.sh"

  cat > "$fixture" <<'JS'
const { pathToFileURL } = await import("node:url");
const { existsSync, writeFileSync } = await import("node:fs");
const pluginURL = pathToFileURL(process.env.FM_PLUGIN).href;
const { FmPrimaryWatchArm } = await import(pluginURL);
writeFileSync(`${process.env.FM_HOME}/state/.lock`, `${process.pid}\n`);
const hooks = await FmPrimaryWatchArm({
  client: { session: { promptAsync: async () => {} } },
  directory: process.env.FM_ROOT,
});
const result = await hooks.event({ event: { type: "session.idle", properties: { sessionID: "test-session" } } });
if (result !== undefined) throw new Error(`unexpected hook result: ${result}`);
for (let i = 0; i < 250 && !existsSync(process.env.FM_TEST_GIT_BASH_LOG); i += 1) {
  await new Promise((resolve) => setTimeout(resolve, 20));
}
if (!existsSync(process.env.FM_TEST_GIT_BASH_LOG)) throw new Error("Git Bash fixture was not launched");
JS

  out=$(FM_PLUGIN="$plugin_win" FM_ROOT="$root_win" FM_HOME="$home_win" \
    FM_STATE_OVERRIDE="$home_win/state" FM_CONFIG_OVERRIDE="$home_win/config" \
    FM_GIT_BASH="$bash_win" FM_TEST_GIT_BASH_LOG="$log_win" node "$fixture" 2>&1) || \
    fail "OpenCode Windows routing fixture failed: $out"
  assert_contains "$(sed -n '1p' "$log")" "--restart" \
    "watcher arm did not reach the shell script through Git Bash"
  pass "OpenCode watcher arm routes Windows shell scripts through discovered Git Bash"
}

test_watch_arm_uses_discovered_git_bash_on_windows

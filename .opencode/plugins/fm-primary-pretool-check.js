import { realpathSync, existsSync } from "node:fs";
import { resolve } from "node:path";
import { spawn } from "node:child_process";

// PreToolUse seatbelt for OpenCode: the arm mechanism itself lives entirely in
// fm-primary-watch-arm.js (a plugin-owned child process, never a model tool
// call), so the residual risk here is the AGENT shelling `bin/fm-watch-arm.sh`
// wrong through its own bash tool - the anti-pattern bin/fm-arm-pretool-check.sh
// guards against (see that script's header and docs/arm-pretool-check.md).
// tool.execute.before can block by throwing (verified 2026-07-09 against
// OpenCode 1.17.15: throwing here prevents the bash command from running and
// surfaces the thrown message as the failed tool result).

// Windows cannot execute a .sh script directly, and Bun's spawn throws
// synchronously (EFTYPE) instead of emitting an error event, which killed
// every bash tool call. Route .sh checks through Git Bash when present and
// treat any spawn failure the same as the existing missing-script allow path.
// FM_GIT_BASH overrides the discovered Git Bash location.
function windowsBashForScripts() {
  if (process.platform !== "win32") return null;
  const candidates = [
    process.env.FM_GIT_BASH,
    "C:\\Program Files\\Git\\bin\\bash.exe",
    "C:\\Program Files\\Git\\usr\\bin\\bash.exe",
    "C:\\Program Files (x86)\\Git\\bin\\bash.exe",
  ].filter(Boolean);
  return candidates.find((path) => existsSync(path)) ?? null;
}

function runProcess(command, args) {
  return new Promise((resolvePromise) => {
    let file = command;
    let argv = [...args];
    if (process.platform === "win32" && /\.sh$/i.test(command)) {
      const bash = windowsBashForScripts();
      if (!bash) {
        resolvePromise({ code: 0, stdout: "", stderr: "" });
        return;
      }
      file = bash;
      argv = [command.replace(/\\/g, "/"), ...argv];
    }
    let child;
    try {
      child = spawn(file, argv, { stdio: ["ignore", "pipe", "pipe"] });
    } catch {
      resolvePromise({ code: 0, stdout: "", stderr: "" });
      return;
    }
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });
    child.on("error", () => resolvePromise({ code: 0, stdout: "", stderr: "" }));
    child.on("close", (code) => resolvePromise({ code: code ?? 0, stdout, stderr }));
  });
}

async function resolveRoot(anchor) {
  if (!anchor) return "";
  const result = await runProcess("git", ["-C", anchor, "rev-parse", "--show-toplevel"]);
  const root = result.stdout.trim();
  if (result.code === 0 && root) return root;
  try {
    return realpathSync(anchor);
  } catch {
    return resolve(anchor);
  }
}

export const FmPrimaryPretoolCheck = async ({ directory, worktree }) => {
  const root = worktree ? (() => {
    try {
      return realpathSync(worktree);
    } catch {
      return resolve(worktree);
    }
  })() : await resolveRoot(directory);

  return {
    "tool.execute.before": async (input, output) => {
      if (!root || input?.tool !== "bash") return;
      const command = output?.args?.command;
      if (!command || typeof command !== "string") return;

      const result = await runProcess(`${root}/bin/fm-arm-pretool-check.sh`, ["--command", command]);
      if (result.code !== 2) return;

      const reason = result.stderr.trim() || "denied by the watcher-arm PreToolUse seatbelt";
      throw new Error(reason);
    },
  };
};

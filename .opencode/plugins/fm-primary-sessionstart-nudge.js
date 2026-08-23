import { spawn } from "node:child_process";
import { realpathSync, existsSync } from "node:fs";
import { resolve } from "node:path";

const handledSessions = new Set();

// Windows cannot execute a .sh script directly, and Bun's spawn throws
// synchronously (EFTYPE) instead of emitting an error event. Route the .sh
// nudge through Git Bash when present and treat any spawn failure the same
// as the existing missing-script skip path. FM_GIT_BASH overrides it.
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
  return new Promise((resolveResult) => {
    let file = command;
    let argv = [...args];
    if (process.platform === "win32" && /\.sh$/i.test(command)) {
      const bash = windowsBashForScripts();
      if (!bash) {
        resolveResult({ code: 0, stdout: "" });
        return;
      }
      file = bash;
      argv = [command.replace(/\\/g, "/"), ...argv];
    }
    let child;
    try {
      child = spawn(file, argv, { stdio: ["ignore", "pipe", "ignore"] });
    } catch {
      resolveResult({ code: 0, stdout: "" });
      return;
    }
    let stdout = "";
    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.on("error", () => resolveResult({ code: 0, stdout: "" }));
    child.on("close", (code) => resolveResult({ code: code ?? 0, stdout }));
  });
}

function resolvePath(anchor) {
  try {
    return realpathSync(anchor);
  } catch {
    return resolve(anchor);
  }
}

async function resolveRoot(anchor) {
  if (!anchor) return "";
  const result = await runProcess("git", ["-C", anchor, "rev-parse", "--show-toplevel"]);
  const root = result.stdout.trim();
  if (result.code === 0 && root) return root;
  return resolvePath(anchor);
}

export const FmPrimarySessionstartNudge = async ({ client, directory, worktree }) => {
  const root = worktree ? resolvePath(worktree) : await resolveRoot(directory);

  return {
    event: async ({ event }) => {
      if (event.type !== "session.created") return;
      const sessionID = event.properties?.info?.id ?? event.properties?.sessionID;
      if (!sessionID || handledSessions.has(sessionID) || !root) return;
      handledSessions.add(sessionID);

      const result = await runProcess(`${root}/bin/fm-sessionstart-nudge.sh`, []);
      const nudge = result.code === 0 ? result.stdout.trim() : "";
      if (!nudge) return;

      try {
        await client.session.promptAsync({
          path: { id: sessionID },
          body: {
            parts: [{ type: "text", text: nudge }],
          },
        });
      } catch {
      }
    },
  };
};

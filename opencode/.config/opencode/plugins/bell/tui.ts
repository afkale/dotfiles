import { execFileSync } from "node:child_process"
import { Plugin } from "@opencode/plugin/tui"

// Ring the terminal bell when this TUI needs attention.
// The bell is a plain BEL byte on stdout: terminals can play a sound,
// flash, or mark the session as unread.
export default Plugin.define({
  id: "afkale.bell",
  setup(context) {
    let last = 0

    // A bell in the pane the user is already looking at only leaves a stale
    // notification mark behind. Only ring when this pane is not visible.
    const isFocusedInTmux = () => {
      const pane = process.env.TMUX_PANE
      if (!pane) return false

      try {
        const state = execFileSync(
          "tmux",
          [
            "display-message",
            "-p",
            "-t",
            pane,
            "#{pane_active} #{window_active} #{session_attached}",
          ],
          { encoding: "utf8", timeout: 500, stdio: ["ignore", "pipe", "ignore"] },
        )
        const [paneActive, windowActive, attached] = state.trim().split(/\s+/).map(Number)
        return paneActive === 1 && windowActive === 1 && attached > 0
      } catch {
        return false
      }
    }

    const ring = () => {
      if (!process.stdout.isTTY) return
      if (isFocusedInTmux()) return

      const now = Date.now()
      if (now - last < 1000) return
      last = now
      process.stdout.write("\x07")
    }

    const isRoot = (sessionID?: string) => {
      if (!sessionID) return true
      return !context.data.session.get(sessionID)?.parentID
    }

    // The background service broadcasts events for every session, including
    // sessions shown by other OpenCode instances and dedicated `ai run` jobs.
    // Ignore those; this TUI only needs to announce its own tabs and the
    // session currently on screen.
    const showsSession = (sessionID?: string) => {
      if (!sessionID) return false

      const shown = new Set<string>()
      try {
        const route = context.ui.router.current()
        if (route.type === "session") shown.add(route.sessionID)
        else if (route.type === "plugin" && route.data?.sessionID) shown.add(route.data.sessionID)
      } catch {
        // Router state is unavailable during startup; fall through.
      }
      try {
        if (context.ui.tabs.enabled()) {
          for (const tab of context.ui.tabs.list()) shown.add(tab.sessionID)
        }
      } catch {
        // Tabs are optional; the current route is enough.
      }

      if (shown.has(sessionID)) return true
      try {
        const root = context.data.session.root(sessionID)
        return root ? shown.has(root) : false
      } catch {
        return false
      }
    }

    const ringForSession = (sessionID?: string) => {
      if (showsSession(sessionID)) ring()
    }

    const stops = [
      context.data.on("permission.asked", (event) => ringForSession(event.data.sessionID)),
      context.data.on("form.created", (event) => {
        // Global forms are not tied to a session, so ignore them.
        if (event.data.form.sessionID !== "global") ringForSession(event.data.form.sessionID)
      }),
      context.data.on("session.execution.succeeded", (event) => {
        if (isRoot(event.data.sessionID)) ringForSession(event.data.sessionID)
      }),
      context.data.on("session.execution.failed", (event) => {
        if (isRoot(event.data.sessionID)) ringForSession(event.data.sessionID)
      }),
    ]

    return () => stops.forEach((stop) => stop())
  },
})

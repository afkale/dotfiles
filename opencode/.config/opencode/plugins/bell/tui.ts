import { Plugin } from "@opencode/plugin/tui"

// Ring the terminal bell when this TUI needs attention.
// The bell is a plain BEL byte on stdout: terminals can play a sound,
// flash, or mark the session as unread.
export default Plugin.define({
  id: "afkale.bell",
  setup(context) {
    let last = 0

    const ring = () => {
      const now = Date.now()
      if (now - last < 1000) return
      last = now
      if (process.stdout.isTTY) process.stdout.write("\x07")
    }

    const isRoot = (sessionID?: string) => {
      if (!sessionID) return true
      return !context.data.session.get(sessionID)?.parentID
    }

    const stops = [
      context.data.on("permission.asked", ring),
      context.data.on("form.created", (event) => {
        // Global forms are not tied to a session, so ignore them.
        if (event.data.form.sessionID !== "global") ring()
      }),
      context.data.on("session.execution.succeeded", (event) => {
        if (isRoot(event.data.sessionID)) ring()
      }),
      context.data.on("session.execution.failed", (event) => {
        if (isRoot(event.data.sessionID)) ring()
      }),
    ]

    return () => stops.forEach((stop) => stop())
  },
})

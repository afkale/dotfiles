import { Plugin } from "@opencode/plugin/tui";
import { execFileSync } from "node:child_process";

export default Plugin.define({
  id: "agent-manager.track-conversation",
  setup(context: any) {
    let last = "";
    const check = () => {
      const route = context.ui.router.current();
      const sessionID = route.type === "session" ? route.sessionID : undefined;
      if (!sessionID || sessionID === last) return;
      const info = context.data.session.get(sessionID);
      if (!info || info.parentID) return;
      try {
        execFileSync("agent-manager", ["track-conversation", "--tool", "opencode", "--id", sessionID], { stdio: ["ignore", "ignore", "pipe"] });
        last = sessionID;
      } catch {}
    };
    const timer = setInterval(check, 250);
    check();
    return () => clearInterval(timer);
  },
});

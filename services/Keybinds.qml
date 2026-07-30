pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Liest die aktiven Hyprland-Keybinds via `hyprctl binds -j` und stellt sie als
// aufbereitete Liste bereit (fuer das Cheatsheet-Overlay).
// Jeder Eintrag: { key: "SUPER + F1", action: "…", raw: <original> }
Singleton {
    id: root

    // Liste aufbereiteter Binds: [{ key, action }]
    property var binds: []
    property bool loading: false

    // Modmask-Bits (Hyprland/wlroots): SHIFT=1, CAPS=2, CTRL=4, ALT=8,
    // MOD2=16, MOD3=32, SUPER(LOGO)=64, MOD5=128.
    function modString(mask) {
        const parts = [];
        if (mask & 64) parts.push("SUPER");
        if (mask & 4) parts.push("CTRL");
        if (mask & 8) parts.push("ALT");
        if (mask & 1) parts.push("SHIFT");
        return parts;
    }

    // Lesbare Aktion aus dispatcher + arg. caelestia:global-Binds bekommen sprechende Namen.
    readonly property var caelestiaActions: ({
        "launcher": Tr.t("Launcher"),
        "session": Tr.t("Session"),
        "sidebar": Tr.t("Sidebar"),
        "dashboard": Tr.t("Dashboard"),
        "showall": Tr.t("Toggle all panels"),
        "utilities": Tr.t("Utilities"),
        "cheatsheet": Tr.t("Keyboard shortcuts"),
        "clearNotifs": Tr.t("Clear notifications"),
        "lock": Tr.t("Lock"),
        "screenshot": Tr.t("Screenshot"),
        "mediaToggle": Tr.t("Play/Pause"),
        "mediaNext": Tr.t("Next track"),
        "mediaPrev": Tr.t("Previous track")
    })

    function actionString(dispatcher, arg) {
        // caelestia:<name> -> sprechender Name
        if (dispatcher === "global" && arg && arg.indexOf("caelestia:") === 0) {
            const name = arg.substring("caelestia:".length);
            return root.caelestiaActions[name] ?? name;
        }
        if (!arg || arg.length === 0)
            return dispatcher;
        return dispatcher + " " + arg;
    }

    function reload() {
        root.loading = true;
        proc.running = true;
    }

    Process {
        id: proc

        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                let data;
                try {
                    data = JSON.parse(text);
                } catch (e) {
                    root.binds = [];
                    return;
                }
                const out = [];
                for (const b of data) {
                    const mods = root.modString(b.modmask ?? 0);
                    const keyName = (b.key && b.key.length) ? b.key : (b.keycode ? ("code:" + b.keycode) : "");
                    if (!keyName)
                        continue;
                    const keyStr = mods.concat([keyName]).join(" + ");
                    out.push({
                        key: keyStr,
                        action: root.actionString(b.dispatcher ?? "", b.arg ?? "")
                    });
                }
                root.binds = out;
            }
        }
    }
}

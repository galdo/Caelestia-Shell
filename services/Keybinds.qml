pragma Singleton

import QtQuick
import Quickshell

// Kuratierte Uebersicht der wichtigsten Hyprland-Shortcuts (fuer das Cheatsheet).
// Handgepflegt, weil die Lua-Config in `hyprctl binds` nur "__lua" statt lesbarer
// Aktionen liefert. Bei Bind-Aenderungen in keybinds.lua hier nachziehen.
// Gruppen: { title, items: [{ key, action }] }
Singleton {
    id: root

    readonly property var groups: [
        {
            "title": Tr.t("Windows"),
            "items": [
                { "key": "SUPER + Q", "action": Tr.t("Close window") },
                { "key": "SUPER + ALT + Space", "action": Tr.t("Toggle floating") },
                { "key": "SUPER + F", "action": Tr.t("Fullscreen") },
                { "key": "SUPER + P", "action": Tr.t("Pin window") },
                { "key": "SUPER + ←/→/↑/↓", "action": Tr.t("Focus window") },
                { "key": "SUPER + SHIFT + ←/→/↑/↓", "action": Tr.t("Move window") },
                { "key": "SUPER + Z", "action": Tr.t("Drag window (mouse)") },
                { "key": "SUPER + X", "action": Tr.t("Resize window (mouse)") }
            ]
        },
        {
            "title": Tr.t("Workspaces"),
            "items": [
                { "key": "SUPER + 1–9", "action": Tr.t("Switch to workspace") },
                { "key": "SUPER + ALT + 1–9", "action": Tr.t("Move window to workspace") },
                { "key": "SUPER + S", "action": Tr.t("Special workspace") },
                { "key": "SUPER + M", "action": Tr.t("Music workspace") },
                { "key": "SUPER + D", "action": Tr.t("Communication workspace") },
                { "key": "SUPER + R", "action": Tr.t("Todo workspace") }
            ]
        },
        {
            "title": Tr.t("Applications"),
            "items": [
                { "key": "SUPER + T", "action": Tr.t("Terminal") },
                { "key": "SUPER + W", "action": Tr.t("Browser") },
                { "key": "SUPER + C", "action": Tr.t("Editor") },
                { "key": "SUPER + E", "action": Tr.t("File manager") }
            ]
        },
        {
            "title": Tr.t("Shell"),
            "items": [
                { "key": "SUPER", "action": Tr.t("Launcher") },
                { "key": "SUPER + N", "action": Tr.t("Sidebar") },
                { "key": "SUPER + K", "action": Tr.t("Toggle all panels") },
                { "key": "CTRL + ALT + Delete", "action": Tr.t("Session") },
                { "key": "SUPER + L", "action": Tr.t("Lock") },
                { "key": "SUPER + F1", "action": Tr.t("Keyboard shortcuts") },
                { "key": "SUPER + V", "action": Tr.t("Clipboard") },
                { "key": "Print", "action": Tr.t("Screenshot") }
            ]
        },
        {
            "title": Tr.t("Media & volume"),
            "items": [
                { "key": "XF86AudioRaiseVolume", "action": Tr.t("Volume up") },
                { "key": "XF86AudioLowerVolume", "action": Tr.t("Volume down") },
                { "key": "XF86AudioMute", "action": Tr.t("Mute") },
                { "key": "XF86AudioPlay", "action": Tr.t("Play/Pause") },
                { "key": "XF86AudioNext", "action": Tr.t("Next track") },
                { "key": "XF86AudioPrev", "action": Tr.t("Previous track") }
            ]
        }
    ]
}

pragma Singleton

import QtQuick
import qs.services

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            label: Tr.t("Wallpaper & style"),
            icon: "palette",
            description: Tr.t("Wallpaper, fonts, colours"),
            category: "appearance"
        },

        // Connectivity
        // TODO
        // {
        //     label: Tr.t("Display"),
        //     icon: "monitor",
        //     description: Tr.t("Output configuration"),
        //     category: "connectivity"
        // },
        {
            label: Tr.t("Network"),
            icon: "wifi",
            description: Tr.t("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            label: Tr.t("Connected devices"),
            icon: "devices_other",
            description: Tr.t("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            label: Tr.t("Audio"),
            icon: "volume_up",
            description: Tr.t("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        {
            label: Tr.t("Updates"),
            icon: "update",
            description: Tr.t("System updates"),
            category: "system"
        },
        {
            label: Tr.t("Plugins"),
            icon: "extension",
            description: Tr.t("Manage plugins"),
            category: "system"
        },

        // Shell
        {
            label: Tr.t("Panels"),
            icon: "dock_to_bottom",
            description: Tr.t("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            label: Tr.t("Dock"),
            icon: "apps",
            description: Tr.t("Pinned apps, position"),
            category: "shell"
        },
        {
            label: Tr.t("Apps"),
            icon: "apps",
            description: Tr.t("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            label: Tr.t("Services"),
            icon: "build",
            description: Tr.t("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            label: Tr.t("Language & region"),
            icon: "globe",
            description: Tr.t("UI language, weather location, display units"),
            category: "shell"
        },

        // About
        {
            label: Tr.t("About"),
            icon: "info",
            description: Tr.t("System information, credits"),
            category: "about"
        },
    ]
}

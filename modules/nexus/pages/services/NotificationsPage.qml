import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root

    // Notification fullscreen visibility, mapped to GlobalConfig.notifs.fullscreen
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: Tr.t("Off")
            icon: "notifications_off"
        },
        MenuItem {
            text: Tr.t("On")
            icon: "notifications"
        }
    ]
    readonly property list<string> notifFullscreenValues: ["off", "on"]

    // Toast fullscreen visibility, mapped to GlobalConfig.utilities.toasts.fullscreen
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: Tr.t("Off")
            icon: "notifications_off"
        },
        MenuItem {
            text: Tr.t("Important")
            icon: "priority_high"
        },
        MenuItem {
            text: Tr.t("On")
            icon: "notifications"
        }
    ]
    readonly property list<string> toastFullscreenValues: ["off", "important", "all"]

    title: Tr.t("Notifications")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Notifications
        SectionHeader {
            first: true
            text: Tr.t("Notifications")
        }

        SelectRow {
            first: true
            label: Tr.t("Show in fullscreen")
            subtext: Tr.t("Whether notifications appear over fullscreen apps")
            menuItems: root.notifFullscreenItems
            active: root.notifFullscreenItems[Math.max(0, root.notifFullscreenValues.indexOf(GlobalConfig.notifs.fullscreen))]
            onSelected: item => GlobalConfig.notifs.fullscreen = root.notifFullscreenValues[root.notifFullscreenItems.indexOf(item)]
        }

        ToggleRow {
            text: Tr.t("Expire automatically")
            subtext: Tr.t("Dismiss notifications after their timeout")
            checked: GlobalConfig.notifs.expire
            onToggled: GlobalConfig.notifs.expire = checked
        }

        ToggleRow {
            text: Tr.t("Open expanded")
            subtext: Tr.t("Show notifications expanded by default")
            checked: GlobalConfig.notifs.openExpanded
            onToggled: GlobalConfig.notifs.openExpanded = checked
        }

        StepperRow {
            label: Tr.t("Default timeout")
            subtext: Tr.t("Time before a notification dismisses (ms)")
            value: GlobalConfig.notifs.defaultExpireTimeout
            from: 1000
            to: 60000
            stepSize: 500
            onMoved: v => GlobalConfig.notifs.defaultExpireTimeout = Math.round(v)
        }

        StepperRow {
            last: true
            label: Tr.t("Group preview count")
            subtext: Tr.t("Notifications shown per group before collapsing")
            value: GlobalConfig.notifs.groupPreviewNum
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.notifs.groupPreviewNum = Math.round(v)
        }

        // Toasts
        SectionHeader {
            text: Tr.t("Toasts")
        }

        SelectRow {
            first: true
            label: Tr.t("Show in fullscreen")
            subtext: Tr.t("Whether toasts appear over fullscreen apps")
            menuItems: root.toastFullscreenItems
            active: root.toastFullscreenItems[Math.max(0, root.toastFullscreenValues.indexOf(GlobalConfig.utilities.toasts.fullscreen))]
            onSelected: item => GlobalConfig.utilities.toasts.fullscreen = root.toastFullscreenValues[root.toastFullscreenItems.indexOf(item)]
        }

        StepperRow {
            last: true
            label: Tr.t("Visible toasts")
            subtext: Tr.t("Maximum number of toasts shown at once")
            value: GlobalConfig.utilities.maxToasts
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.utilities.maxToasts = Math.round(v)
        }

        // Toast events
        SectionHeader {
            text: Tr.t("Toast events")
        }

        ToggleRow {
            first: true
            text: Tr.t("Charging changes")
            checked: GlobalConfig.utilities.toasts.chargingChanged
            onToggled: GlobalConfig.utilities.toasts.chargingChanged = checked
        }

        ToggleRow {
            text: Tr.t("Game mode changes")
            checked: GlobalConfig.utilities.toasts.gameModeChanged
            onToggled: GlobalConfig.utilities.toasts.gameModeChanged = checked
        }

        ToggleRow {
            text: Tr.t("Do not disturb changes")
            checked: GlobalConfig.utilities.toasts.dndChanged
            onToggled: GlobalConfig.utilities.toasts.dndChanged = checked
        }

        ToggleRow {
            text: Tr.t("Audio output changes")
            checked: GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: GlobalConfig.utilities.toasts.audioOutputChanged = checked
        }

        ToggleRow {
            text: Tr.t("Audio input changes")
            checked: GlobalConfig.utilities.toasts.audioInputChanged
            onToggled: GlobalConfig.utilities.toasts.audioInputChanged = checked
        }

        ToggleRow {
            text: Tr.t("Caps lock changes")
            checked: GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: GlobalConfig.utilities.toasts.capsLockChanged = checked
        }

        ToggleRow {
            text: Tr.t("Num lock changes")
            checked: GlobalConfig.utilities.toasts.numLockChanged
            onToggled: GlobalConfig.utilities.toasts.numLockChanged = checked
        }

        ToggleRow {
            text: Tr.t("Keyboard layout changes")
            checked: GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: GlobalConfig.utilities.toasts.kbLayoutChanged = checked
        }

        ToggleRow {
            text: Tr.t("VPN changes")
            checked: GlobalConfig.utilities.toasts.vpnChanged
            onToggled: GlobalConfig.utilities.toasts.vpnChanged = checked
        }

        ToggleRow {
            last: true
            text: Tr.t("Now playing")
            checked: GlobalConfig.utilities.toasts.nowPlaying
            onToggled: GlobalConfig.utilities.toasts.nowPlaying = checked
        }
    }
}

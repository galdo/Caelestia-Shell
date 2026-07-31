import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root

    title: Tr.t("Panels")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        NavRow {
            first: true
            icon: "dashboard"
            label: Tr.t("Dashboard")
            status: Config.dashboard.enabled ? Tr.t("Enabled") : Tr.t("Disabled")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            icon: "dock_to_bottom"
            label: Tr.t("Taskbar")
            status: Config.bar.persistent ? Tr.t("Always visible") : Config.bar.showOnHover ? Tr.t("Reveal on hover") : Tr.t("Reveal on drag")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "apps"
            label: Tr.t("Launcher")
            status: Config.launcher.enabled ? Tr.t("Enabled") : Tr.t("Disabled")
            onClicked: root.nState.openSubPage(3)
        }

        NavRow {
            icon: "dock_to_right"
            label: Tr.t("Sidebar")
            status: Config.sidebar.enabled ? Tr.t("Enabled") : Tr.t("Disabled")
            onClicked: root.nState.openSubPage(4)
        }

        NavRow {
            icon: "construction"
            label: Tr.t("Utilities")
            status: Config.utilities.enabled ? Tr.t("Enabled") : Tr.t("Disabled")
            onClicked: root.nState.openSubPage(5)
        }

        NavRow {
            last: true
            icon: "apps"
            label: Tr.t("Dock")
            status: GlobalConfig.dock.enabled ? Tr.t("Enabled") : Tr.t("Disabled")
            onClicked: root.nState.openSubPage(11)
        }
    }
}

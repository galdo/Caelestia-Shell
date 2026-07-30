pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root

    title: Tr.t("Status icons")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Visible icons
        SectionHeader {
            first: true
            text: Tr.t("Visible icons")
        }

        ToggleRow {
            first: true
            text: Tr.t("Speakers")
            checked: Config.bar.status.showAudio
            onToggled: GlobalConfig.bar.status.showAudio = checked
        }

        ToggleRow {
            text: Tr.t("Microphone")
            checked: Config.bar.status.showMicrophone
            onToggled: GlobalConfig.bar.status.showMicrophone = checked
        }

        ToggleRow {
            text: Tr.t("Keyboard layout")
            checked: Config.bar.status.showKbLayout
            onToggled: GlobalConfig.bar.status.showKbLayout = checked
        }

        ToggleRow {
            text: Tr.t("Network")
            checked: Config.bar.status.showNetwork
            onToggled: GlobalConfig.bar.status.showNetwork = checked
        }

        ToggleRow {
            text: Tr.t("Wi-Fi")
            checked: Config.bar.status.showWifi
            onToggled: GlobalConfig.bar.status.showWifi = checked
        }

        ToggleRow {
            text: Tr.t("Bluetooth")
            checked: Config.bar.status.showBluetooth
            onToggled: GlobalConfig.bar.status.showBluetooth = checked
        }

        ToggleRow {
            text: Tr.t("Battery")
            checked: Config.bar.status.showBattery
            onToggled: GlobalConfig.bar.status.showBattery = checked
        }

        ToggleRow {
            last: true
            text: Tr.t("Caps lock")
            checked: Config.bar.status.showLockStatus
            onToggled: GlobalConfig.bar.status.showLockStatus = checked
        }

        // Behaviour
        SectionHeader {
            text: Tr.t("Behaviour")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.t("Popout on hover")
            subtext: Tr.t("Show a details popout when hovering the status icons")
            checked: Config.bar.popouts.statusIcons
            onToggled: GlobalConfig.bar.popouts.statusIcons = checked
        }
    }
}

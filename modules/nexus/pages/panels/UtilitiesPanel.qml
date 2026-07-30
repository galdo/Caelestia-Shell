pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common
import qs.services

PageBase {
    id: root

    function isToggleOn(id: string): bool {
        const item = Config.utilities.quickToggles.find(t => t.id === id);
        return item ? (item.enabled ?? true) : false;
    }

    function setToggleOn(id: string, on: bool): void {
        let found = false;
        const next = Config.utilities.quickToggles.map(item => {
            if (item.id !== id)
                return item;
            found = true;
            return Object.assign({}, item, {
                enabled: on
            });
        });
        if (!found)
            next.push({
                id,
                enabled: on
            });
        GlobalConfig.utilities.quickToggles = next;
    }

    title: Tr.t("Utilities")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.t("General")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.t("Enabled")
            subtext: Tr.t("Show the utilities panel")
            checked: Config.utilities.enabled
            onToggled: GlobalConfig.utilities.enabled = checked
        }

        // Cards
        SectionHeader {
            text: Tr.t("Cards")
        }

        ToggleRow {
            first: true
            text: Tr.t("Keep awake")
            subtext: Tr.t("Show the idle inhibitor card")
            checked: Config.utilities.cards.keepAwake
            onToggled: GlobalConfig.utilities.cards.keepAwake = checked
        }

        ToggleRow {
            text: Tr.t("Screen recorder")
            subtext: Tr.t("Show the screen recorder card")
            checked: Config.utilities.cards.recorder
            onToggled: GlobalConfig.utilities.cards.recorder = checked
        }

        ToggleRow {
            last: true
            text: Tr.t("Quick toggles")
            subtext: Tr.t("Show the quick toggles card")
            checked: Config.utilities.cards.quickToggles
            onToggled: GlobalConfig.utilities.cards.quickToggles = checked
        }

        // Quick toggles
        SectionHeader {
            text: Tr.t("Quick toggles")
        }

        ToggleRow {
            first: true
            text: Tr.t("Wi-Fi")
            subtext: Tr.t("Toggle wireless networking")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("wifi")
            onToggled: root.setToggleOn("wifi", checked)
        }

        ToggleRow {
            text: Tr.t("Bluetooth")
            subtext: Tr.t("Toggle the Bluetooth adapter")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("bluetooth")
            onToggled: root.setToggleOn("bluetooth", checked)
        }

        ToggleRow {
            text: Tr.t("Microphone")
            subtext: Tr.t("Mute or unmute the default source")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("mic")
            onToggled: root.setToggleOn("mic", checked)
        }

        ToggleRow {
            text: Tr.t("Settings")
            subtext: Tr.t("Open the settings window")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("settings")
            onToggled: root.setToggleOn("settings", checked)
        }

        ToggleRow {
            text: Tr.t("Game mode")
            subtext: Tr.t("Toggle game mode")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("gameMode")
            onToggled: root.setToggleOn("gameMode", checked)
        }

        ToggleRow {
            text: Tr.t("Do not disturb")
            subtext: Tr.t("Silence notifications")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("dnd")
            onToggled: root.setToggleOn("dnd", checked)
        }

        ToggleRow {
            last: true
            text: Tr.t("VPN")
            subtext: Tr.t("Connect or disconnect the VPN")
            disabled: !Config.utilities.cards.quickToggles
            checked: root.isToggleOn("vpn")
            onToggled: root.setToggleOn("vpn", checked)
        }
    }
}

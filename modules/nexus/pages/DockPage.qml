pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.t("Dock")

    // Positions-Optionen (unten / oben). objectName als stabiler Schluessel
    // (dynamische Custom-Properties gehen beim MenuItem-Signal verloren).
    readonly property list<MenuItem> positionItems: [
        MenuItem {
            objectName: "bottom"
            text: Tr.t("Bottom")
        },
        MenuItem {
            objectName: "top"
            text: Tr.t("Top")
        }
    ]

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Alle Apps, die noch nicht angeheftet sind (fuer den Hinzufuegen-Dropdown).
        // Variants ist kein visuelles Item -> landet in 'data', nicht im Layout.
        Variants {
            id: appVariants

            model: {
                const pinned = GlobalConfig.dock.pinned ?? [];
                return [...DesktopEntries.applications.values]
                    .filter(a => !pinned.includes(a.id))
                    .sort((a, b) => a.name.localeCompare(b.name));
            }

            MenuItem {
                required property var modelData
                readonly property string appId: modelData.id
                text: modelData.name
            }
        }

        // Allgemein
        SectionHeader {
            first: true
            text: Tr.t("General")
        }

        ToggleRow {
            first: true
            text: Tr.t("Enable dock")
            checked: GlobalConfig.dock.enabled
            onToggled: GlobalConfig.dock.enabled = checked
        }

        ToggleRow {
            text: Tr.t("Show running apps")
            subtext: Tr.t("Also show running apps that are not pinned")
            checked: GlobalConfig.dock.showRunning
            onToggled: GlobalConfig.dock.showRunning = checked
        }

        SelectRow {
            last: true
            label: Tr.t("Position")
            subtext: Tr.t("Where the dock attaches to the bar")
            menuItems: root.positionItems
            active: root.positionItems.find(i => i.objectName === GlobalConfig.dock.position) ?? root.positionItems[0]
            onSelected: item => GlobalConfig.dock.position = item.objectName
        }

        // Angeheftete Apps
        SectionHeader {
            text: Tr.t("Pinned apps")
        }

        // Hinzufuegen
        SelectRow {
            first: true
            label: Tr.t("Add app")
            fallbackText: Tr.t("Select an app to pin")
            fallbackIcon: "add"
            menuItems: appVariants.instances
            active: null
            onSelected: item => {
                const pinned = GlobalConfig.dock.pinned ?? [];
                if (!pinned.includes(item.appId))
                    GlobalConfig.dock.pinned = [...pinned, item.appId];
            }
        }

        // Liste der angehefteten Apps mit Entfernen-Button
        Repeater {
            model: GlobalConfig.dock.pinned ?? []

            ConnectedRect {
                id: pinnedRow

                required property string modelData
                required property int index

                readonly property var entry: DesktopEntries.heuristicLookup(modelData)

                Layout.fillWidth: true
                last: pinnedRow.index === (GlobalConfig.dock.pinned.length - 1)
                implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

                RowLayout {
                    id: rowLayout

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.medium
                    spacing: Tokens.spacing.medium

                    IconImage {
                        asynchronous: true
                        source: Quickshell.iconPath(pinnedRow.entry?.icon, "image-missing")
                        implicitSize: Tokens.font.body.large.pixelSize * 1.4
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: pinnedRow.entry?.name ?? pinnedRow.modelData
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    IconButton {
                        icon: "close"
                        onClicked: {
                            const pinned = GlobalConfig.dock.pinned ?? [];
                            GlobalConfig.dock.pinned = pinned.filter(a => a !== pinnedRow.modelData);
                        }
                    }
                }
            }
        }

        // Hinweis bei leerer Liste
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.medium
            visible: (GlobalConfig.dock.pinned ?? []).length === 0
            horizontalAlignment: Text.AlignHCenter
            text: Tr.t("No pinned apps yet")
            color: Colours.palette.m3outlineVariant
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Cheatsheet-Overlay: zentrierte Uebersicht der wichtigsten Shortcuts (kuratiert).
// Sichtbar an screenState.cheatsheet gebunden.
// Schliesst auf Esc oder Klick ausserhalb der Karte.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.cheatsheet
    property real animScale: shouldBeActive ? 1 : 0.9
    property real animOpacity: shouldBeActive ? 1 : 0

    anchors.fill: parent
    visible: animOpacity > 0

    // Fokus aktiv holen, sobald das Overlay oeffnet (deklaratives focus: greift nicht
    // zuverlaessig, wenn das Item schon existiert) -> Tastatur (Pfeile/PageUp/Down/Esc).
    onShouldBeActiveChanged: {
        if (shouldBeActive)
            shortcutList.forceActiveFocus();
    }

    Behavior on animScale {
        Anim {}
    }
    Behavior on animOpacity {
        Anim {}
    }

    // Abdunkelnder Hintergrund; Klick schliesst
    MouseArea {
        anchors.fill: parent
        onClicked: root.screenState.cheatsheet = false
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: root.animOpacity * 0.4
    }

    // Esc schliesst (Fokus liegt auf der ListView, siehe unten)

    StyledRect {
        id: card

        anchors.centerIn: parent
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        opacity: root.animOpacity
        scale: root.animScale

        implicitWidth: Math.min(root.width * 0.6, 720)
        implicitHeight: Math.min(root.height * 0.75, 640)

        // Klicks auf der Karte nicht an den schliessenden Hintergrund durchreichen.
        // WICHTIG: nur Maustasten abfangen, KEINE Wheel-Events schlucken -> sonst
        // erreicht das Mausrad die ListView darunter nicht (Scroll tot).
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onWheel: wheel => wheel.accepted = false
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "help"
                    color: Colours.palette.m3primary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Tr.t("Keyboard shortcuts")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }
            }

            ListView {
                id: shortcutList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: Keybinds.groups
                spacing: Tokens.spacing.medium

                // Fokus auf die Liste, sobald das Overlay offen ist -> Mausrad + Tastatur
                // (Pfeile/PageUp/Down) scrollen; Esc schliesst. Ohne Fokus reagiert der
                // Scrollbalken nicht (Fenster-keyboardFocus wird in ContentWindow gesetzt).
                focus: root.shouldBeActive
                Keys.onEscapePressed: root.screenState.cheatsheet = false

                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                ScrollBar.vertical: ScrollBar {
                    policy: shortcutList.contentHeight > shortcutList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                }

                delegate: ColumnLayout {
                    required property var modelData
                    width: ListView.view.width
                    spacing: Tokens.spacing.small / 2

                    // Gruppentitel
                    StyledText {
                        text: modelData.title
                        font: Tokens.font.body.large
                        color: Colours.palette.m3primary
                    }

                    // Eintraege der Gruppe
                    Repeater {
                        model: modelData.items

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.medium

                            StyledRect {
                                radius: Tokens.rounding.small
                                color: Colours.palette.m3surfaceContainerHighest
                                implicitWidth: keyText.implicitWidth + Tokens.padding.small * 2
                                implicitHeight: keyText.implicitHeight + Tokens.padding.small

                                StyledText {
                                    id: keyText
                                    anchors.centerIn: parent
                                    text: modelData.key
                                    color: Colours.palette.m3onSurface
                                    font: Tokens.font.mono.small
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: modelData.action
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}

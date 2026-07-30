pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher as Launcher
import qs.modules.launcher.services

// App-Grid-Overlay: zentrierte Karte mit Suchfeld oben und einem Raster aller
// installierten Apps. Aufruf ueber das Logo-Icon oben links oder den appgrid-Shortcut.
// Schliesst auf Esc oder Klick ausserhalb der Karte.
Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.appgrid
    property real animScale: shouldBeActive ? 1 : 0.9
    property real animOpacity: shouldBeActive ? 1 : 0

    anchors.fill: parent
    visible: animOpacity > 0

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            searchField.text = "";
            searchField.forceActiveFocus();
        }
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
        onClicked: root.screenState.appgrid = false
    }

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3scrim
        opacity: root.animOpacity * 0.4
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        radius: Tokens.rounding.large
        color: Colours.palette.m3surfaceContainer

        opacity: root.animOpacity
        scale: root.animScale

        implicitWidth: Math.min(root.width * 0.7, 900)
        implicitHeight: Math.min(root.height * 0.8, 680)

        // Klicks auf der Karte nicht an den schliessenden Hintergrund durchreichen
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            // Suchfeld oben (filtert das Raster nach Namen)
            TextField {
                id: searchField

                Layout.fillWidth: true
                placeholderText: Tr.t("Search apps")
                color: Colours.palette.m3onSurface
                placeholderTextColor: Colours.palette.m3outline
                font: Tokens.font.body.large
                background: StyledRect {
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest
                }
                leftPadding: Tokens.padding.large
                rightPadding: Tokens.padding.large
                topPadding: Tokens.padding.medium
                bottomPadding: Tokens.padding.medium

                Keys.onEscapePressed: root.screenState.appgrid = false
                Keys.onDownPressed: appGrid.currentIndex = Math.min(appGrid.count - 1, appGrid.currentIndex + 1)
                Keys.onUpPressed: appGrid.currentIndex = Math.max(0, appGrid.currentIndex - 1)
                Keys.onRightPressed: appGrid.currentIndex = Math.min(appGrid.count - 1, appGrid.currentIndex + 1)
                Keys.onLeftPressed: appGrid.currentIndex = Math.max(0, appGrid.currentIndex - 1)
                onAccepted: {
                    const item = appGrid.currentItem;
                    if (item?.modelData) {
                        Apps.launch(item.modelData);
                        root.screenState.appgrid = false;
                    }
                }
            }

            Launcher.AppGrid {
                id: appGrid

                Layout.fillWidth: true
                Layout.fillHeight: true
                screenState: root.screenState
                filterText: searchField.text
            }
        }
    }
}

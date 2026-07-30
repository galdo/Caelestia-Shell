import QtQuick
import Caelestia.Config
import qs.components
import qs.services

// Bar-Button: oeffnet das Keyboard-Shortcuts-Cheatsheet.
Item {
    id: root

    required property ScreenState screenState

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        onClicked: root.screenState.cheatsheet = !root.screenState.cheatsheet
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: "help"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.builders.small.build()
    }
}

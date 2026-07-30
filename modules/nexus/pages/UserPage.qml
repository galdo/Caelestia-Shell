pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.components.images
import qs.services
import qs.modules.nexus.common

// Benutzer-Einstellungen: Anzeigename (persistiert in ~/.config/caelestia/user.json)
// und Avatar-Bild (File-Picker -> kopiert nach ~/.face, wie im Dashboard).
PageBase {
    id: root

    title: Tr.t("User")

    // Anzeigename: default = $USER, editierbar, persistiert als JSON.
    property string displayName: Quickshell.env("USER") ?? ""

    // Persistenz des Anzeigenamens.
    // WICHTIG: FileView/FileDialog sind KEINE visuellen Items -> nicht als direktes
    // Kind von PageBase (dessen default property Items erwartet), sonst
    // "Cannot assign object of type FileView to property of type QQuickItem*".
    // Als benannte Property deklarieren.
    readonly property FileView userFile: FileView {
        path: `${Paths.home}/.config/caelestia/user.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.displayName)
                    root.displayName = data.displayName;
            } catch (e) {}
        }
    }

    function saveName(name: string): void {
        root.displayName = name;
        root.userFile.setText(JSON.stringify({
            displayName: name
        }, null, 2));
    }

    // Avatar-Auswahl (kopiert nach ~/.face)
    readonly property FileDialog facePicker: FileDialog {
        title: Tr.t("Select an avatar image")
        filterLabel: Tr.t("Images")
        filters: ["png", "jpg", "jpeg", "webp"]
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                pfp.path = "";  // Cache-Bust
            pfp.path = `${Paths.home}/.face`;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Avatar
        SectionHeader {
            first: true
            text: Tr.t("Avatar")
        }

        ConnectedRect {
            first: true
            last: true
            Layout.fillWidth: true
            implicitHeight: avatarRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: avatarRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                // Rundes Avatar-Vorschaubild
                StyledRect {
                    implicitWidth: Tokens.font.body.large.pixelSize * 3
                    implicitHeight: implicitWidth
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3surfaceContainerHighest
                    clip: true

                    MaterialIcon {
                        anchors.centerIn: parent
                        visible: pfp.status !== Image.Ready
                        text: "person"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.large
                    }

                    CachingImage {
                        id: pfp

                        anchors.fill: parent
                        path: `${Paths.home}/.face`
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Tr.t("Choose an image for your profile")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                StyledRect {
                    implicitWidth: chooseLabel.implicitWidth + Tokens.padding.large * 2
                    implicitHeight: chooseLabel.implicitHeight + Tokens.padding.medium
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    StateLayer {
                        radius: parent.radius
                        onClicked: root.facePicker.open()
                    }

                    StyledText {
                        id: chooseLabel

                        anchors.centerIn: parent
                        text: Tr.t("Choose…")
                        color: Colours.palette.m3onPrimary
                        font: Tokens.font.body.medium
                    }
                }
            }
        }

        // Name
        SectionHeader {
            text: Tr.t("Display name")
        }

        StyledTextField {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.extraSmall
            text: root.displayName
            placeholderText: Tr.t("Your name")
            leadingIcon: "badge"
            onAccepted: root.saveName(text)
            onEditingFinished: root.saveName(text)
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.small
            text: Tr.t("Shown on the lock screen and dashboard.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.Wrap
        }
    }
}

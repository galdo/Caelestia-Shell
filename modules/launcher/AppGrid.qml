pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.launcher.services

// Vergroesserte Uebersicht ALLER installierten Apps als Icon-Raster mit Beschriftung
// unter jedem Icon. Aktiviert ueber den "?"-Prefix im Launcher (analog zu Wallpapers).
// Bietet currentIndex/currentItem/incrementCurrentIndex/decrementCurrentIndex (GridView
// nativ) -> Enter/Pfeile im Content.qml funktionieren wie bei den anderen Listen.
GridView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    // Alle sichtbaren Apps (versteckte via hiddenApps rausgefiltert), alphabetisch.
    // Wenn nach dem "?" noch Text steht, danach filtern (Name-Substring).
    readonly property string filterText: {
        const t = search.text ?? "";
        const p = "?";
        return t.startsWith(p) ? t.slice(p.length).trim().toLowerCase() : "";
    }
    readonly property var allApps: {
        const list = DesktopEntries.applications?.values ?? [];
        const visible = list.filter(a => a && !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id));
        const filtered = root.filterText.length === 0 ? visible : visible.filter(a => (a.name ?? "").toLowerCase().includes(root.filterText));
        return filtered.slice().sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));
    }

    // Rasterdimensionen
    readonly property int cell: 108
    readonly property int iconSize: 52

    cellWidth: cell
    cellHeight: cell
    clip: true

    model: ScriptModel {
        values: root.allApps
        onValuesChanged: root.currentIndex = 0
    }

    // Markierung des aktiven Items
    highlightFollowsCurrentItem: true
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    delegate: Item {
        id: appCell

        required property DesktopEntry modelData
        required property int index

        width: root.cellWidth
        height: root.cellHeight

        StateLayer {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small / 2
            radius: Tokens.rounding.large
            onClicked: {
                root.currentIndex = appCell.index;
                Apps.launch(appCell.modelData);
                root.screenState.launcher = false;
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Tokens.spacing.small / 2
            width: parent.width - Tokens.padding.small * 2

            IconImage {
                anchors.horizontalCenter: parent.horizontalCenter
                asynchronous: true
                source: Quickshell.iconPath(appCell.modelData?.icon, "image-missing")
                implicitSize: root.iconSize
            }

            StyledText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: appCell.modelData?.name ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurface
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
        }
    }
}

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

// Icon-Raster ALLER installierten Apps mit Beschriftung unter jedem Icon.
// Wird vom AppGridPanel verwendet. Bietet GridView-Navigation (Pfeile/Enter).
GridView {
    id: root

    required property ScreenState screenState
    property string filterText: ""

    // Alle sichtbaren Apps (versteckte via hiddenApps raus), nach Name gefiltert, alphabetisch.
    readonly property var allApps: {
        const list = DesktopEntries.applications?.values ?? [];
        const visible = list.filter(a => a && !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id));
        const f = (root.filterText ?? "").trim().toLowerCase();
        const filtered = f.length === 0 ? visible : visible.filter(a => (a.name ?? "").toLowerCase().includes(f));
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
                root.screenState.appgrid = false;
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

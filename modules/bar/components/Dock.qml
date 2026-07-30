pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

// Dock: angeheftete + laufende Apps als vertikale Icon-Spalte in der (linken) Bar.
// Der HINTERGRUND wird NICHT hier gezeichnet, sondern als BlobRect in ContentWindow.qml,
// damit er mit dem linken Bar-Schenkel zu einer durchgehenden L-Flaeche verschmilzt.
// Hier nur die Icons (transparentes Item).
Item {
    id: root

    property color colour: Colours.palette.m3onSurface

    // Anzahl der Icons — von der Blob-Flaeche (ContentWindow) zur Hoehen-Synchronisation genutzt.
    readonly property int itemCount: root.allEntries.length

    // Angeheftete App-IDs -> DesktopEntry (heuristisch aufgeloest, null gefiltert)
    readonly property var pinnedEntries: {
        try {
            return (GlobalConfig.dock.pinned ?? []).map(id => DesktopEntries.heuristicLookup(id)).filter(e => e);
        } catch (e) {
            console.warn("Dock pinnedEntries error:", e);
            return [];
        }
    }

    // Laufende Fenster-Klassen (unique), die NICHT bereits angeheftet sind
    readonly property var pinnedClasses: root.pinnedEntries.map(e => (e.id ?? "").toLowerCase())
    readonly property var runningEntries: {
        if (!GlobalConfig.dock.showRunning)
            return [];
        const out = [];
        try {
            const seen = {};
            const tls = Hypr.toplevels?.values ?? [];
            for (const t of tls) {
                const cls = (t?.lastIpcObject?.class ?? "").toString().toLowerCase();
                if (!cls || seen[cls])
                    continue;
                seen[cls] = true;
                if (root.pinnedClasses.includes(cls))
                    continue;
                const entry = DesktopEntries.heuristicLookup(cls);
                if (entry)
                    out.push(entry);
            }
        } catch (e) {
            console.warn("Dock runningEntries error:", e);
        }
        return out;
    }

    readonly property var allEntries: root.pinnedEntries.concat(root.runningEntries)

    visible: GlobalConfig.dock.enabled && root.allEntries.length > 0

    implicitWidth: Tokens.sizes.bar.innerWidth
    implicitHeight: iconColumn.implicitHeight + Tokens.padding.medium * 2

    // Ist eine App (per class) gerade offen?
    function isRunning(entryId) {
        try {
            const cls = (entryId ?? "").toString().toLowerCase();
            return (Hypr.toplevels?.values ?? []).some(t => (t?.lastIpcObject?.class ?? "").toString().toLowerCase() === cls);
        } catch (e) {
            return false;
        }
    }

    // Klick: laufendes Fenster fokussieren, sonst App starten.
    function activate(entry) {
        if (!entry)
            return;
        try {
            const cls = (entry.id ?? "").toString().toLowerCase();
            const t = (Hypr.toplevels?.values ?? []).find(w => (w?.lastIpcObject?.class ?? "").toString().toLowerCase() === cls);
            if (t) {
                const addr = t.address ?? t.lastIpcObject?.address;
                if (addr)
                    Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ address = "0x${addr}" })` : `focuswindow address:0x${addr}`);
            } else {
                Apps.launch(entry);
            }
        } catch (e) {
            console.warn("Dock activate error:", e);
        }
    }

    ColumnLayout {
        id: iconColumn

        anchors.centerIn: parent
        width: parent.width

        spacing: Tokens.spacing.medium / 2

        Repeater {
            model: root.allEntries

            Item {
                id: appItem

                required property var modelData

                readonly property bool running: root.isRunning(modelData.id)

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Tokens.sizes.bar.innerWidth
                implicitHeight: implicitWidth

                StateLayer {
                    anchors.fill: parent
                    radius: Tokens.rounding.full
                    onClicked: root.activate(appItem.modelData)
                }

                IconImage {
                    anchors.centerIn: parent
                    asynchronous: true
                    source: Quickshell.iconPath(appItem.modelData?.icon, "image-missing")
                    implicitSize: parent.implicitWidth * 0.7
                }

                // Kleiner Indikator fuer laufende Apps
                StyledRect {
                    visible: appItem.running
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: Tokens.padding.small / 2
                    implicitHeight: parent.implicitHeight * 0.4
                    radius: Tokens.rounding.full
                    color: root.colour
                }
            }
        }
    }
}

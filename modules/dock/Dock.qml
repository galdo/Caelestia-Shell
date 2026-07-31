pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.utils
import qs.modules.launcher.services

// Horizontales Auto-Hide-Dock am unteren Bildschirmrand (eigenes Fenster pro Screen).
// Sichtbar, wenn kein Fenster den unteren Bereich verdeckt; sonst versteckt und
// erscheint bei Maus am unteren Rand (ueber den Fenstern, Overlay-Layer).
Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).dock.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData

        readonly property HyprlandMonitor monitor: Hypr.monitorFor(modelData)

        // Fullscreen-Fenster (inkl. Special-WS) -> Dock ganz weg
        readonly property bool hasFullscreen: {
            const ws = monitor?.activeWorkspace;
            return ws?.toplevels?.values?.some(t => (t.lastIpcObject?.fullscreen ?? 0) > 1) ?? false;
        }

        // Verdeckt ein (gekacheltes) Fenster die untere Dock-Zone?
        // Feste Zahlenwerte statt Tokens.* — Tokens braucht Screen-Kontext, der auf
        // Fenster-Ebene (win) nicht gilt (nur in Kind-Items unter contentItem).
        readonly property int dockZone: dockPill.implicitHeight + 24
        readonly property bool occluded: {
            const tls = monitor?.activeWorkspace?.toplevels?.values ?? [];
            const monY = monitor?.lastIpcObject?.at?.[1] ?? 0;
            return tls.some(t => {
                const io = t.lastIpcObject;
                if (!io || io.floating)
                    return false;
                const wy = (io.at?.[1] ?? 0) - monY;
                const wh = io.size?.[1] ?? 0;
                return wy + wh > modelData.height - dockZone;
            });
        }

        readonly property bool revealed: revealHover.hovered || !occluded

        screen: modelData
        name: "dock"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: revealed ? WlrLayer.Overlay : WlrLayer.Top
        color: "transparent"
        surfaceFormat.opaque: false

        visible: GlobalConfig.dock.enabled && !hasFullscreen && dockPill.hasItems

        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        // Fenster hoeher als die Pille, damit die weggeschobene Pille nicht clippt.
        implicitHeight: dockPill.implicitHeight + slideRoom
        readonly property int slideRoom: dockPill.implicitHeight + 24  // fester Wert (kein Tokens auf win-Ebene)

        // Klickbar nur: die Pille + ein duenner Reveal-Streifen darunter (statisch,
        // keine Umschaltung -> kein Binding-Loop). Rest klick-transparent -> Bar erreichbar.
        mask: Region {
            Region {
                item: dockPill
            }
            Region {
                x: (win.width - win.revealWidth) / 2
                y: win.height - win.revealZone
                width: win.revealWidth
                height: win.revealZone
            }
        }
        readonly property int revealZone: 6   // fester Wert (kein Tokens auf win-Ebene)
        readonly property int revealWidth: Math.max(dockPill.implicitWidth, 200)

        // Slide + Fade
        property real offsetScale: revealed ? 0 : 1
        Behavior on offsetScale {
            Anim {}
        }

        // Duenne Hover-Zone am unteren Rand + Pille selbst triggern das Reveal
        HoverHandler {
            id: revealHover
        }

        StyledRect {
            id: dockPill

            readonly property color colour: Colours.palette.m3onSurface

            // --- Icon-Datenquelle (uebernommen aus dem vertikalen Dock) ---
            readonly property var pinnedEntries: {
                const _dep = DesktopEntries.applications?.values?.length ?? 0;
                try {
                    return (GlobalConfig.dock.pinned ?? []).map(id => DesktopEntries.heuristicLookup(id)).filter(e => e);
                } catch (e) {
                    return [];
                }
            }
            readonly property var pinnedClasses: pinnedEntries.map(e => (e.id ?? "").toLowerCase())
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
                        if (pinnedClasses.includes(cls))
                            continue;
                        const entry = DesktopEntries.heuristicLookup(cls);
                        if (entry)
                            out.push(entry);
                    }
                } catch (e) {}
                return out;
            }
            readonly property var allEntries: pinnedEntries.concat(runningEntries)
            readonly property bool hasItems: allEntries.length > 0

            function isRunning(entryId) {
                try {
                    const cls = (entryId ?? "").toString().toLowerCase();
                    return (Hypr.toplevels?.values ?? []).some(t => (t?.lastIpcObject?.class ?? "").toString().toLowerCase() === cls);
                } catch (e) {
                    return false;
                }
            }
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
                } catch (e) {}
            }

            function isPinnedId(id) {
                return (GlobalConfig.dock.pinned ?? []).includes(id);
            }
            function pinId(id) {
                if (!id)
                    return;
                const pinned = (GlobalConfig.dock.pinned ?? []).slice();
                if (!pinned.includes(id)) {
                    pinned.push(id);
                    GlobalConfig.dock.pinned = pinned;
                }
            }
            function unpinId(id) {
                if (!id)
                    return;
                GlobalConfig.dock.pinned = (GlobalConfig.dock.pinned ?? []).filter(a => a !== id);
            }
            // Rechtsklick-Toggle: pinnt bzw. loest per ID
            function togglePin(id) {
                if (isPinnedId(id))
                    unpinId(id);
                else
                    pinId(id);
            }

            // Panel-Look: klebt buendig an der Unterkante (kein Abstand), Slide faehrt
            // es nach unten aus dem Rand. Obere Ecken gerundet, untere kantig (am Rand).
            // Slide-Distanz wie echte Panels: implicitHeight + 5px Puffer, damit die Pille
            // beim Overshoot-Easing (DefaultSpatial) komplett hinter dem Rand verschwindet
            // und beim Reinkommen sichtbar "wobbelt" (identisch zu Session/Sidebar).
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (-implicitHeight - 5) * win.offsetScale
            opacity: 1 - win.offsetScale

            color: Colours.tPalette.m3surface
            radius: Tokens.rounding.large
            bottomLeftRadius: 0
            bottomRightRadius: 0

            implicitWidth: iconRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: iconRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: iconRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                Repeater {
                    model: dockPill.allEntries

                    Item {
                        id: appItem

                        required property var modelData

                        readonly property bool running: dockPill.isRunning(modelData.id)
                        readonly property bool pinned: dockPill.isPinnedId(modelData?.id)

                        Layout.alignment: Qt.AlignVCenter
                        // Icon-Groesse aus der Config (1:1). Dock waechst mit (implicitHeight
                        // der Pille leitet sich aus iconRow ab) -> Icons nie abgeschnitten.
                        implicitWidth: GlobalConfig.dock.iconSize
                        implicitHeight: GlobalConfig.dock.iconSize

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.full
                            onClicked: dockPill.activate(appItem.modelData)
                        }

                        // Rechtsklick: Pin/Unpin-Kontextmenue
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: dockPill.togglePin(appItem.modelData?.id)
                        }

                        IconImage {
                            anchors.centerIn: parent
                            asynchronous: true
                            source: Quickshell.iconPath(appItem.modelData?.icon, "image-missing")
                            implicitSize: Math.round(GlobalConfig.dock.iconSize * 0.8)
                        }

                        // Indikator fuer laufende Apps (unten)
                        StyledRect {
                            visible: appItem.running
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitWidth: parent.implicitWidth * 0.4
                            implicitHeight: Tokens.padding.small / 2
                            radius: Tokens.rounding.full
                            color: dockPill.colour
                        }
                    }
                }
            }
        }
    }
}

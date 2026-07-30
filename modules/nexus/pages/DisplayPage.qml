pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

// Bildschirm-Einstellungen: Aufloesung + Anordnung pro Monitor.
// Setzt Werte zur Laufzeit (hyprctl/hl.monitor) UND schreibt sie persistent in
// ~/.config/caelestia/hypr-user.lua, damit sie den Neustart ueberleben.
PageBase {
    id: root

    title: Tr.t("Display")

    // Live-Monitorliste aus Quickshell.Hyprland (via Hypr-Service).
    readonly property var monitors: Hypr.monitors?.values ?? []

    // Zerlegt einen availableModes-Eintrag "1920x1080@60.00Hz" in { res, hz, label }.
    function parseMode(modeStr: string): var {
        const m = String(modeStr).match(/^(\d+x\d+)@([\d.]+)Hz$/);
        if (!m)
            return null;
        const hz = parseFloat(m[2]);
        return {
            key: modeStr,
            res: m[1],
            hz: hz,
            // Anzeige: "1920x1080 @ 60 Hz" (ganze Zahl wenn moeglich)
            label: `${m[1]} @ ${Math.round(hz * 100) / 100} Hz`
        };
    }

    // Aktueller Modus eines Monitors als "WxH@R.RRRHz" (fuer hl.monitor mode = ...).
    function currentMode(mon: var): string {
        const io = mon?.lastIpcObject ?? {};
        const w = io.width ?? mon?.width ?? 0;
        const h = io.height ?? mon?.height ?? 0;
        const hz = io.refreshRate ?? 0;
        return `${w}x${h}@${hz.toFixed(5)}Hz`;
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Ein Abschnitt pro Monitor.
        Repeater {
            model: root.monitors

            ColumnLayout {
                id: monSection

                required property var modelData
                required property int index

                readonly property var mon: modelData
                readonly property var io: mon?.lastIpcObject ?? ({})
                readonly property string monName: mon?.name ?? (io.name ?? "?")

                // Verfuegbare Modi (aus lastIpcObject.availableModes; QML-API hat kein
                // dediziertes availableModes-Property -> raw ipc object nutzen).
                readonly property var modes: {
                    const raw = io.availableModes ?? [];
                    const out = [];
                    for (const s of raw) {
                        const p = root.parseMode(s);
                        if (p)
                            out.push(p);
                    }
                    // Falls Hyprland (noch) keine Modi liefert, wenigstens den
                    // aktuellen Modus als Auswahl anbieten.
                    if (out.length === 0) {
                        const cur = root.parseMode(root.currentMode(mon));
                        if (cur)
                            out.push(cur);
                    }
                    return out;
                }

                // Ausgewaehlter Modus (Default: aktueller Modus des Monitors).
                property string selectedMode: root.currentMode(mon)
                // Ausgewaehlte Skalierung.
                property real selectedScale: io.scale ?? mon?.scale ?? 1
                // Anordnung: Bezugsmonitor + Richtung (nur Multi-Monitor).
                // Werden von den arrange-SelectRows unten gesetzt, damit
                // applyMonitor() sie am Section-Objekt lesen kann.
                property string refMonitorName: ""
                property string placementDir: "right"

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: monSection.index === 0
                    text: monSection.monName
                }

                // Aktueller Zustand (Info).
                InfoRow {
                    icon: "monitor"
                    label: Tr.t("Current mode")
                    value: {
                        const io = monSection.io;
                        const w = io.width ?? monSection.mon?.width ?? 0;
                        const h = io.height ?? monSection.mon?.height ?? 0;
                        const hz = io.refreshRate ?? 0;
                        return `${w}x${h} @ ${Math.round(hz * 100) / 100} Hz`;
                    }
                }

                InfoRow {
                    icon: "aspect_ratio"
                    label: Tr.t("Position")
                    value: {
                        const io = monSection.io;
                        const x = io.x ?? monSection.mon?.x ?? 0;
                        const y = io.y ?? monSection.mon?.y ?? 0;
                        return `${x}, ${y}`;
                    }
                }

                // Aufloesung waehlen (Dropdown).
                SelectRow {
                    id: modeSelect

                    // MenuItems dynamisch aus den verfuegbaren Modi. objectName traegt
                    // den stabilen Schluessel "WxH@R.RRRHz" (Custom-Props gehen im
                    // MenuItem-Signal verloren).
                    readonly property list<MenuItem> modeItems: {
                        const items = [];
                        for (const mode of monSection.modes) {
                            const it = modeItemComp.createObject(modeSelect, {
                                objectName: mode.key,
                                text: mode.label
                            });
                            if (it)
                                items.push(it);
                        }
                        return items;
                    }

                    label: Tr.t("Resolution")
                    subtext: Tr.t("Refresh rate is chosen with the mode")
                    menuItems: modeItems
                    active: modeItems.find(i => i.objectName === monSection.selectedMode) ?? modeItems[0] ?? null
                    onSelected: item => monSection.selectedMode = item.objectName
                }

                // Skalierung.
                StepperRow {
                    label: Tr.t("Scale")
                    subtext: Tr.t("Display scaling factor (percent)")
                    from: 50
                    to: 300
                    stepSize: 25
                    value: Math.round(monSection.selectedScale * 100)
                    onMoved: value => monSection.selectedScale = value / 100
                }

                // Anordnung: nur bei mehreren Monitoren sinnvoll.
                // Bezugsmonitor + relative Lage. Ergebnis wird beim Anwenden in eine
                // Positionsangabe fuer hl.monitor uebersetzt.
                SelectRow {
                    id: arrangeRef

                    visible: root.monitors.length > 1

                    readonly property list<MenuItem> refItems: {
                        const items = [];
                        for (const other of root.monitors) {
                            const oname = other?.name ?? "?";
                            if (oname === monSection.monName)
                                continue;
                            const it = refItemComp.createObject(arrangeRef, {
                                objectName: oname,
                                text: oname
                            });
                            if (it)
                                items.push(it);
                        }
                        return items;
                    }

                    property string refMonitor: refItems[0]?.objectName ?? ""

                    // Default fuer die Section setzen, sobald bekannt.
                    onRefMonitorChanged: monSection.refMonitorName = refMonitor
                    Component.onCompleted: monSection.refMonitorName = refMonitor

                    label: Tr.t("Relative to")
                    subtext: Tr.t("Reference monitor for arrangement")
                    menuItems: refItems
                    active: refItems.find(i => i.objectName === refMonitor) ?? refItems[0] ?? null
                    onSelected: item => {
                        refMonitor = item.objectName;
                        monSection.refMonitorName = item.objectName;
                    }
                }

                SelectRow {
                    id: arrangeDir

                    visible: root.monitors.length > 1

                    readonly property list<MenuItem> dirItems: [
                        rightOfItem,
                        leftOfItem,
                        aboveItem,
                        belowItem
                    ]

                    property string direction: "right"

                    onDirectionChanged: monSection.placementDir = direction

                    label: Tr.t("Placement")
                    subtext: Tr.t("Where this monitor sits")
                    menuItems: dirItems
                    active: dirItems.find(i => i.objectName === direction) ?? dirItems[0]
                    onSelected: item => {
                        direction = item.objectName;
                        monSection.placementDir = item.objectName;
                    }

                    MenuItem {
                        id: rightOfItem
                        objectName: "right"
                        text: Tr.t("Right of reference")
                    }
                    MenuItem {
                        id: leftOfItem
                        objectName: "left"
                        text: Tr.t("Left of reference")
                    }
                    MenuItem {
                        id: aboveItem
                        objectName: "above"
                        text: Tr.t("Above reference")
                    }
                    MenuItem {
                        id: belowItem
                        objectName: "below"
                        text: Tr.t("Below reference")
                    }
                }

                // Anwenden-Button.
                Item {
                    Layout.fillWidth: true
                    implicitHeight: applyBtn.implicitHeight + Tokens.padding.medium

                    IconTextButton {
                        id: applyBtn

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalPadding: Tokens.padding.extraLarge
                        verticalPadding: Tokens.padding.medium
                        icon: "check"
                        text: Tr.t("Apply")
                        onClicked: root.applyMonitor(monSection)
                    }
                }
            }
        }

        // Hinweis, wenn keine Monitore erkannt wurden.
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.medium
            visible: root.monitors.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: Tr.t("No monitors detected")
            color: Colours.palette.m3outlineVariant
        }
    }

    // MenuItem-Fabriken (dynamische Modi/Referenzen).
    Component {
        id: modeItemComp
        MenuItem {
            required property string objectName
            required property string text
        }
    }
    Component {
        id: refItemComp
        MenuItem {
            required property string objectName
            required property string text
        }
    }

    // Berechnet die Position (Pixel "XxY") aus Bezugsmonitor + Richtung.
    // Wendet Aufloesung/Position/Skalierung an: zur Laufzeit + persistent in die
    // hypr-user.lua.
    function applyMonitor(section: var): void {
        const name = section.monName;
        const mode = section.selectedMode; // "WxH@R.RRRHz"
        const scale = section.selectedScale;

        // Position bestimmen.
        let position;
        if (root.monitors.length > 1) {
            position = resolvePosition(section);
        } else {
            const io = section.io;
            position = `${io.x ?? section.mon?.x ?? 0}x${io.y ?? section.mon?.y ?? 0}`;
        }

        // 1) Laufzeit: hyprctl keyword-Dispatch (funktioniert in Lua- und
        // klassischer Config identisch).
        Hypr.dispatch(`keyword monitor ${name},${mode},${position},${scale}`);

        // 2) Persistenz: hl.monitor-Zeile in hypr-user.lua aktualisieren/schreiben.
        userConfig.writeMonitor(name, mode, position, scale);

        Toaster.toast(Tr.t("Display updated"), Tr.t("Applied %1 to %2").arg(mode).arg(name), "monitor");
    }

    // Uebersetzt Bezugsmonitor + Richtung in eine Pixel-Position fuer den
    // gerade angewendeten Monitor. Nutzt die aktuelle Geometrie des Bezugs.
    function resolvePosition(section: var): string {
        // arrangeRef / arrangeDir liegen als Kinder im Repeater-Delegate.
        // Wir lesen sie ueber die exponierten Properties am Section-Objekt.
        const refName = section.refMonitorName;
        const dir = section.placementDir;

        const refMon = root.monitors.find(m => (m?.name ?? "") === refName);
        if (!refMon) {
            const io = section.io;
            return `${io.x ?? 0}x${io.y ?? 0}`;
        }

        const rio = refMon.lastIpcObject ?? {};
        const rx = rio.x ?? refMon.x ?? 0;
        const ry = rio.y ?? refMon.y ?? 0;
        const rw = rio.width ?? refMon.width ?? 0;
        const rh = rio.height ?? refMon.height ?? 0;

        // Eigene Modus-Groesse (fuer left/above braucht man Breite/Hoehe).
        const ownW = parseInt(String(section.selectedMode).split("x")[0], 10) || 0;
        const ownH = parseInt(String(section.selectedMode).split("@")[0].split("x")[1], 10) || 0;

        switch (dir) {
        case "left":
            return `${rx - ownW}x${ry}`;
        case "above":
            return `${rx}x${ry - ownH}`;
        case "below":
            return `${rx}x${ry + rh}`;
        case "right":
        default:
            return `${rx + rw}x${ry}`;
        }
    }

    // FileView auf die User-Lua. Wir lesen den aktuellen Inhalt und ersetzen die
    // hl.monitor-Zeile fuer den betreffenden output (oder haengen sie an).
    // WICHTIG: FileView ist kein visuelles Item -> als Property deklarieren, nicht als
    // direktes Kind von PageBase (sonst "Cannot assign FileView to QQuickItem*").
    readonly property FileView userConfig: FileView {
        id: userConfig

        property string content: ""

        printErrors: false
        path: `${Paths.config}/hypr-user.lua`
        onLoaded: content = text()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                content = "";
        }

        // Schreibt/aktualisiert hl.monitor fuer 'output'.
        function writeMonitor(output: string, mode: string, position: string, scale: real): void {
            // Vor dem Schreiben sicherstellen, dass wir den aktuellen Inhalt haben.
            let text = content;

            const line = `hl.monitor({ output = "${output}", mode = "${mode}", position = "${position}", scale = ${scale} })`;

            // Regex: hl.monitor({ ... output = "<output>" ... }) auf einer Zeile.
            const escaped = output.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            const re = new RegExp(`hl\\.monitor\\(\\{[^}]*output\\s*=\\s*"${escaped}"[^}]*\\}\\)`, "m");

            if (re.test(text)) {
                text = text.replace(re, line);
            } else if (text.length === 0) {
                text = line + "\n";
            } else {
                text = text.replace(/\n*$/, "") + "\n" + line + "\n";
            }

            content = text;
            setText(text);
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

// Bildschirm-Einstellungen: Aufloesung + Skalierung des (primaeren) Monitors.
// Setzt Werte zur Laufzeit (hyprctl monitor) UND schreibt sie persistent in
// ~/.config/caelestia/hypr-user.lua (hl.monitor), damit sie den Neustart ueberleben.
//
// Auflösungsauswahl ueber Variants -> .instances (erprobtes Muster wie DockPage
// "Add app"; dynamisches createObject in SelectRow funktioniert NICHT zuverlaessig).
PageBase {
    id: root

    title: Tr.t("Display")

    // Primaerer Monitor (in der VM genau einer): der fokussierte, sonst der erste.
    readonly property var mon: {
        const list = Hypr.monitors?.values ?? [];
        return Hypr.focusedMonitor ?? list[0] ?? null;
    }
    readonly property var io: mon?.lastIpcObject ?? ({})
    readonly property string monName: mon?.name ?? (io.name ?? "")

    // Verfuegbare Modi als "WxH@R.RRRHz". Dedupliziert auf "WxH" (hoechste Hz je Aufloesung).
    // Zusaetzlich gaengige Standard-Aufloesungen ergaenzen, die der Monitor NICHT meldet
    // (virtio-gpu/VM akzeptiert oft beliebige Modi, z.B. 2560x1440) -> mit 60Hz-Fallback.
    readonly property var resList: {
        const raw = io.availableModes ?? [];
        const best = {};  // "WxH" -> {w,h,hz,res,mode}
        for (const s of raw) {
            const m = String(s).match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
            if (!m)
                continue;
            const w = parseInt(m[1], 10);
            const h = parseInt(m[2], 10);
            const hz = parseFloat(m[3]);
            const key = `${w}x${h}`;
            if (!best[key] || hz > best[key].hz)
                best[key] = { w, h, hz, res: key, mode: s };
        }
        // Gaengige Auflösungen ergaenzen, falls nicht gemeldet.
        const common = [[3840,2160],[2560,1440],[2560,1080],[1920,1200],[1920,1080],[1680,1050],[1600,900],[1440,900],[1366,768],[1280,720]];
        for (const [w, h] of common) {
            const key = `${w}x${h}`;
            if (!best[key])
                best[key] = { w, h, hz: 60, res: key, mode: `${w}x${h}@60Hz` };
        }
        // Aktuelle Auflösung sicher drin.
        const cw = io.width ?? mon?.width ?? 0;
        const ch = io.height ?? mon?.height ?? 0;
        if (cw > 0 && !best[`${cw}x${ch}`])
            best[`${cw}x${ch}`] = { w: cw, h: ch, hz: 60, res: `${cw}x${ch}`, mode: `${cw}x${ch}@60Hz` };
        return Object.values(best).sort((a, b) => (b.w * b.h) - (a.w * a.h));
    }

    // Aktuelle Auflösung als "WxH" (fuer active-Vorauswahl).
    readonly property string currentRes: {
        const w = io.width ?? mon?.width ?? 0;
        const h = io.height ?? mon?.height ?? 0;
        return `${w}x${h}`;
    }

    // Gewaehlte Werte (Default: aktuell).
    property string selectedRes: currentRes
    property real selectedScale: io.scale ?? mon?.scale ?? 1

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // MenuItems fuer die Auflösungs-SelectRow aus den Modi erzeugen.
        // Variants ist kein visuelles Item -> landet in 'data' (wie in DockPage).
        Variants {
            id: resVariants

            model: root.resList

            MenuItem {
                required property var modelData
                // objectName traegt den stabilen Schluessel "WxH".
                objectName: modelData.res
                text: `${modelData.res}  ·  ${Math.round(modelData.hz)} Hz`
            }
        }

        // Kein Monitor?
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.medium
            visible: !root.mon
            horizontalAlignment: Text.AlignHCenter
            text: Tr.t("No monitors detected")
            color: Colours.palette.m3outlineVariant
        }

        // Monitor-Infos
        SectionHeader {
            first: true
            text: root.monName
            visible: !!root.mon
        }

        InfoRow {
            visible: !!root.mon
            icon: "monitor"
            label: Tr.t("Current mode")
            value: {
                const w = root.io.width ?? 0;
                const h = root.io.height ?? 0;
                const hz = root.io.refreshRate ?? 0;
                return `${w}x${h} @ ${Math.round(hz)} Hz`;
            }
        }

        // Auflösung waehlen
        SelectRow {
            visible: !!root.mon
            label: Tr.t("Resolution")
            subtext: Tr.t("Refresh rate is chosen with the mode")
            menuItems: resVariants.instances
            active: resVariants.instances.find(i => i.objectName === root.selectedRes) ?? null
            onSelected: item => root.selectedRes = item.objectName
        }

        // Skalierung
        StepperRow {
            visible: !!root.mon
            label: Tr.t("Scale")
            subtext: Tr.t("Display scaling factor (percent)")
            from: 50
            to: 300
            stepSize: 25
            value: Math.round(root.selectedScale * 100)
            onMoved: value => root.selectedScale = value / 100
        }

        // Anwenden
        Item {
            visible: !!root.mon
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
                onClicked: root.applyMonitor()
            }
        }
    }

    // Aufloesung/Skalierung anwenden: Laufzeit (hyprctl) + persistent (hypr-user.lua).
    function applyMonitor(): void {
        const name = root.monName;
        if (!name)
            return;

        // Vollen Modus-String zur gewaehlten Auflösung finden (hoechste Hz).
        const entry = root.resList.find(e => e.res === root.selectedRes);
        const mode = entry?.mode ?? `${root.selectedRes}@60Hz`;
        // hyprctl erwartt "WxH@R" ohne "Hz"-Suffix.
        const hyprMode = mode.replace(/Hz$/, "");

        const io = root.io;
        const position = `${io.x ?? 0}x${io.y ?? 0}`;
        const scale = root.selectedScale;

        // 1) Laufzeit: hyprctl keyword als Prozess. Funktioniert unabhaengig von Lua-/
        //    klassischer Config (Hypr.dispatch("keyword ...") greift bei usingLua NICHT).
        applyProc.command = ["hyprctl", "keyword", "monitor", `${name},${hyprMode},${position},${scale}`];
        applyProc.running = true;

        // 2) Persistenz (hl.monitor nutzt weiter den vollen mode-String).
        userConfig.writeMonitor(name, mode, position, scale);

        Toaster.toast(Tr.t("Display updated"), Tr.t("Applied %1 to %2").arg(mode).arg(name), "monitor");
    }

    // Prozess fuer 'hyprctl keyword monitor ...' (Property, kein PageBase-Kind).
    readonly property Process applyProc: Process {}

    // hypr-user.lua lesen/schreiben (FileView ist kein visuelles Item -> Property!).
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

        function writeMonitor(output: string, mode: string, position: string, scale: real): void {
            let text = content;
            const line = `hl.monitor({ output = "${output}", mode = "${mode}", position = "${position}", scale = ${scale} })`;
            const escaped = output.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            const re = new RegExp(`hl\\.monitor\\(\\{[^}]*output\\s*=\\s*"${escaped}"[^}]*\\}\\)`, "m");
            if (re.test(text))
                text = text.replace(re, line);
            else if (text.length === 0)
                text = line + "\n";
            else
                text = text.replace(/\n*$/, "") + "\n" + line + "\n";
            content = text;
            setText(text);
        }
    }
}

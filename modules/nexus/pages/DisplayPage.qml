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

// Bildschirm-Einstellungen. In der VM steuert spice-vdagent (Auto-Resize) die Aufloesung
// automatisch (folgt der GNOME-Boxes-Fenstergroesse) -> eine manuelle Auflösungswahl
// wuerde vom Agent sofort ueberschrieben. Daher: Aufloesung nur ANZEIGEN + Hinweis;
// die SKALIERUNG ist einstellbar (setzt hl.monitor durch, wird nicht ueberschrieben).
PageBase {
    id: root

    title: Tr.t("Display")

    readonly property var mon: {
        const list = Hypr.monitors?.values ?? [];
        return Hypr.focusedMonitor ?? list[0] ?? null;
    }
    readonly property var io: mon?.lastIpcObject ?? ({})
    // Echter Hyprland-Name steht im rohen IPC-Objekt (z.B. "Virtual-1"); mon.name kann
    // eine abweichende Quickshell-Bezeichnung sein.
    readonly property string monName: (io.name ?? mon?.name ?? "").toString()

    property real selectedScale: io.scale ?? mon?.scale ?? 1

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.medium
            visible: !root.mon
            horizontalAlignment: Text.AlignHCenter
            text: Tr.t("No monitors detected")
            color: Colours.palette.m3outlineVariant
        }

        SectionHeader {
            first: true
            text: root.monName
            visible: !!root.mon
        }

        InfoRow {
            visible: !!root.mon
            first: true
            icon: "monitor"
            label: Tr.t("Current mode")
            value: {
                const w = root.io.width ?? 0;
                const h = root.io.height ?? 0;
                const hz = root.io.refreshRate ?? 0;
                return `${w}x${h} @ ${Math.round(hz)} Hz`;
            }
        }

        InfoRow {
            visible: !!root.mon
            icon: "aspect_ratio"
            label: Tr.t("Position")
            value: `${root.io.x ?? 0}, ${root.io.y ?? 0}`
        }

        InfoRow {
            visible: !!root.mon
            last: true
            icon: "desktop_windows"
            label: Tr.t("Model")
            value: (root.io.model ?? root.io.description ?? "—").toString()
        }

        // Hinweis: Aufloesung folgt dem Fenster (Auto-Resize).
        StyledText {
            visible: !!root.mon
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.medium
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large
            text: Tr.t("The resolution follows the window size automatically (VM auto-resize). Resize or maximise the Boxes window to change it.")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            wrapMode: Text.Wrap
        }

        // Skalierung (wird durchgesetzt, nicht vom Agent ueberschrieben).
        SectionHeader {
            visible: !!root.mon
            text: Tr.t("Scaling")
        }

        StepperRow {
            visible: !!root.mon
            first: true
            last: true
            label: Tr.t("Scale")
            subtext: Tr.t("Display scaling factor (percent)")
            from: 50
            to: 300
            stepSize: 25
            value: Math.round(root.selectedScale * 100)
            onMoved: value => {
                root.selectedScale = value / 100;
                root.applyScale();
            }
        }
    }

    // Skalierung setzen (Laufzeit via hl.monitor eval) + persistent in hypr-user.lua.
    // Behaelt die aktuelle Aufloesung ("preferred" laesst Auto-Resize weiter zu).
    function applyScale(): void {
        const name = root.monName;
        if (!name)
            return;
        const scale = root.selectedScale;
        // Lua-Config: hl.monitor via hyprctl eval (keyword geht nicht bei non-legacy parser).
        applyProc.command = ["hyprctl", "eval",
            `hl.monitor({ output = "${name}", mode = "preferred", position = "auto", scale = ${scale} })`];
        applyProc.running = true;

        userConfig.writeScale(name, scale);
        Toaster.toast(Tr.t("Display updated"), Tr.t("Scale set to %1%").arg(Math.round(scale * 100)), "monitor");
    }

    readonly property Process applyProc: Process {}

    // hypr-user.lua: hl.monitor-Zeile fuer den Monitor aktualisieren (nur scale, mode
    // bleibt "preferred" damit Auto-Resize weiter greift).
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

        function writeScale(output: string, scale: real): void {
            let text = content;
            const line = `hl.monitor({ output = "${output}", mode = "preferred", position = "auto", scale = ${scale} })`;
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

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.services

Scope {
    id: root

    readonly property list<var> warnLevels: [...GlobalConfig.general.battery.warnLevels].sort((a, b) => a.level - b.level)
    property real lastPercentage: 100

    function handleBatteryWarnings(): void {
        const p = UPower.displayDevice.percentage * 100;

        if (!UPower.onBattery) {
            root.lastPercentage = p;
            return;
        }

        if (root.lastPercentage >= 0) {
            for (const level of root.warnLevels) {
                if (p <= level.level && root.lastPercentage > level.level) {
                    Toaster.toast(level.title ?? Tr.t("Battery warning"), level.message ?? Tr.t("Battery level is low"), level.icon ?? "battery_android_alert", level.critical ? Toast.Error : Toast.Warning);
                    break;
                }
            }
        }

        if (!hibernateTimer.running && p <= GlobalConfig.general.battery.criticalLevel) {
            Toaster.toast(Tr.t("Hibernating in 5 seconds"), Tr.t("Hibernating to prevent data loss"), "battery_android_alert", Toast.Error);
            hibernateTimer.start();
        }

        root.lastPercentage = p;
    }

    Connections {
        function onOnBatteryChanged(): void {
            if (!UPower.displayDevice.ready)
                return;

            if (UPower.onBattery) {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(Tr.t("Charger unplugged"), Tr.t("Battery is discharging"), "power_off");
                root.handleBatteryWarnings();
            } else {
                if (GlobalConfig.utilities.toasts.chargingChanged)
                    Toaster.toast(Tr.t("Charger plugged in"), Tr.t("Battery is charging"), "power");
                root.lastPercentage = 100;
            }
        }

        target: UPower
    }

    Connections {
        function onReadyChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Connections {
        function onPercentageChanged(): void {
            if (!UPower.displayDevice.ready)
                return;
            root.handleBatteryWarnings();
        }

        target: UPower.displayDevice
    }

    Timer {
        id: hibernateTimer

        interval: 5000
        onTriggered: SessionManager.hibernate()
    }
}

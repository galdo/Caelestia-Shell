import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.services

Scope {
    Connections {
        function onLoaded(): void {
            if (GlobalConfig.utilities.toasts.configLoaded)
                Toaster.toast(Tr.t("Config loaded"), Tr.t("Config loaded successfully!"), "rule_settings");
        }

        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(Tr.t("Failed to parse config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        function onSaveFailed(error: string, screen: string): void {
            Toaster.toast(Tr.t("Failed to save config%1").arg(screen ? " for " + screen : ""), error, "settings_alert", Toast.Error);
        }

        function onUnknownOption(key: string, screen: string): void {
            Toaster.toast(Tr.t("Unknown option in%1 config").arg(screen ? " " + screen : ""), key, "question_mark", Toast.Warning);
        }

        target: GlobalConfig
    }

    Connections {
        function onLoadFailed(error: string, screen: string): void {
            Toaster.toast(Tr.t("Failed to parse token config%1").arg(screen ? "for " + screen : ""), error, "settings_alert", Toast.Warning);
        }

        function onUnknownOption(key: string, screen: string): void {
            Toaster.toast(Tr.t("Unknown option in%1 token config").arg(screen ? " " + screen : ""), key, "question_mark", Toast.Warning);
        }

        target: TokenConfig
    }
}

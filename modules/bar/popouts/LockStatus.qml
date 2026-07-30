import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    StyledText {
        text: Tr.t("Capslock: %1").arg(Hypr.capsLock ? "Enabled" : "Disabled")
    }

    StyledText {
        text: Tr.t("Numlock: %1").arg(Hypr.numLock ? "Enabled" : "Disabled")
    }
}

#pragma once

#include "configobject.hpp"

#include <qstringlist.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class DockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    // Default AUS: Shell laedt garantiert. In den Einstellungen einschalten ->
    // etwaiger Crash erscheint dann im journalctl (Shell lief bis dahin) mit QML-Zeile.
    CONFIG_PROPERTY(bool, enabled, false)
    // Angeheftete Apps (DesktopEntry-IDs). Global (nicht per-Monitor).
    CONFIG_GLOBAL_PROPERTY(QStringList, pinned, {})
    // Position in der linken Bar-Spalte: "bottom" (unten, um die untere-linke Ecke)
    // oder "top" (oben, um die obere-linke Ecke).
    CONFIG_PROPERTY(QString, position, u"bottom"_s)
    // Zusaetzlich laufende, nicht angeheftete Apps anzeigen (Taskbar-Verhalten).
    CONFIG_PROPERTY(bool, showRunning, true)
    // Icon-Groesse (Kantenlaenge px, 1:1). Dock waechst mit -> Icons nie abgeschnitten.
    CONFIG_PROPERTY(int, iconSize, 40)

public:
    explicit DockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config

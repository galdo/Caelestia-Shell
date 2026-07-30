#pragma once

#include "configobject.hpp"

#include <qstringlist.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

class DockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    // Angeheftete Apps (DesktopEntry-IDs). Global (nicht per-Monitor).
    CONFIG_GLOBAL_PROPERTY(QStringList, pinned, {})
    // Position in der linken Bar-Spalte: "bottom" (unten, um die untere-linke Ecke)
    // oder "top" (oben, um die obere-linke Ecke).
    CONFIG_PROPERTY(QString, position, u"bottom"_s)
    // Zusaetzlich laufende, nicht angeheftete Apps anzeigen (Taskbar-Verhalten).
    CONFIG_PROPERTY(bool, showRunning, true)

public:
    explicit DockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config

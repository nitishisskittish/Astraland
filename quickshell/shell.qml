import QtQuick
import QtQuick.Controls

ApplicationWindow {
    Loader {
        source: "notifications.qml"
    }
    Loader {
        source: "bar.qml"
    }
}

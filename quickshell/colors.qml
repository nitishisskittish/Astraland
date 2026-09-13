pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var colors: ({})

    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/colors/matugen_output.gen"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.colors = JSON.parse(text())
    }
}

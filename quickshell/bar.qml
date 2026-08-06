import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import "globalConfig.js" as Global

PanelWindow {
    id: root
    screen: Quickshell.screens[2]

    property int cpuUsage: 0
    property int memUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property var battery: 0
    property int brightness: 0
    property bool batteryWarning: false

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Global.bar.height
    color: "#1a1b26"

    FileView {
        id: statFile
        path: "/proc/stat"
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
    }

    FileView {
        id: batFile
        path: "/sys/class/power_supply/BAT0/capacity"
    }

    function updateCpu() {
        statFile.reload();
        var line = statFile.text().split("\n")[0];
        var p = line.trim().split(/\s+/);
        var idle = parseInt(p[4]) + parseInt(p[5]);
        var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0);
        if (lastCpuTotal > 0) {
            cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)));
        }
        lastCpuTotal = total;
        lastCpuIdle = idle;
    }

    function updateMem() {
        memFile.reload();
        var lines = memFile.text().split("\n");
        var vals = {};
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].match(/^(\w+):\s+(\d+)/);
            if (m)
                vals[m[1]] = parseInt(m[2]);
        }
        var total = vals["MemTotal"] || 1;
        var avail = vals["MemAvailable"] || 0;
        memUsage = Math.round(100 * (total - avail) / total);
    }

    function updateBattery() {
        batFile.reload();
        var val = parseInt(batFile.text().trim());
        battery = val;
        if (battery > 15) {
            batteryWarning = false;
        }
        if (battery < 15 && !batteryWarning) {
            notifyProc.running = true;
            batteryWarning = true;
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "Battery Warning", "Battery below 15%"]
    }

    Process {
        id: brightnessMonitor
        command: ["brightnessctl", "monitor"]
        running: true

        onRunningChanged: {
            if (!running)
                running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                brightnessProc.running = true;
            }
        }
    }

    Process {
        id: brightnessProc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                if (data)
                    root.brightness = parseInt(data.trim());
            }
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: updateBattery()
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            updateCpu();
            updateMem();
        }
    }

    Component.onCompleted: {
        updateCpu();
        updateMem();
        updateBattery();
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4

        Repeater {
            model: 9

            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: index + 1
                color: isActive ? Global.colors.cyan : (ws ? Global.colors.blue : Global.colors.muted)
                font {
                    pixelSize: Global.bar.fontSize
                    bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${index + 1} })`)
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: " " + cpuUsage + "%"     // CPU
            color: Global.colors.yellow
            font {
                family: Global.bar.fontFamily
                pixelSize: Global.bar.fontSize
                bold: true
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: Global.colors.muted
        }

        Text {
            text: ":" + memUsage + "%"
            color: Global.colors.yellow
            font {
                family: Global.bar.fontFamily
                pixelSize: Global.bar.fontSize
                bold: true
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: Global.colors.muted
        }

        Text {
            PwObjectTracker {
                objects: [Pipewire.defaultAudioSink]
            }
            property int volume: Math.round(Pipewire.defaultAudioSink.audio.volume * 100)
            text: (Pipewire.defaultAudioSink.audio.muted ? "󰖁 " : volume > 65 ? "󰕾 " : volume > 35 ? "󰖀 " : "󰕿 ") + volume + "%"
            color: Global.colors.yellow
            font {
                family: Global.bar.fontFamily
                pixelSize: Global.bar.fontSize
                bold: true
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: Global.colors.muted
        }

        Text {
            text: (root.brightness <= 33 ? "󰃞 " : root.brightness <= 66 ? "󰃟 " : "󰃠 ") + root.brightness + "%"
            color: Global.colors.yellow
            font {
                family: Global.bar.fontFamily
                pixelSize: Global.bar.fontSize
                bold: true
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: Global.colors.muted
        }

        Text {
            text: (battery >= 80 ? "+" : battery >= 60 ? " " : battery >= 40 ? " " : battery >= 15 ? " " : " ") + battery + "%"
            color: battery < 15 ? Global.colors.red : Global.colors.yellow
            font {
                family: Global.bar.fontFamily
                pixelSize: Global.bar.fontSize
                bold: true
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: Global.colors.muted
        }

        Text {
            id: clock
            text: Qt.formatDateTime(new Date(), "hh:mm ap")
            Timer {
                interval: 60000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "hh:mm ap")
            }

            color: Global.colors.yellow
            font {
                family: Global.bar.fontFamily
                pixelSize: Global.bar.fontSize
                bold: true
            }
        }
    }
}

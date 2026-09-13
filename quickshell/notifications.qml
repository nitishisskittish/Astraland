import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls
import "."

Scope {
    id: root
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 16
    property bool centerOpen: false
    ListModel {
        id: history
    }
    NotificationServer {
        id: server
        actionsSupported: true
        bodyImagesSupported: true
        imageSupported: true
        onNotification: n => {
            history.insert(0, {
                summary: n.summary,
                body: n.body,
                appName: n.appName,
                urgency: n.urgency,
                time: Qt.formatDateTime(new Date(), "hh:mm ap")
            }), n.tracked = true;
        }
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void {
            root.centerOpen = !root.centerOpen;
        }
        function show(): void {
            root.centerOpen = true;
        }
        function hide(): void {
            root.centerOpen = false;
        }
    }
    PanelWindow {
        visible: !centerOpen
        anchors {
            top: true
            right: true
        }
        margins {
            top: 12
            right: 12
        }
        implicitWidth: 370
        implicitHeight: Math.max(1, column.implicitHeight)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        ColumnLayout {
            id: column
            width: parent.width
            spacing: 10
            Repeater {
                model: server.trackedNotifications
                Rectangle {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 85
                    radius: 8
                    color: Colors.colors.bg
                    border.width: 2
                    border.color: modelData.urgency == NotificationUrgency.Critical ? Colors.colors.red : Colors.colors.highlight2
                    Timer {
                        running: card.modelData.urgency != NotificationUrgency.Critical
                        interval: 5000
                        onTriggered: card.modelData.dismiss()
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                text: card.modelData.summary
                                font.family: fontFamily
                                font.pixelSize: fontSize
                                color: Colors.colors.highlight1
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                visible: text !== ""
                                text: card.modelData.body
                                font.family: fontFamily
                                font.pixelSize: fontSize - 1
                                color: Colors.colors.fg
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.appName
                                font.family: fontFamily
                                font.pixelSize: fontSize - 3
                                color: Colors.colors.muted
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: card.modelData.dismiss()
                    }
                }
            }
        }
    } // Notification Center
    PanelWindow {
        visible: root.centerOpen
        anchors {
            top: true
            right: true
        }
        Timer {
            id: closeTimer
            interval: 2000
            repeat: false
            onTriggered: root.centerOpen = false
        }
        margins {
            top: 12
            right: 12
        }
        implicitWidth: history.count > 0 ? 380 : 300
        implicitHeight: Math.min(centerCol.implicitHeight + 24, 600)
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Colors.colors.bg
            border.width: 2
            border.color: Colors.colors.highlight1
            ColumnLayout {
                id: centerCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: history.count > 0 ? 4 : 0
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: history.count > 0 ? Text.AlignLeft : Text.AlignHCenter
                        text: history.count > 0 ? "Notifications" : "No Notifications"
                        color: Colors.colors.highlight1
                        font.family: fontFamily
                        font.pixelSize: fontSize + 2
                        font.bold: true
                    }
                    Text {
                        text: "Clear all"
                        visible: history.count > 0
                        color: Colors.colors.red
                        font.family: fontFamily
                        font.pixelSize: fontSize - 1
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                history.clear();
                                closeTimer.restart();
                            }
                        }
                    }
                }
                ScrollView {
                    clip: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ColumnLayout {
                        id: cardCol
                        width: parent.width
                        Repeater {
                            model: history
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: content.implicitHeight + 20
                                radius: 8
                                color: Colors.colors.bg_dark
                                border.width: 2
                                ColumnLayout {
                                    id: content
                                    anchors.margins: 10
                                    anchors.fill: parent
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            Layout.fillWidth: true
                                            text: model.summary
                                            font.family: fontFamily
                                            font.pixelSize: fontSize
                                            color: Colors.colors.fg
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: model.time
                                            font.family: fontFamily
                                            font.pixelSize: fontSize - 3
                                            color: Colors.colors.muted
                                        }
                                        Text {
                                            text: "x"
                                            font.family: fontFamily
                                            font.pixelSize: fontSize - 3
                                            color: Colors.colors.muted
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: {
                                                    if (history.count <= 1) {
                                                        closeTimer.restart();
                                                    }
                                                    history.remove(index);
                                                }
                                            }
                                        }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: model.body
                                        font.family: fontFamily
                                        font.pixelSize: fontSize - 1
                                        color: Colors.colors.fg
                                        wrapMode: Text.WordWrap
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: model.appName != ""
                                        text: model.appName
                                        font.family: fontFamily
                                        font.pixelSize: fontSize - 3
                                        color: Colors.colors.muted
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

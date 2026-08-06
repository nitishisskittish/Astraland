import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import QtQuick.Controls

import "globalConfig.js" as Global

Scope {
    id: root
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
                    Layout.preferredHeight: 75

                    radius: 8
                    color: Global.colors.bg
                    border.width: 2
                    border.color: modelData.urgency == NotificationUrgency.Critical ? Global.colors.red : Global.colors.purple

                    Timer {
                        running: card.modelData.urgency != NotificationUrgency.Critical
                        interval: Global.notifications.timeout
                        onTriggered: card.modelData.dismiss()
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Image {
                            Layout.preferredHeight: 55
                            Layout.preferredWidth: 55
                            Layout.alignment: Qt.AlignTop
                            fillMode: Image.PreserveAspectFit
                            visible: card.modelData.image !== "" || card.modelData.appIcon !== ""
                            source: card.modelData.image !== "" ? card.modelData.image : (card.modelData.appIcon !== "" ? Quickshell.iconPath(card.modelData.appIcon) : "")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                text: card.modelData.summary
                                font.family: Global.bar.fontFamily
                                font.pixelSize: Global.bar.fontSize
                                color: Global.colors.cyan
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                visible: text !== ""
                                text: card.modelData.body
                                font.family: Global.bar.fontFamily
                                font.pixelSize: Global.bar.fontSize - 1
                                color: Global.colors.fg
                                elide: Text.ElideRight
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
    }

    //Notification Center
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

        implicitWidth: 380
        implicitHeight: Math.min(centerCol.implicitHeight + 24, 600)

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Global.colors.bg
            border.width: 2
            border.color: Global.colors.purple

            ColumnLayout {
                id: centerCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: Global.colors.cyan
                        font.family: Global.bar.fontFamily
                        font.pixelSize: Global.bar.fontSize + 2
                        font.bold: true
                    }

                    Text {
                        text: "Clear all"
                        visible: history.count > 0
                        color: Global.colors.red
                        font.family: Global.bar.fontFamily
                        font.pixelSize: Global.bar.fontSize - 1

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
                                color: Global.colors.bg_dark
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
                                            font.family: Global.bar.fontFamily
                                            font.pixelSize: Global.bar.fontSize
                                            color: Global.colors.fg
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: model.time
                                            font.family: Global.bar.fontFamily
                                            font.pixelSize: Global.bar.fontSize - 3
                                            color: Global.colors.muted
                                        }

                                        Text {
                                            text: "x"
                                            font.family: Global.bar.fontFamily
                                            font.pixelSize: Global.bar.fontSize - 3
                                            color: Global.colors.muted

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
                                        font.family: Global.bar.fontFamily
                                        font.pixelSize: Global.bar.fontSize - 1
                                        color: Global.colors.fg
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: model.appName != ""
                                        text: model.appName
                                        font.family: Global.bar.fontFamily
                                        font.pixelSize: Global.bar.fontSize - 3
                                        color: Global.colors.muted
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

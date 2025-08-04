// FramelessHelper.qml

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.1

Item {
    id: root

    property Window window // no longer required
    property int resizeMargin: 8
    property bool enableDrag: true
    property bool enableResize: true

    // ---- Drag Area ----
    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: resizeMargin // Don't interfere with resize areas

        property point clickPos

        onPressed: {
            if (!window || window.visibility === Window.FullScreen) return;
            clickPos = Qt.point(mouse.x, mouse.y)
        }

        onPositionChanged: {
            if (!window || window.visibility === Window.FullScreen) return;
            if (mouse.buttons & Qt.LeftButton) {
                window.x += mouse.x - clickPos.x
                window.y += mouse.y - clickPos.y
            }
        }
    }

    // ---- Edge Resize Areas ----
    // Left edge
    Rectangle {
        visible: enableResize && window
        width: resizeMargin
        height: parent.height - 2 * resizeMargin // Leave space for corners
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor

            property real startX
            property real startWidth

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startX = window.x
                startWidth = window.width
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalX = mapToGlobal(mouse.x, mouse.y).x
                let deltaX = globalX - startX

                if (startWidth - deltaX >= window.minimumWidth) {
                    window.x = startX + deltaX
                    window.width = startWidth - deltaX
                }
            }
        }
    }

    // Right edge
    Rectangle {
        visible: enableResize && window
        width: resizeMargin
        height: parent.height - 2 * resizeMargin
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor

            property real startWidth

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startWidth = window.width
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalX = mapToGlobal(mouse.x, mouse.y).x
                let newWidth = globalX - window.x

                if (newWidth >= window.minimumWidth) {
                    window.width = newWidth
                }
            }
        }
    }

    // Top edge
    Rectangle {
        visible: enableResize && window
        width: parent.width - 2 * resizeMargin
        height: resizeMargin
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor

            property real startY
            property real startHeight

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startY = window.y
                startHeight = window.height
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalY = mapToGlobal(mouse.x, mouse.y).y
                let deltaY = globalY - startY

                if (startHeight - deltaY >= window.minimumHeight) {
                    window.y = startY + deltaY
                    window.height = startHeight - deltaY
                }
            }
        }
    }

    // Bottom edge
    Rectangle {
        visible: enableResize && window
        width: parent.width - 2 * resizeMargin
        height: resizeMargin
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor

            property real startHeight

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startHeight = window.height
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalY = mapToGlobal(mouse.x, mouse.y).y
                let newHeight = globalY - window.y

                if (newHeight >= window.minimumHeight) {
                    window.height = newHeight
                }
            }
        }
    }

    // ---- Corner Resize Areas ----
    // Top-left corner
    Rectangle {
        visible: enableResize && window
        width: resizeMargin
        height: resizeMargin
        anchors.top: parent.top
        anchors.left: parent.left
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor

            property real startX
            property real startY
            property real startWidth
            property real startHeight

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startX = window.x
                startY = window.y
                startWidth = window.width
                startHeight = window.height
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalPos = mapToGlobal(mouse.x, mouse.y)
                let deltaX = globalPos.x - startX
                let deltaY = globalPos.y - startY

                if (startWidth - deltaX >= window.minimumWidth && startHeight - deltaY >= window.minimumHeight) {
                    window.x = startX + deltaX
                    window.y = startY + deltaY
                    window.width = startWidth - deltaX
                    window.height = startHeight - deltaY
                }
            }
        }
    }

    // Top-right corner
    Rectangle {
        visible: enableResize && window
        width: resizeMargin
        height: resizeMargin
        anchors.top: parent.top
        anchors.right: parent.right
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor

            property real startY
            property real startHeight

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startY = window.y
                startHeight = window.height
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalPos = mapToGlobal(mouse.x, mouse.y)
                let newWidth = globalPos.x - window.x
                let deltaY = globalPos.y - startY

                if (newWidth >= window.minimumWidth && startHeight - deltaY >= window.minimumHeight) {
                    window.width = newWidth
                    window.y = startY + deltaY
                    window.height = startHeight - deltaY
                }
            }
        }
    }

    // Bottom-left corner
    Rectangle {
        visible: enableResize && window
        width: resizeMargin
        height: resizeMargin
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeBDiagCursor

            property real startX
            property real startWidth

            onPressed: {
                if (!window || window.visibility === Window.FullScreen) return;
                startX = window.x
                startWidth = window.width
            }

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalPos = mapToGlobal(mouse.x, mouse.y)
                let deltaX = globalPos.x - startX
                let newHeight = globalPos.y - window.y

                if (startWidth - deltaX >= window.minimumWidth && newHeight >= window.minimumHeight) {
                    window.x = startX + deltaX
                    window.width = startWidth - deltaX
                    window.height = newHeight
                }
            }
        }
    }

    // Bottom-right corner
    Rectangle {
        visible: enableResize && window
        width: resizeMargin
        height: resizeMargin
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor

            onPositionChanged: {
                if (!window || !(mouse.buttons & Qt.LeftButton) || window.visibility === Window.FullScreen)
                    return

                let globalPos = mapToGlobal(mouse.x, mouse.y)
                let newWidth = globalPos.x - window.x
                let newHeight = globalPos.y - window.y

                if (newWidth >= window.minimumWidth && newHeight >= window.minimumHeight) {
                    window.width = newWidth
                    window.height = newHeight
                }
            }
        }
    }
}

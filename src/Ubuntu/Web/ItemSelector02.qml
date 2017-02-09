/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItems

Item {
    id: itemSelector

    property QtObject selectorModel: model

    property var webview: null
    property real maximumLabelWidth

    property real contentWidth: Math.max(model.elementRect.width, maximumLabelWidth + units.gu(6))
    property real contentHeight
    width: contentWidth
    height: contentHeight

    property real listContentHeight: 0 // intermediate property to avoid binding loop
    property real listItemHeight: units.gu(4)
    property real addressBarHeight: webview.height - webview.viewportHeight
    property bool isAbove

    onListContentHeightChanged: updatePosition()
    function updatePosition() {
        itemSelector.x = model.elementRect.x;
        var availableAbove = model.elementRect.y - addressBarHeight;
        var availableBelow = webview.viewportHeight - model.elementRect.y - model.elementRect.height + addressBarHeight;

        if (availableBelow >= availableAbove) {
            // position popover below the box
            itemSelector.isAbove = false;
            itemSelector.contentHeight = Math.min(availableBelow, listContentHeight);
            itemSelector.y = model.elementRect.y + model.elementRect.height;
        } else {
            // position popover above the box
            itemSelector.isAbove = true;
            itemSelector.contentHeight = Math.min(availableAbove, listContentHeight);
            itemSelector.y = model.elementRect.y - itemSelector.contentHeight;
        }
    }

    // eat mouse events beneath the list so that they never reach the webview below
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onWheel: wheel.accepted = true
    }

    // eat mouse events around the list so that they never reach the webview below
    InverseMouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: selectorModel.accept()
        onWheel: wheel.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.overlay
        function newColorWithAlpha(color, alpha) {
            return Qt.rgba(color.r, color.g, color.b, alpha);
        }
        border.color: newColorWithAlpha(theme.palette.normal.base, 0.4)
        border.width: units.dp(1)
    }

    ListView {
        id: listView
        clip: true
        width: itemSelector.contentWidth
        height: itemSelector.contentHeight
        keyNavigationWraps: true

        property int initialIndex
        Component.onCompleted: currentIndex = initialIndex

        model: selectorModel.items

        delegate: ListItem {
            height: listItemLayout.height + (divider.visible ? divider.height : 0)
            ListItemLayout {
                id: listItemLayout
                padding {
                    top: 0
                    bottom: 0
                }
                height: listItemHeight
                title.height: listItemHeight
                title.verticalAlignment: Text.AlignVCenter
                title.text: model.text
                title.onPaintedWidthChanged: maximumLabelWidth = Math.max(title.paintedWidth, maximumLabelWidth)
            }

            color: selected ? theme.palette.normal.focus : "transparent"
            selected: model.selected
            Component.onCompleted: if (model.selected) listView.initialIndex = model.index

            onClicked: {
                selectorModel.items.select(model.index)
                selectorModel.accept()
            }
        }

        section.property: "group"
        section.delegate: ListItems.Header {
            text: section
        }

        onContentHeightChanged: itemSelector.listContentHeight = contentHeight
    }

    Scrollbar {
        flickableItem: listView
        align: Qt.AlignTrailing
    }

    onVisibleChanged: {
        if (!visible) {
            selectorModel.cancel()
        }
    }
}

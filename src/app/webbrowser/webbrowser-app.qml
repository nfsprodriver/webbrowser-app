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
import QtQuick.Window 2.2
import Ubuntu.Components 1.3
import ".."

BrowserWindow {
    id: window

    property alias urls: browser.initialUrls
    property alias newSession: browser.newSession

    currentWebview: browser.currentWebview

    title: {
        if (browser.title) {
            // TRANSLATORS: %1 refers to the current page’s title
            return i18n.tr("%1 - Ubuntu Web Browser").arg(browser.title)
        } else {
            return i18n.tr("Ubuntu Web Browser")
        }
    }

    Browser {
        id: browser
        anchors.fill: parent
        webbrowserWindow: webbrowserWindowProxy
        developerExtrasEnabled: window.developerExtrasEnabled

        fullscreen: window.visibility === Window.FullScreen

        Component.onCompleted: i18n.domain = "webbrowser-app"

        Keys.onPressed: {
            if ((event.key === Qt.Key_F11) && (event.modifiers === Qt.NoModifier)) {
                // F11 to toggle application-level fullscreen
                window.setFullscreen(window.visibility !== Window.FullScreen)
                if (currentWebview.fullscreen) {
                    currentWebview.fullscreen = false
                }
            }
        }
        Keys.onEscapePressed: {
            // ESC to exit fullscreen, regardless of whether it was requested
            // by the page or toggled on by the user.
            window.setFullscreen(false)
            currentWebview.fullscreen = false
        }
    }

    onOpenUrls: {
        for (var i = 0; i < urls.length; ++i) {
            var setCurrent = (i == urls.length - 1)
            browser.openUrlInNewTab(urls[i], setCurrent, setCurrent)
        }
    }
}

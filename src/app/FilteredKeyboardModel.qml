/*
 * Copyright 2016 Canonical Ltd.
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
import Unity.InputInfo 0.1

SortFilterModel {
    model: InputDeviceModel {
        deviceFilter: InputInfo.Keyboard
    }
    filter {
        // Filter out autopilot-emulated keyboards
        // (see https://launchpad.net/bugs/1542224).
        property: "name"
        pattern: /^(?!py-evdev-uinput).*$/
    }
}

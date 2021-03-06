# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Copyright 2015-2016 Canonical
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License version 3, as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

from autopilot.platform import model
from autopilot.matchers import Eventually
import testtools
from testtools.matchers import Contains, Equals, StartsWith

from webbrowser_app.tests import StartOpenRemotePageTestCaseBase


class TestContextMenuBase(StartOpenRemotePageTestCaseBase):

    data_uri_prefix = "data:image/png;base64,"

    def setUp(self, path):
        super(TestContextMenuBase, self).setUp(path)
        self.menu = self.main_window.open_context_menu()
        # The context menu should never steal active focus from the webview,
        # but because it’s currently implemented as a dialog on narrow screens,
        # it does (see https://launchpad.net/bugs/1526884).
        if self.main_window.wide:
            webview = self.main_window.get_current_webview()
            self.assertThat(webview.activeFocus, Equals(True))

    def verify_link_opened_in_a_new_tab(self):
        self.assert_number_webviews_eventually(2)
        webview = self.main_window.get_current_webview()
        new_url = self.base_url + "/test1"
        self.assertThat(webview.url, Eventually(Equals(new_url)))

    def verify_link_bookmarked(self):
        url = self.base_url + "/test1"
        self.main_window.go_to_url(url)
        self.main_window.wait_until_page_loaded(url)
        self.main_window.chrome.bookmarked.wait_for(True)

    def verify_image_opened_in_a_new_tab(self):
        self.assert_number_webviews_eventually(2)
        webview = self.main_window.get_current_webview()
        self.assertThat(webview.url,
                        Eventually(StartsWith(self.data_uri_prefix)))


class TestContextMenuLink(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuLink, self).setUp(path="/link")
        self.assertThat(self.menu.get_title_label().text,
                        Equals(self.base_url + "/test1"))

    def test_open_link_in_new_tab(self):
        self.menu.click_action("OpenLinkInNewTabContextualAction")
        self.verify_link_opened_in_a_new_tab()

    def test_bookmark_link(self):
        self.menu.click_action("BookmarkLinkContextualAction")
        bookmark_options = self.main_window.get_bookmark_options()
        bookmark_options.click_dismiss_button()
        self.verify_link_bookmarked()

    def test_copy_link(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyLinkContextualAction")

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self.menu.click_action("ShareContextualAction")
        self.main_window.wait_select_single("ContentShareDialog")


class TestContextMenuImage(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuImage, self).setUp(path="/image")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_open_image_in_new_tab(self):
        self.menu.click_action("OpenImageInNewTabContextualAction")
        self.verify_image_opened_in_a_new_tab()

    def test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyImageContextualAction")


class TestContextMenuImageAndLink(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuImageAndLink, self).setUp(path="/imagelink")
        self.assertThat(self.menu.get_title_label().text,
                        StartsWith(self.data_uri_prefix))

    def test_open_link_in_new_tab(self):
        self.menu.click_action("OpenLinkInNewTabContextualAction")
        self.verify_link_opened_in_a_new_tab()

    def test_bookmark_link(self):
        self.menu.click_action("BookmarkLinkContextualAction")
        bookmark_options = self.main_window.get_bookmark_options()
        bookmark_options.click_dismiss_button()
        self.verify_link_bookmarked()

    def test_copy_link(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyLinkContextualAction")

    @testtools.skipIf(model() == "Desktop", "on devices only")
    def test_share_link(self):
        self.menu.click_action("ShareContextualAction")
        self.main_window.wait_select_single("ContentShareDialog")

    def test_open_image_in_new_tab(self):
        self.menu.click_action("OpenImageInNewTabContextualAction")
        self.verify_image_opened_in_a_new_tab()

    def test_copy_image(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyImageContextualAction")


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestContextMenuTextArea(TestContextMenuBase):

    def setUp(self):
        super(TestContextMenuTextArea, self).setUp(path="/textarea")
        self.assertThat(self.menu.get_title_label().visible, Equals(False))

    def test_actions(self):
        webview = self.main_window.get_current_webview()
        actions = ["SelectAll", "Cut", "Undo", "Redo",
                   "Paste", "SelectAll", "Copy", "Erase"]
        for action in actions:
            self.menu.click_action("{}ContextualAction".format(action))
            self.assertThat(webview.activeFocus, Eventually(Equals(True)))
            self.menu = self.main_window.open_context_menu()


@testtools.skipIf(model() != "Desktop", "on desktop only")
class TestContextMenuTextSelection(StartOpenRemotePageTestCaseBase):

    def setUp(self):
        super(TestContextMenuTextSelection, self).setUp(path="/test1")
        # This test is not meant to be run without a mouse.
        self.assertThat(str(self.pointing_device._device), Contains("Mouse"))
        # Click and drag with the mouse to select the text in the page.
        rect = self.main_window.get_current_webview().globalRect
        x0 = rect.x + 5
        y0 = rect.y + self.main_window.chrome.height + 5
        x1 = rect.x + rect.width - 5
        y1 = rect.y + rect.height - 5
        self.pointing_device.drag(x0, y0, x1, y1)
        # Open the context menu.
        self.menu = self.main_window.open_context_menu()

    def test_copy_text(self):
        # There is no easy way to test the contents of the clipboard,
        # but we can at least verify that the context menu was dismissed.
        self.menu.click_action("CopyContextualAction")

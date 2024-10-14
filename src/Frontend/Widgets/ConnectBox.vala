/***
  Copyright (C) 2014 Kiran John Hampal <kiran@elementaryos.org>

  This program is free software: you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License version 3, as published
  by the Free Software Foundation.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranties of
  MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License along
  with this program. If not, see <http://www.gnu.org/licenses>
***/

namespace Taxi {
    public class ConnectBox : Adw.Bin {
        private Gtk.ComboBoxText protocol_combobox;
        private Gtk.Entry path_entry;
        private ulong? handler;
        private bool show_fav_icon = false;
        private bool added = false;

        public signal void connect_initiated (GLib.Uri uri);
        public signal void bookmarked ();
        public signal GLib.Uri ask_hostname ();

        construct {
            string[] entries = {"FTP", "SFTP", "DAV", "AFP"};

            protocol_combobox = new Gtk.ComboBoxText ();
            foreach (var entry in entries) {
                protocol_combobox.append_text (entry);
            }
            protocol_combobox.active = 0;

            path_entry = new Gtk.Entry ();
            path_entry.placeholder_text = _("hostname:port/folder");
            path_entry.hexpand = true;
            path_entry.max_width_chars = 10000;

            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.append (protocol_combobox);
            box.append (path_entry );
            box.add_css_class (Granite.STYLE_CLASS_LINKED);

            child = box;

            path_entry.activate.connect (submit_form);
            path_entry.changed.connect (on_changed);

            var focus_controller = new Gtk.EventControllerFocus ();
            path_entry.add_controller (focus_controller);
            focus_controller.enter.connect (on_grab_focus);
            focus_controller.leave.connect (on_focus_out);
        }

        private void submit_form () {
            var protocol = ((Protocol) protocol_combobox.get_active ()).to_plain_text ();
            var path = path_entry.get_text ();

            try {
                var uri = Uri.parse (protocol + "://" + path, PARSE_RELAXED);
                connect_initiated (uri);
            } catch (Error err) {
                warning (err.message);
            }
        }

        private void on_changed () {
            var host_icon = path_entry.get_icon_name (Gtk.EntryIconPosition.SECONDARY);
            if (host_icon != "go-jump-symbolic") {
                path_entry.set_icon_from_icon_name (
                    Gtk.EntryIconPosition.SECONDARY,
                    "go-jump-symbolic"
                );
                if (handler != null) {
                    path_entry.disconnect (handler);
                }
                path_entry.icon_press.connect (this.submit_form);
            } else if (path_entry.get_text () == "") {
                if (show_fav_icon) {
                    show_favorite_icon (added);
                } else {
                    hide_host_icon ();
                }
            }
        }

        private void on_focus_out () {
            if (path_entry.get_text () == "" && show_fav_icon) {
                var uri_reply = ask_hostname ();
                // TODO: Handle text changes in a less lazy way
                path_entry.changed.disconnect (this.on_changed);
                path_entry.set_text (uri_reply.to_string ());
                path_entry.changed.connect (this.on_changed);
            }
        }

        private void hide_host_icon () {
            path_entry.set_icon_from_icon_name (
                Gtk.EntryIconPosition.SECONDARY,
                null
            );
        }

        public void go_to_uri (string uri) {
            string [] split = uri.split ("://");

            switch (split[0].up ()) {
                case "FTP":
                    protocol_combobox.active = 0;
                    break;
                case "SFTP":
                    protocol_combobox.active = 1;
                    break;
                case "DAV":
                    protocol_combobox.active = 2;
                    break;
                case "AFP":
                    protocol_combobox.active = 3;
                    break;
            }

            path_entry.text = split[1];

            try {
                connect_initiated (GLib.Uri.parse (uri, PARSE_RELAXED));
            } catch (Error err) {
                warning (err.message);
            }
        }

        public void show_favorite_icon (bool added = false) {
            path_entry.icon_press.disconnect (this.submit_form);
            show_fav_icon = true;
            this.added = added;
            var icon_name = added ? "starred-symbolic" : "non-starred-symbolic";
            path_entry.set_icon_from_icon_name (
                Gtk.EntryIconPosition.SECONDARY,
                icon_name
            );
            if (handler != null) {
                path_entry.disconnect (handler);
            }
            handler = path_entry.icon_press.connect (() => {
                bookmarked ();
            });
        }

        public bool on_key_press_event () {
            if (!path_entry.has_visible_focus ()) {
                path_entry.grab_focus ();
            }

            return false;
        }

        private void on_grab_focus () {
            path_entry.select_region (0, 0);
            path_entry.set_position (-1);
        }
    }
}

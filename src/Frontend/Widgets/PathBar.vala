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
    class PathBar : Gtk.Box {
        public bool transfer_button_sensitive { get; set; }

        private GLib.Uri current_uri;

        public signal void navigate (GLib.Uri uri);
        public signal void transfer ();

        public PathBar.from_uri (GLib.Uri uri) {
            set_path (uri);
        }

        construct {
            height_request = 32;
            add_css_class ("pathbar");
        }

        private string concat_until (string[] words, int n) {
            var result = "";
            for (int i = 0; (i < n + 1) && (i < words.length); i++) {
                result += words [i] + "/";
            }
            return result;
        }

        private void add_path_frag (string child, string path) {
            var button = new Gtk.Button () {
                valign = CENTER
            };

            if (path == "/") {
                button.child = new Gtk.Image.from_icon_name (child);
            } else {
                var label = new Gtk.Label (child);
                label.ellipsize = Pango.EllipsizeMode.MIDDLE;

                button.tooltip_text = child;
                button.child = label;

                var sep = new Gtk.Image.from_icon_name ("go-next-symbolic") {
                    margin_start = 3,
                    margin_end = 3,
                    css_classes = { Granite.STYLE_CLASS_DIM_LABEL }
                };

                append (sep);
            }

            button.add_css_class (Granite.STYLE_CLASS_FLAT);
            button.add_css_class ("path-button");

            button.clicked.connect (() => {
                try {
                    current_uri = GLib.Uri.parse (current_uri.get_scheme () + "://" + path, PARSE_RELAXED);
                    navigate (current_uri);
                } catch (Error err) {
                    warning (err.message);
                }
            });

            append (button);
        }

        public void set_path (GLib.Uri uri) {
            clear_path ();
            current_uri = uri;
            string transfer_icon_name;
            var scheme = uri.get_scheme ();
            switch (scheme) {
                case "file":
                    add_path_frag ("drive-harddisk-symbolic", "/");
                    transfer_icon_name = "document-export-symbolic";
                    break;
                case "ftp":
                case "sftp":
                default:
                    add_path_frag ("folder-remote-symbolic", "/");
                    transfer_icon_name = "document-import-symbolic";
                    break;
            }
            set_path_helper (uri.get_path ());

            var transfer_button = new Gtk.Button.from_icon_name (transfer_icon_name) {
                valign = CENTER
            };
            transfer_button.halign = Gtk.Align.END;
            transfer_button.hexpand = true;
            transfer_button.sensitive = false;
            transfer_button.tooltip_text = _("Transfer");
            transfer_button.bind_property (
                "sensitive", this,
                "transfer-button-sensitive",
                GLib.BindingFlags.BIDIRECTIONAL
            );
            transfer_button.add_css_class (Granite.STYLE_CLASS_FLAT);

            transfer_button.clicked.connect (() => transfer ());

            append (transfer_button);
        }

        private void set_path_helper (string path) {
            string[] directories = path.split ("/");
            for (int i = 0; i < directories.length; i++) {
                if (directories [i] != "") {
                    add_path_frag (directories [i], concat_until (directories, i));
                }
            }
        }

        private void clear_path () {
            for (Gtk.Widget? child = get_first_child (); child != null;) {
                Gtk.Widget? next = child.get_next_sibling ();
                remove (child);
                child = next;
            }

            margin_top = 0;
            margin_bottom = 0;
            margin_start = 0;
            margin_end = 0;
        }
    }
}

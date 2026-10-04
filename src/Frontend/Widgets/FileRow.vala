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

    class FileRow : Gtk.ListBoxRow {
        public GLib.FileInfo file_info { get; construct; }

        private Gtk.CheckButton checkbox;
        private Gtk.Popover menu_popover;

        GLib.Uri _current_uri;
        public GLib.Uri current_uri {
            get {
                return _current_uri;
            }

            set {
                _current_uri = value;
            }
        }

        GLib.Uri _uri;
        public GLib.Uri? uri {
            get {
                try {
                    _uri = GLib.Uri.parse_relative (current_uri, file_info.get_name (), PARSE_RELAXED);
                } catch (Error e) {
                    message (e.message);
                }

                return _uri;
            }
        }

        public string file_name {
            get {
                return file_info.get_name ();
            }
        }

        public GLib.FileType file_type {
            get {
                return file_info.get_file_type ();
            }
        }

        public bool active {
            get {
                return checkbox.active;
            }
        }

        public signal void on_checkbutton_toggle ();
        public signal void on_delete ();

        public FileRow (GLib.FileInfo file_info) {
            Object (
                file_info: file_info
            );
        }

        construct {
            checkbox = new Gtk.CheckButton ();
            checkbox.toggled.connect (() => {
                on_checkbutton_toggle ();
            });

            var icon = new Gtk.Image.from_gicon (file_info.get_icon ()) {
                pixel_size = 24
            };

            var name = new Gtk.Label (file_info.get_name ());
            name.halign = Gtk.Align.START;
            name.hexpand = true;

            var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
                hexpand = true,
                margin_top = 6,
                margin_bottom = 6,
                margin_start = 12,
                margin_end = 12
            };
            row.append (checkbox);
            row.append (icon);
            row.append (name);

            if (file_info.get_file_type () == FileType.REGULAR) {
                var size = new Gtk.Label (bit_string_format (file_info.get_size ()));
                size.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);
                row.append (size);
            }

            child = row;
            build_dnd ();

            var menu_gesture = new Gtk.GestureClick () {
                button = 3
            };
            add_controller (menu_gesture);
            menu_gesture.pressed.connect ((n_press, x, y) => {
                build_context_menu (x, y);
            });
        }

        private void build_context_menu (double x, double y) {
            if (menu_popover != null) {
                menu_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
                menu_popover.popup ();
                return;
            }

            var open_menu = new Gtk.Button () {
                child = new Gtk.Label (_("Open")) {
                    halign = START
                },
                css_classes = { Granite.STYLE_CLASS_MENUITEM }
            };

            var delete_menu = new Gtk.Button () {
                child = new Gtk.Label (_("Delete")) {
                    halign = START
                },
                css_classes = { Granite.STYLE_CLASS_MENUITEM }
            };

            var menu_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                margin_top = 3,
                margin_bottom = 3
            };

            menu_box.append (open_menu);
            menu_box.append (delete_menu);

            menu_popover = new Gtk.Popover () {
                has_arrow = false,
                halign = Gtk.Align.START,
                child = menu_box,
                width_request = 250
            };

            menu_popover.set_parent (this);
            menu_popover.pointing_to = { ((int) x), (int) y, 1, 1 };
            menu_popover.popup ();

            open_menu.clicked.connect (() => {
                menu_popover.popdown ();
                open_menu.activate_action_variant ("win.open", new Variant.string (uri.to_string ()));
            });

            delete_menu.clicked.connect (() => {
                menu_popover.popdown ();
                open_menu.activate_action_variant ("win.delete", new Variant.string (uri.to_string ()));
            });
        }

        private void build_dnd () {
            var drag_source = new Gtk.DragSource ();
            drag_source.set_actions (Gdk.DragAction.COPY);
            add_controller (drag_source);

            drag_source.prepare.connect ((x, y) => {
                return new Gdk.ContentProvider.for_value (this);
            });

            drag_source.drag_begin.connect ((source, drag) => {
                var paintable = new Gtk.WidgetPaintable (this);
                source.set_icon (paintable, 0, 0);
            });
        }

        private string bit_string_format (int64 bytes) {
            var floatbytes = (float) bytes;
            int i;
            for (i = 0; floatbytes >= 1000.0f || i > 6; i++) {
                floatbytes /= 1000.0f;
            }
            string[] measurement = { "bytes", "kB", "MB", "GB", "TB", "PB", "EB" };
            return "%.3g %s".printf (floatbytes, measurement [i]);
        }
    }
}

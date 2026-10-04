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

    class OperationsPopover : Gtk.Popover {

        private Gtk.ListBox listbox;

        private Gee.Map<IOperationInfo, Gtk.ListBoxRow> operation_map = new Gee.HashMap <IOperationInfo, Gtk.ListBoxRow> ();

        public signal void operations_pending ();
        public signal void operations_finished ();

        construct {
            listbox = new Gtk.ListBox () {
                margin_top = 12,
                margin_bottom = 12,
                margin_start = 12,
                margin_end = 12
            };
            listbox.set_placeholder (new Gtk.Label (_("No file operations are in progress")));

            child = listbox;
            autohide = false;
        }

        public async void add_operation (IOperationInfo operation) {
            if (operation_map.size <= 0) {
                operations_pending ();
            }

            var row_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                margin_top = 3,
                margin_bottom = 3
            };

            var icon = yield operation.get_file_icon ();
            row_box.append (new Gtk.Image.from_gicon (icon));

            row_box.append (new Gtk.Label (operation.get_file_name ()) {
                margin_start = 6,
                ellipsize = END
            });

            var cancel_container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                hexpand = true,
                halign = END,
                margin_start = 12
            };
            cancel_container.append (new Gtk.Image.from_icon_name ("process-stop-symbolic"));

            var click_controller = new Gtk.GestureClick ();
            cancel_container.add_controller (click_controller);
            click_controller.pressed.connect (() => {
                operation.cancel ();
            });

            row_box.append (cancel_container);

            operation_map[operation] = new Gtk.ListBoxRow () {
                child = row_box,
                tooltip_text = operation.get_file_name ()
            };

            listbox.append (operation_map[operation]);
        }

        public void remove_operation (IOperationInfo operation) {
            if (!operation_map.has_key (operation)) {
                return;
            }

            var row = operation_map.get (operation);
            listbox.remove (row);
            operation_map.unset (operation);
            if (operation_map.size <= 0) {
                operations_finished ();
            }
        }
    }
}

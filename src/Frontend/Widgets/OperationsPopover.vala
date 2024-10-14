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

        Gtk.Grid grid;
        Gtk.Label placeholder;

        Gee.Map<IOperationInfo, Gtk.Box> operation_map = new Gee.HashMap <IOperationInfo, Gtk.Box> ();

        public signal void operations_pending ();
        public signal void operations_finished ();

        public OperationsPopover (Gtk.Widget widget) {
            set_parent (widget);
            grid = new Gtk.Grid () {
                margin_top = 12,
                margin_bottom = 12,
                margin_start = 12,
                margin_end = 12
            };

            placeholder = new Gtk.Label (_("No file operations are in progress"));
            child = grid;

            build ();
        }

        private void build () {
            grid.attach (placeholder, 0, 0);
        }

        public async void add_operation (IOperationInfo operation) {
            if (grid.get_child_at (0, 0) == placeholder) {
                grid.remove (placeholder);
                operations_pending ();
            }
            var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            operation_map.set (operation, row);

            var icon = yield operation.get_file_icon ();
            row.append (new Gtk.Image.from_gicon (icon));

            row.append (new Gtk.Label (operation.get_file_name ()) {
                margin_start = 6
            });

            var cancel_container = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
                hexpand = true,
                halign = END
            };
            cancel_container.append (new Gtk.Image.from_icon_name ("process-stop-symbolic"));

            var click_controller = new Gtk.GestureClick ();
            cancel_container.add_controller (click_controller);
            click_controller.pressed.connect (() => {
                operation.cancel ();
            });

            row.append (cancel_container);

            grid.attach (row, 0, 0);
        }

        public void remove_operation (IOperationInfo operation) {
            var row = operation_map.get (operation);
            grid.remove (row);
            operation_map.unset (operation);
            if (operation_map.size == 0) {
                operations_finished ();
                grid.attach (placeholder, 0, 0);
            }
        }
    }
}

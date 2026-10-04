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

    class LocalFileAccess : FileAccess {

        private File _file_handle;
        private FileMonitor? file_monitor;

        private override File file_handle {
            get {
                return _file_handle;
            }
            set {
                try {
                    _file_handle = value;
                    if (file_monitor != null) {
                        file_monitor.cancel ();
                    }
                    file_monitor = _file_handle.monitor_directory (
                        FileMonitorFlags.NONE,
                        null
                    );
                    file_monitor.changed.connect (() => {
                        directory_changed ();
                    });
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }

        public LocalFileAccess () {
            file_monitor = null;
            file_operation = new FileOperations ();
            file_handle = File.new_for_path (Environment.get_home_dir ());
        }

        public async override bool connect_to_device (
            GLib.Uri uri,
            Gtk.Window window
        ) {
            return true;
        }
    }
}

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

    class RemoteFileAccess : FileAccess {

        private GLib.Uri uri;
        private Gtk.Window window;

        public RemoteFileAccess () {
            file_operation = new FileOperations ();
        }

        public async override bool connect_to_device (
            GLib.Uri uri,
            Gtk.Window window
        ) {
            this.window = window;
            var mount = mount_operation_from_uri (uri);
            this.uri = uri;
            file_handle = File.new_for_uri (uri.to_string ());
            try {
                return yield file_handle.mount_enclosing_volume (
                    MountMountFlags.NONE,
                    mount,
                    null
                );
            } catch (Error e) {

                // Already mounted
                if (e.code == 17) {
                    return true;
                }

                message ("ERROR MOUNTING: " + e.message + "\n");

                return false;

            } finally {
                connected ();
            }
        }

        public override async List<FileInfo> get_file_list () {
            return yield get_file_list_helper (5);
        }

        private async List<FileInfo> get_file_list_helper (int attempts_left = 5) {
            try {
                return yield file_operation.get_file_list (file_handle);
            } catch (Error e) {

                // Unmounted
                if (e.code == 16 && attempts_left > 0) {
                    if (yield connect_to_device (uri, window)) {
                        return yield get_file_list_helper (--attempts_left);
                    }
                }

                // Host closed conn
                if (e.code == 0 && attempts_left > 0) {
                    return yield get_file_list_helper (--attempts_left);
                }

                message (e.message);

                return new List<FileInfo> ();
            }
        }

        /*public override void goto_path (string path) {
            file_handle = file_handle.resolve_relative_path ("/" + path);
        }*/

        private Gtk.MountOperation mount_operation_from_uri (GLib.Uri uri) {
            var mount = new Gtk.MountOperation (window);
            mount.set_domain (uri.get_host ());
            return mount;
        }
    }
}

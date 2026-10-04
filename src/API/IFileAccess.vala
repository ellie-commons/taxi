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

    interface IFileAccess : Object {

        public signal void connected ();
        public signal void directory_changed ();

        /**
         * Connects to a server
         *
         * @return true if successful at connecting
         */
        public async abstract bool connect_to_device (
            GLib.Uri uri,
            Gtk.Window window
        );

        /**
         * Get a list of files in a directory
         *
         * @return a list of file information objects
         */
        public async abstract List<FileInfo> get_file_list ();

        public abstract GLib.Uri? get_uri ();

        public abstract void goto_dir (GLib.Uri uri);

        public abstract void open_file (GLib.Uri uri);

        public abstract File get_current_file ();
    }
}

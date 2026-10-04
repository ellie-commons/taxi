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

    class ConnectionSaver : IConnectionSaver, Object {

        string file_dir = Path.build_filename (
            Environment.get_user_config_dir (),
            "taxi"
        );
        string file_name = Path.build_filename (
            Environment.get_user_config_dir (),
            "taxi",
            "servers.xbel"
        );

        public bool save (string uri) {
            var data_folder = File.new_for_path (file_dir);
            if (!data_folder.query_exists ()) {
                try {
                    data_folder.make_directory (null);
                } catch (Error e) {
                    message (e.message);
                    return false;
                }
            }
            try {
                var bookmark = new BookmarkFile ();
                var bookmark_file = File.new_for_path (file_name);
                if (bookmark_file.query_exists ()) {
                    bookmark.load_from_file (file_name);
                    if (bookmark.has_item (uri)) {
                        message ("Item already exists");
                        return true;
                    }
                }
                bookmark.add_application (uri, "taxi", "taxi");
                return bookmark.to_file (file_name);
            } catch (Error e) {
                message (e.message);
            }

            return false;
        }

        public bool remove (string uri) {
            var bookmark = new BookmarkFile ();
            var bookmark_file = File.new_for_path (file_name);
            if (bookmark_file.query_exists ()) {
                try {
                    bookmark.load_from_file (file_name);
                    bookmark.remove_application (uri, "taxi");
                    return bookmark.to_file (file_name);
                } catch (Error e) {
                    message (e.message);
                    return false;
                }
            }
            return false;
        }

        public List<string> get_saved_conns () {
            var bookmark = new BookmarkFile ();
            var bookmark_file = File.new_for_path (file_name);
            var connection_list = new List<string> ();
            if (bookmark_file.query_exists ()) {
                try {
                    bookmark.load_from_file (file_name);
                    foreach (string uri in bookmark.get_uris ()) {
                        connection_list.append (uri);
                    }
                } catch (Error e) {
                    message (e.message);
                }
            }
            return connection_list;
        }

        public bool is_bookmarked (string uri) {
            var bookmark = new BookmarkFile ();
            var bookmark_file = File.new_for_path (file_name);
            if (bookmark_file.query_exists ()) {
                try {
                    bookmark.load_from_file (file_name);
                    return bookmark.has_item (uri);
                } catch (Error e) {
                    message (e.message);
                }
            }
            return false;
        }
    }
}

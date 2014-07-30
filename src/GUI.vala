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

using Gtk;
using Granite;

namespace Taxi {

    class GUI : Object {

        Gtk.Window window;
        Gtk.HeaderBar header_bar;
        ConnectBox connect_box;
        Granite.Widgets.Welcome welcome;
        FilePane local_pane;
        FilePane remote_pane;
        IConnectionSaver conn_saver;
        IFileAccess remote_access;
        IFileAccess local_access;
        IFileOperations file_operation;

        public GUI (
            IFileAccess local_access,
            IFileAccess remote_access,
            IFileOperations file_operation,
            IConnectionSaver conn_saver
        ) {
            this.local_access = local_access;
            this.remote_access = remote_access;
            this.file_operation = file_operation;
            this.conn_saver = conn_saver;
            this.remote_access.connected.connect (() => {
            });
        }

        public void build () {
            window = new Gtk.Window ();
            add_header_bar ();
            add_welcome ();
            setup_window ();
            setup_styles ();
            Gtk.main ();
        }

        private void add_header_bar () {
            header_bar = new HeaderBar ();
            connect_box = new ConnectBox ();
            header_bar.set_show_close_button (true);
            header_bar.set_custom_title (new Gtk.Label (null));
            header_bar.pack_start (connect_box);

            connect_box.connect_initiated.connect (this.connect_init);
            connect_box.bookmarked.connect (this.bookmark);
        }

        private void add_welcome () {
            welcome = new Granite.Widgets.Welcome (
                "Connect",
                "Type an URL and press 'Enter' to connect to a server."
            );
            welcome.margin = 12;
            window.add (welcome);
        }

        private void connect_init (IConnInfo conn) {
            remote_access.connect_to_device.begin (conn, (obj, res) => {
                if (remote_access.connect_to_device.end (res)) {
                    if (local_pane == null) {
                        window.remove (welcome);
                        add_panes ();
                    }
                    update_local_pane ();
                    update_remote_pane ();
                    connect_box.show_favorite_icon (
                        conn_saver.is_bookmarked (remote_access.get_uri ())
                    );
                    window.show_all ();
                } else {
                    welcome.title = "Could not connect to '" +
                        conn.hostname + ":" + conn.port.to_string () + "'";
                }
            });
        }

        private void bookmark () {
            if (conn_saver.is_bookmarked (remote_access.get_uri ())) {
                conn_saver.remove (remote_access.get_uri ());
            } else {
                conn_saver.save (remote_access.get_uri ());
            }
            connect_box.show_favorite_icon (
                conn_saver.is_bookmarked (remote_access.get_uri ())
            );
        }

        private void add_panes () {
            var pane_inner = new Gtk.Grid ();
            pane_inner.set_column_homogeneous (true);

            local_pane = new FilePane (true);
            pane_inner.add (local_pane);

            local_pane.row_clicked.connect (this.on_local_row_clicked);
            local_pane.pathbar_activated.connect (this.on_local_pathbar_activated);
            local_pane.file_dragged.connect (this.on_local_file_dragged);

            remote_pane = new FilePane ();
            pane_inner.add (remote_pane);
            remote_pane.row_clicked.connect (this.on_remote_row_clicked);
            remote_pane.pathbar_activated.connect (this.on_remote_pathbar_activated);
            remote_pane.file_dragged.connect (this.on_remote_file_dragged);

            window.add (pane_inner);
        }

        private void on_local_pathbar_activated (string path) {
            local_access.goto_path (path);
            update_local_pane ();
        }

        private void on_local_row_clicked (string name) {
            local_access.goto_child (name);
            update_local_pane ();
        }

        private void on_remote_pathbar_activated (string path) {
            remote_access.goto_path (path);
            update_remote_pane ();
        }

        private void on_remote_row_clicked (string name) {
            remote_access.goto_child (name);
            update_remote_pane ();
        }

        private void on_remote_file_dragged (string uri) {
            on_file_dragged (uri, remote_pane, remote_access);
        }

        private void on_local_file_dragged (string uri) {
            on_file_dragged (uri, local_pane, local_access);
        }

        private void on_file_dragged (string uri, FilePane file_pane, IFileAccess file_access) {
            var source_file = File.new_for_uri (uri.replace ("\r\n", ""));
            var dest_file = file_access.get_current_file ().get_child (source_file.get_basename ());
            file_operation.copy_recursive.begin (
                source_file,
                dest_file,
                FileCopyFlags.NONE,
                null,
                (obj, res) => {
                    try {
                        file_operation.copy_recursive.end (res);
                        update_pane (file_access, file_pane);
                    } catch (Error e) {
                        warning (e.message);
                    }
                }
             );
        }

        private void update_local_pane () {
            update_pane (local_access, local_pane);
        }

        private void update_remote_pane () {
            update_pane (remote_access, remote_pane);
        }

        private void update_pane (IFileAccess file_access, FilePane file_pane) {
            var file_uri = file_access.get_uri ();
            file_access.get_file_list.begin ((obj, res) => {
                var file_files = file_access.get_file_list.end (res);
                file_pane.update_list (file_files);
                file_pane.update_pathbar (file_uri);
            });
        }

        private void setup_styles () {
            try {
                string styles;
                FileUtils.get_contents ("css/fallback.css", out styles);
                Granite.Widgets.Utils.set_theming_for_screen (
                    Gdk.Screen.get_default (),
                    styles,
                    Gtk.STYLE_PROVIDER_PRIORITY_FALLBACK
                );
                message (styles);
                FileUtils.get_contents ("css/application.css", out styles);
                Granite.Widgets.Utils.set_theming_for_screen (
                    Gdk.Screen.get_default (),
                    styles,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                );
                message (styles);
            } catch (FileError e) {
                warning ("Couldn't load welcome stylesheet fallback");
            }
        }

        private void setup_window () {
            window.default_width = 650;
            window.default_height = 550;
            window.set_titlebar (header_bar);
            window.show_all ();
        }
    }
}

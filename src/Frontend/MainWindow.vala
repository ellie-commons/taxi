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
  with program. If not, see <http://www.gnu.org/licenses>
***/

class Taxi.MainWindow : Gtk.ApplicationWindow {
    public IConnectionSaver conn_saver { get; construct; }
    public IFileOperations file_operation { get; construct; }
    public IFileAccess local_access { get; construct; }
    public IFileAccess remote_access { get; construct; }

    private Granite.Toast toast;
    private Gtk.Revealer spinner_revealer;
    private Gtk.Box bookmark_list;
    private Gtk.Box outer_box;
    private Gtk.MenuButton bookmark_menu_button;
    private Gtk.Stack alert_stack;
    private ConnectBox connect_box;
    private FilePane local_pane;
    private FilePane remote_pane;
    private GLib.Uri conn_uri;
    private Gtk.Popover bookmark_popover;
    private Gtk.Box welcome_box;
    private Gtk.Label title_label;

    public MainWindow (
        Gtk.Application application,
        IFileAccess local_access,
        IFileAccess remote_access,
        IFileOperations file_operation,
        IConnectionSaver conn_saver
    ) {
        Object (
            application: application,
            conn_saver: conn_saver,
            file_operation: file_operation,
            local_access: local_access,
            remote_access: remote_access
        );
    }

    construct {
        var navigate_action = new SimpleAction ("navigate", VariantType.STRING);
        navigate_action.activate.connect (action_navigate);

        var open_action = new SimpleAction ("open", VariantType.STRING);
        open_action.activate.connect (action_open);

        var delete_action = new SimpleAction ("delete", VariantType.STRING);
        delete_action.activate.connect (action_delete);

        add_action (navigate_action);
        add_action (open_action);
        add_action (delete_action);

        connect_box = new ConnectBox ();
        connect_box.valign = Gtk.Align.CENTER;

        var spinner = new Gtk.Spinner ();
        spinner.start ();

        var popover = new OperationsPopover (spinner);

        var operations_button = new Gtk.MenuButton () {
            popover = popover,
            valign = CENTER,
            child = spinner
        };
        operations_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        spinner_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT,
            child = operations_button
        };

        bookmark_list = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        bookmark_list.add_css_class (Granite.STYLE_CLASS_MENU);

        var bookmark_scrollbox = new Gtk.ScrolledWindow () {
            child = bookmark_list,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            max_content_height = 500,
            propagate_natural_height = true,
        };

        bookmark_popover = new Gtk.Popover () {
            child = bookmark_scrollbox,
            width_request = 250
        };

        bookmark_menu_button = new Gtk.MenuButton () {
            icon_name = "user-bookmarks",
            tooltip_text = _("Access Bookmarks"),
            popover = bookmark_popover,
            valign = CENTER
        };
        bookmark_menu_button.add_css_class (Granite.STYLE_CLASS_LARGE_ICONS);

        update_bookmark_menu ();

        var header_bar = new Adw.HeaderBar () {
            show_title = false
        };
        header_bar.pack_start (connect_box);
        header_bar.pack_start (spinner_revealer);
        header_bar.pack_start (bookmark_menu_button);

        var app_icon = new Gtk.Image.from_icon_name ("com.github.alecaddd.taxi") {
            pixel_size = 64
        };

        title_label = new Gtk.Label (_("Connect"));
        title_label.add_css_class (Granite.STYLE_CLASS_H1_LABEL);

        var description_label = new Gtk.Label (_("Type a URL and press 'Enter' to\nconnect to a server.")) {
            justify = CENTER
        };

        welcome_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            hexpand = true,
            vexpand = true,
            halign = CENTER,
            valign = CENTER
        };
        welcome_box.append (app_icon);
        welcome_box.append (title_label);
        welcome_box.append (description_label);

        local_pane = new FilePane ();
        local_pane.open.connect (on_local_open);
        local_pane.navigate.connect (on_local_navigate);
        local_pane.file_dragged.connect (on_local_file_dragged);
        local_pane.transfer.connect (on_remote_file_dragged);
        local_access.directory_changed.connect (() => update_pane (Location.LOCAL));

        remote_pane = new FilePane ();
        remote_pane.open.connect (on_remote_open);
        remote_pane.navigate.connect (on_remote_navigate);
        remote_pane.file_dragged.connect (on_remote_file_dragged);
        remote_pane.transfer.connect (on_local_file_dragged);

        outer_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        outer_box.append (local_pane);
        outer_box.append (new Gtk.Separator (Gtk.Orientation.VERTICAL));
        outer_box.append (remote_pane);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        size_group.add_widget (local_pane);
        size_group.add_widget (remote_pane);

        alert_stack = new Gtk.Stack ();
        alert_stack.add_child (welcome_box);
        alert_stack.add_child (outer_box);

        toast = new Granite.Toast ("");

        var overlay = new Gtk.Overlay () {
            child = alert_stack
        };
        overlay.add_overlay (toast);

        var grid = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        grid.append (header_bar);
        grid.append (overlay);

        // We need to hide the title area for the split headerbar
        var null_title = new Gtk.Grid () {
            visible = false
        };
        set_titlebar (null_title);

        child = grid;

        connect_box.connect_initiated.connect (on_connect_initiated);
        connect_box.ask_hostname.connect (on_ask_hostname);
        connect_box.bookmarked.connect (bookmark);

        file_operation.operation_added.connect (popover.add_operation);
        file_operation.operation_removed.connect (popover.remove_operation);

        popover.operations_pending.connect (show_spinner);
        popover.operations_finished.connect (hide_spinner);
    }

    private void on_connect_initiated (GLib.Uri uri) {
        show_spinner ();
        remote_access.connect_to_device.begin (uri, this, (obj, res) => {
            if (remote_access.connect_to_device.end (res)) {
                alert_stack.visible_child = outer_box;
                update_pane (Location.LOCAL);
                update_pane (Location.REMOTE);
                connect_box.show_favorite_icon (
                    conn_saver.is_bookmarked (remote_access.get_uri ().to_string ())
                );
                conn_uri = uri;
            } else {
                alert_stack.visible_child = welcome_box;
                title_label.label = _("Could not connect to '%s'").printf (uri.to_string ());
            }
            hide_spinner ();
        });
    }

    private void show_spinner () {
        spinner_revealer.reveal_child = true;
    }

    private void hide_spinner () {
        spinner_revealer.reveal_child = false;
    }

    private void bookmark () {
        var uri_string = conn_uri.to_string ();
        if (conn_saver.is_bookmarked (uri_string)) {
            conn_saver.remove (uri_string);
        } else {
            conn_saver.save (uri_string);
        }
        connect_box.show_favorite_icon (
            conn_saver.is_bookmarked (uri_string)
        );
        update_bookmark_menu ();
    }

    private void update_bookmark_menu () {
        for (Gtk.Widget? child = bookmark_list.get_first_child (); child != null;) {
            Gtk.Widget? next = child.get_next_sibling ();
            bookmark_list.remove (child);
            child = next;
        }

        var uri_list = conn_saver.get_saved_conns ();
        if (uri_list.length () == 0) {
            bookmark_menu_button.sensitive = false;
        } else {
            foreach (string uri in uri_list) {
                var bookmark_item = new Gtk.Button () {
                    child = new Gtk.Label (uri) {
                        halign = START
                    }
                };
                bookmark_item.add_css_class (Granite.STYLE_CLASS_MENUITEM);
                bookmark_item.clicked.connect (() => {
                    connect_box.go_to_uri (uri);
                    bookmark_popover.popdown ();
                });

                bookmark_list.append (bookmark_item);
            }
            bookmark_menu_button.sensitive = true;
        }
    }

    private void on_local_navigate (GLib.Uri uri) {
        navigate (uri, local_access, Location.LOCAL);
    }

    private void on_local_open (GLib.Uri uri) {
        local_access.open_file (uri);
    }

    private void on_remote_navigate (GLib.Uri uri) {
        navigate (uri, remote_access, Location.REMOTE);
    }

    private void on_remote_open (GLib.Uri uri) {
        remote_access.open_file (uri);
    }

    private void on_remote_file_dragged (string uri) {
        file_dragged (uri, Location.REMOTE, remote_access);
    }

    private void on_local_file_dragged (string uri) {
        file_dragged (uri, Location.LOCAL, local_access);
    }

    private void navigate (GLib.Uri uri, IFileAccess file_access, Location pane) {
        file_access.goto_dir (uri);
        update_pane (pane);
    }

    private void action_navigate (GLib.SimpleAction action, GLib.Variant? variant) {
        try {
            var uri = GLib.Uri.parse (variant.get_string (), PARSE_RELAXED);
            if (uri.get_scheme () == "file") {
                local_access.goto_dir (uri);
                update_pane (LOCAL);
            } else {
                remote_access.goto_dir (uri);
                update_pane (REMOTE);
            }
        } catch (Error err) {
            warning (err.message);
        }
    }

    private void action_open (GLib.SimpleAction action, GLib.Variant? variant) {
        try {
            var uri = GLib.Uri.parse (variant.get_string (), PARSE_RELAXED);
            if (uri.get_scheme () == "file") {
                local_access.open_file (uri);
            } else {
                remote_access.open_file (uri);
            }
        } catch (Error err) {
            warning (err.message);
        }
    }

    private void action_delete (GLib.SimpleAction action, GLib.Variant? variant) {
        try {
            var uri = GLib.Uri.parse (variant.get_string (), PARSE_RELAXED);
            if (uri.get_scheme () == "file") {
                file_delete (uri, Location.LOCAL);
            } else {
                file_delete (uri, Location.REMOTE);
            }
        } catch (Error err) {
            warning (err.message);
        }
    }

    private void file_dragged (
        string uri,
        Location pane,
        IFileAccess file_access
    ) {
        var source_file = File.new_for_uri (uri.replace ("\r\n", ""));
        var dest_file = file_access.get_current_file ().get_child (source_file.get_basename ());
        file_operation.copy_recursive.begin (
            source_file,
            dest_file,
            FileCopyFlags.NONE,
            new Cancellable (),
            (obj, res) => {
                try {
                    file_operation.copy_recursive.end (res);
                    update_pane (pane);
                } catch (Error e) {
                    toast.title = e.message;
                    toast.send_notification ();
                }
            }
         );
    }

    private void file_delete (GLib.Uri uri, Location pane) {
        var file = File.new_for_uri (uri.to_string ());
        file_operation.delete_recursive.begin (
            file,
            new Cancellable (),
            (obj, res) => {
                try {
                    file_operation.delete_recursive.end (res);
                    update_pane (pane);
                } catch (Error e) {
                    toast.title = e.message;
                    toast.send_notification ();
                }
            }
        );
    }

    private void update_pane (Location pane) {
        IFileAccess file_access;
        FilePane file_pane;
        switch (pane) {
            case Location.REMOTE:
                file_access = remote_access;
                file_pane = remote_pane;
                break;
            case Location.LOCAL:
            default:
                file_access = local_access;
                file_pane = local_pane;
                break;
        }
        file_pane.start_spinner ();
        var file_uri = file_access.get_uri ();
        file_access.get_file_list.begin ((obj, res) => {
        var file_files = file_access.get_file_list.end (res);
            file_pane.stop_spinner ();
            file_pane.update_pathbar (file_uri);
            file_pane.update_list (file_files);
        });
    }

    private GLib.Uri on_ask_hostname () {
        return conn_uri;
    }
}

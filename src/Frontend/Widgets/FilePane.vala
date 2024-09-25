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

    enum Target {
        STRING,
        URI_LIST;
    }

    //  const Gtk.TargetEntry[] TARGET_LIST = {
    //      { "test/plain", 0, Target.STRING },
    //      { "text/uri-list", 0, Target.URI_LIST }
    //  };

    class FilePane : Adw.Bin {
        private GLib.Uri current_uri;
        private PathBar path_bar;
        private Gtk.ListBox list_box;
        private Gtk.Stack stack;

        public signal void file_dragged (string uri);
        public signal void transfer (string uri);
        public signal void navigate (GLib.Uri uri);
        public signal void rename (GLib.Uri uri);
        public signal void open (GLib.Uri uri);
        public signal void edit (GLib.Uri uri);

        delegate void ActivateFunc (GLib.Uri uri);

        construct {
            path_bar = new PathBar () {
                hexpand = true
            };

            var placeholder_label = new Gtk.Label (_("This Folder Is Empty")) {
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };
            placeholder_label.add_css_class (Granite.STYLE_CLASS_H2_LABEL);
            placeholder_label.add_css_class (Granite.STYLE_CLASS_DIM_LABEL);

            list_box = new Gtk.ListBox () {
                hexpand = true,
                vexpand = true
            };

            list_box.set_placeholder (placeholder_label);
            list_box.set_selection_mode (Gtk.SelectionMode.MULTIPLE);

            var listbox_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            listbox_view.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            listbox_view.append (list_box);

            var scrolled_pane = new Gtk.ScrolledWindow () {
                child = listbox_view
            };

            var spinner = new Gtk.Spinner () {
                hexpand = true,
                vexpand = true,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER
            };
            spinner.start ();

            stack = new Gtk.Stack ();
            stack.add_named (scrolled_pane, "list");
            stack.add_named (spinner, "spinner");

            var toolbar = new Adw.ToolbarView ();
            toolbar.add_top_bar (path_bar);
            toolbar.content = stack;

            child = toolbar;

            //  list_box.drag_drop.connect (on_drag_drop);
            //  list_box.drag_data_received.connect (on_drag_data_received);
            list_box.row_activated.connect ((row) => {
                var uri = row.get_data<GLib.Uri> ("uri");
                var type = row.get_data<FileType> ("type");
                if (type == FileType.DIRECTORY) {
                    navigate (uri);
                } else {
                    open (uri);
                }
            });

            path_bar.navigate.connect (uri => navigate (uri));
            path_bar.transfer.connect (on_pathbar_transfer);

            //  Gtk.drag_dest_set (
            //      list_box,
            //      Gtk.DestDefaults.ALL,
            //      TARGET_LIST,
            //      Gdk.DragAction.COPY
            //  );
        }

        private void on_pathbar_transfer () {
            foreach (string uri in get_marked_row_uris ()) {
                transfer (uri);
            }
        }

        private Gee.List<string> get_marked_row_uris () {
            var uri_list = new Gee.ArrayList<string> ();

            Gtk.ListBoxRow row = null;
            var row_index = 0;

            do {
                row = list_box.get_row_at_index (row_index);
                if (row.get_data<Gtk.CheckButton> ("checkbutton").get_active ()) {
                    uri_list.add (current_uri.to_string () + "/" + row.get_data<string> ("name"));
                }

                row_index++;
            } while (row != null);

            return uri_list;
        }

        public void update_list (GLib.List<FileInfo> file_list) {
            clear_children (list_box);
            // Have to convert to gee list because glib list sort function is buggy
            // (it randomly removes items...)
            var gee_list = glib_to_gee<FileInfo> (file_list);
            alphabetical_order (gee_list);
            foreach (FileInfo file_info in gee_list) {
                if (file_info.get_name ().get_char (0) == '.') {
                    continue;
                }

                var row = new_row (file_info);
                if (row != null) {
                    list_box.append (row);
                }
            }
        }

        private Gee.ArrayList<G> glib_to_gee<G> (GLib.List<G> list) {
            var gee_list = new Gee.ArrayList<G> ();
            foreach (G item in list) {
                gee_list.add (item);
            }
            return gee_list;
        }

        private void alphabetical_order (Gee.ArrayList<FileInfo> file_list) {
            file_list.sort ((a, b) => {
                if ((a.get_file_type () == FileType.DIRECTORY) &&
                    (b.get_file_type () == FileType.DIRECTORY)) {
                    return a.get_name ().collate (b.get_name ());
                }
                if (a.get_file_type () == FileType.DIRECTORY) {
                    return -1;
                }
                if (b.get_file_type () == FileType.DIRECTORY) {
                    return 1;
                }
                return a.get_name ().collate (b.get_name ());
            });
        }

        private Gtk.ListBoxRow? new_row (FileInfo file_info) {
            var checkbox = new Gtk.CheckButton ();
            checkbox.toggled.connect (on_checkbutton_toggle);

            var icon = new Gtk.Image.from_gicon (file_info.get_icon ());

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

            GLib.Uri uri;
            try {
                uri = GLib.Uri.parse_relative (current_uri, file_info.get_name (), PARSE_RELAXED);
            } catch (Error e) {
                message (e.message);
                return null;
            }

            var ebrow = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            ebrow.append (row);
            ebrow.set_data ("name", file_info.get_name ());
            ebrow.set_data ("type", file_info.get_file_type ());

            var lbrow = new Gtk.ListBoxRow () {
                hexpand = true,
                child = ebrow
            };
            lbrow.set_data ("uri", uri);
            lbrow.set_data ("name", file_info.get_name ());
            lbrow.set_data ("type", file_info.get_file_type ());
            lbrow.set_data ("checkbutton", checkbox);

            //  Gtk.drag_source_set (
            //      ebrow,
            //      Gdk.ModifierType.BUTTON1_MASK,
            //      TARGET_LIST,
            //      Gdk.DragAction.COPY
            //  );
            
            //  ebrow.drag_begin.connect (on_drag_begin);
            //  ebrow.drag_data_get.connect (on_drag_data_get);
            //  ebrow.button_press_event.connect ((event) =>
            //      //  on_ebr_button_press (event, ebrow, lbrow)
            //  );
            //  ebrow.popup_menu.connect (() => on_ebr_popup_menu (ebrow));

            var click_controller = new Gtk.GestureClick () {
                button = 3
            };
            ebrow.add_controller (click_controller);
            click_controller.released.connect ((n_press, x, y) => {
                list_box.select_row (lbrow);
                //  event_box.popup_menu ();
            });

            return lbrow;
        }

        private void on_checkbutton_toggle () {
            if (get_marked_row_uris ().size > 0) {
                path_bar.transfer_button_sensitive = true;
            } else {
                path_bar.transfer_button_sensitive = false;
            }
        }

        private bool on_ebr_popup_menu (Gtk.Box event_box) {
            try {
                var uri = GLib.Uri.parse_relative (
                    current_uri,
                    event_box.get_data<string> ("name"),
                    PARSE_RELAXED
                );

                var menu_model = new GLib.Menu ();

                var type = event_box.get_data<FileType> ("type");
                if (type == FileType.DIRECTORY) {
                    menu_model.append (
                        _("Open"),
                        Action.print_detailed_name (
                            "win.navigate",
                            new Variant.string (uri.to_string ())
                        )
                    );
                } else {
                    menu_model.append (
                        _("Open"),
                        Action.print_detailed_name (
                            "win.open",
                            new Variant.string (uri.to_string ())
                        )
                    );

                    //menu.add (new_menu_item ("Edit", u => edit (u), uri));
                }

                //  var delete_section = new GLib.Menu ();
                //  delete_section.append (
                //      _("Delete"),
                //      Action.print_detailed_name (
                //          "win.delete",
                //          new Variant.string (uri.to_string ())
                //      )
                //  );

                //  menu_model.append_section (null, delete_section);

                //add_menu_item ("Rename", menu, u => rename (u), uri);

                //  var menu = new Gtk.Menu.from_model (menu_model) {
                //      attach_widget = event_box
                //  };
                //  menu.popup_at_pointer (null);
                //  menu.deactivate.connect (() => list_box.select_row (null));

                return true;
            } catch (Error err) {
                warning (err.message);
            }

            return false;
        }

        public void update_pathbar (GLib.Uri uri) {
            current_uri = uri;
            path_bar.set_path (uri);
        }

        private void clear_children (Gtk.ListBox listbox) {
            listbox.remove_all ();
        }

        public void start_spinner () {
            stack.visible_child_name = "spinner";
        }

        public void stop_spinner () {
            stack.visible_child_name = "list";
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

        //  private void on_drag_begin (Gtk.Widget widget, Gdk.DragContext context) {
        //      var widget_window = widget.get_window ();
        //      var pixbuf = Gdk.pixbuf_get_from_window (
        //          widget_window,
        //          0,
        //          0,
        //          widget_window.get_width (),
        //          widget_window.get_height ()
        //      );
        //      Gtk.drag_set_icon_pixbuf (context, pixbuf, 0, 0);
        //  }

        //  private bool on_drag_drop (
        //      Gtk.Widget widget,
        //      Gdk.DragContext context,
        //      int x,
        //      int y,
        //      uint time
        //  ) {
        //      var target_type = (Gdk.Atom) context.list_targets ().nth_data (Target.URI_LIST);
        //      Gtk.drag_get_data (widget, context, target_type, time);
        //      return true;
        //  }

        //  private void on_drag_data_get (
        //      Gtk.Widget widget,
        //      Gdk.DragContext context,
        //      Gtk.SelectionData selection_data,
        //      uint target_type,
        //      uint time
        //  ) {
        //      string file_name = widget.get_data ("name");
        //      string file_uri = current_uri.to_string () + "/" + file_name;
        //      switch (target_type) {
        //          case Target.URI_LIST:
        //              selection_data.set_uris ({ file_uri });
        //              break;
        //          case Target.STRING:
        //              selection_data.set_uris ({ file_uri });
        //              break;
        //          default:
        //              assert_not_reached ();
        //      }
        //  }

        //  private void on_drag_data_received (
        //      Gtk.Widget widget,
        //      Gdk.DragContext context,
        //      int x,
        //      int y,
        //      Gtk.SelectionData selection_data,
        //      uint target_type,
        //      uint time
        //  ) {
        //      switch (target_type) {
        //          case Target.URI_LIST:
        //              file_dragged ((string) selection_data.get_data ());
        //              break;
        //          case Target.STRING:
        //              break;
        //          default:
        //              message ("Data received not accepted");
        //              break;
        //      }
        //  }
    }
}

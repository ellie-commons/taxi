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

public class Taxi.Taxi : Gtk.Application {
    public Taxi () {
        Object (
            application_id: "com.github.alecaddd.taxi",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void startup () {
        base.startup ();

        Granite.init ();

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/alecaddd/taxi/Application.css");
        Gtk.StyleContext.add_provider_for_display (
            Gdk.Display.get_default (),
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        var granite_settings = Granite.Settings.get_default ();
        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = (
            granite_settings.prefers_color_scheme == DARK
        );

        granite_settings.notify["prefers-color-scheme"].connect (() => {
            gtk_settings.gtk_application_prefer_dark_theme = (
                granite_settings.prefers_color_scheme == DARK
            );
        });
    }

    protected override void activate () {
        var main_window = new MainWindow (
            this,
            new LocalFileAccess (),
            new RemoteFileAccess (),
            new FileOperations (),
            new ConnectionSaver ()
        );

        var settings = new Settings ("com.github.alecaddd.taxi.state");
        settings.bind ("window-height", main_window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-width", main_window, "default-width", SettingsBindFlags.DEFAULT);

        if (settings.get_boolean ("maximized")) {
            main_window.maximize ();
        }

        settings.bind ("maximized", main_window, "maximized", SettingsBindFlags.SET);

        main_window.present ();
    }

    public static int main (string[] args) {
        var program = new Taxi ();
        return program.run (args);
    }
}

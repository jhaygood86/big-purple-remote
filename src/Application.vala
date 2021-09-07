/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021 Justin Haygood <jhaygood86@gmail.com>
 */

public class BigPurpleRemoteApp : Gtk.Application {
    public BigPurpleRemoteApp () {
        Object (
            application_id: "io.github.jhaygood86.big-purple-remote",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {

        init_theme ();

        var css_provider = new Gtk.CssProvider ();
        css_provider.load_from_resource ("/io/github/jhaygood86/big-purple-remote/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        var main_window = new MainWindow (this);

        var gtk_settings = Gtk.Settings.get_default ();

        gtk_settings.gtk_application_prefer_dark_theme = true;

        main_window.show_all ();
    }

    private void init_theme () {
        GLib.Value value = GLib.Value (GLib.Type.STRING);

        Gtk.Settings.get_default ().set_property ("gtk-icon-theme-name", "elementary");
        Gtk.Settings.get_default ().set_property ("gtk-theme-name", "io.elementary.stylesheet.grape");
   }

    public static int main (string[] args) {
        return new BigPurpleRemoteApp ().run (args);
    }


}

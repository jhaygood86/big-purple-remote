public class MainWindow : Hdy.ApplicationWindow {
    public MainWindow (Gtk.Application application) {
            Object (
                application: application,
                icon_name: "com.github.jhaygood86.big-purple-remote",
                title: _("Big Purple Remote")
            );
    }

    RemoteGrid remote_grid;
    Hdy.HeaderBar header_bar;

    static construct {
        Hdy.init();
    }

    construct {
        header_bar = new Hdy.HeaderBar () {
            show_close_button = true,
            title = _("Big Purple Remote"),
            has_subtitle = false,
            hexpand = true,
            halign = Gtk.Align.FILL
        };

        Gdk.RGBA brand_color;
        brand_color.parse("#7239b3");

        Granite.Widgets.Utils.set_color_primary (this, brand_color);

        remote_grid = new RemoteGrid ();

        var window_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        window_box.add(header_bar);
        window_box.add(remote_grid);

        child = window_box;

        remote_grid.visible = true;
    }
}

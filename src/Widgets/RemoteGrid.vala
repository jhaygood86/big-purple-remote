public class RemoteGrid : Gtk.Grid {

    private RokuManager roku_manager;
    private Gtk.ComboBox device_list;
    private string current_usn;
    private GLib.Settings settings;
    private Gee.HashMap<string,Gtk.Button> button_map;
    private Gtk.Image channel_image;
    private Gtk.Label channel_name_label;

    construct {
        button_map = new Gee.HashMap<string,Gtk.Button>();

        settings = new GLib.Settings ("io.github.jhaygood86.big-purple-remote");

        device_list = new Gtk.ComboBox ();
        device_list.hexpand = true;
        device_list.halign = Gtk.Align.CENTER;

        var device_list_style_context = device_list.get_style_context ();
        device_list_style_context.add_class("roku-device-list");

        attach(device_list, 0, 0, 3);

        roku_manager = new RokuManager ();

        roku_manager.device_added.connect(device_added);
	    device_list.set_model(roku_manager.roku_devices);

	    var renderer = new Gtk.CellRendererText();
	    device_list.pack_start(renderer,true);
	    device_list.add_attribute(renderer,"text",0);

	    device_list.set_id_column(1);

	    device_list.active = 0;

	    device_list.changed.connect(device_list_changed);

        roku_manager.find_devices();

        channel_image = new Gtk.Image ();

        var channel_image_style_context = channel_image.get_style_context ();
        channel_image_style_context.add_class("channel-image");

        attach(channel_image, 0, 1, 1);

        channel_name_label = new Gtk.Label ("") {
            halign = Gtk.Align.START
        };

        channel_name_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);
        channel_name_label.visible = true;

        attach(channel_name_label, 1, 1, 2, 1);

        create_and_attach_buttons ();
    }

    private void create_and_attach_buttons () {
        create_and_attach_button(_("Power"), "system-shutdown-symbolic", "PowerToggle", 3, 1, 1);

        create_and_attach_button(_("Back"), "edit-undo-symbolic", "Back", 4, 0, 1);
        create_and_attach_button(_("Settings"), "open-menu-symbolic", "Info", 4, 1, 1);
        create_and_attach_button(_("Home"), "user-home-symbolic", "Home", 4, 2, 1);

        var dpad_grid = new Gtk.Grid () {
            hexpand = false,
            halign = Gtk.Align.CENTER
        };

        var up_btn = create_and_attach_button(null, "go-up-symbolic", "Up", 0, 1, 1, dpad_grid);

        var left_btn = create_and_attach_button(null, "go-previous-symbolic", "Left", 1, 0, 1, dpad_grid);
        var ok_btn = create_and_attach_button(_("OK"), null, "OK", 1, 1, 1, dpad_grid);
        var right_btn = create_and_attach_button(null, "go-next-symbolic", "Right", 1, 2, 1, dpad_grid);

        var down_btn = create_and_attach_button(null, "go-down-symbolic", "Down", 2, 1, 1, dpad_grid);

        attach (dpad_grid, 0, 5, 3);

        create_and_attach_button(_("Rewind"), "media-seek-backward-symbolic", "Rev", 6, 0, 1);
        create_and_attach_button(_("Pause"), "media-playback-pause-symbolic", "Pause", 6, 1, 1);
        create_and_attach_button(_("Play"), "media-playback-start-symbolic", "Play", 6, 1, 1).visible = false;
        create_and_attach_button(_("Fast Forward"), "media-seek-forward-symbolic", "Fwd", 6, 2, 1);

        set_dpad_style (up_btn);
        set_dpad_style (left_btn);
        set_dpad_style (ok_btn);
        set_dpad_style (right_btn);
        set_dpad_style (down_btn);
    }

    private void set_dpad_style (Gtk.Button button) {
        var button_style_context = button.get_style_context ();
        button_style_context.add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
    }

    private Gtk.Button create_and_attach_button(string? label, string? icon_name, string button_name, int row, int column, int column_span, Gtk.Grid? parent_grid = null) {

        if (parent_grid == null) {
            parent_grid = this;
        }

        Gtk.Button button;

        string button_label = label;

        var icon_size = Gtk.IconSize.BUTTON;

        if (label == null) {
            button_label = "";
            icon_size = Gtk.IconSize.DIALOG;
        }

        button = new Gtk.Button.with_label (button_label);

        if (icon_name != null) {
            button.image = new Gtk.Image.from_icon_name (icon_name, icon_size);
            button.always_show_image = true;
        }

        button.focus_on_click = false;
        button.sensitive = false;

        button.clicked.connect(() => {
            press_roku_key(button_name);
        });

        var button_style_context = button.get_style_context();

        var button_class_name = "purple-button-" + button_name.down();

        button_style_context.add_class (button_class_name);
        button_style_context.add_class ("purple-button-generic");

        parent_grid.attach (button, column, row, column_span);

        button_map[button_name] = button;

        return button;
    }

	private void device_list_changed(Gtk.ComboBox device_list){
	    settings.set_string("last-used-device-usn",device_list.active_id);

        foreach(var button in button_map.values){
            button.sensitive = true;
        }

        var roku_device = roku_manager.set_active_device(device_list.active_id);

        var power_button = button_map["PowerToggle"];
        power_button.visible = roku_device.is_television;

        set_channel_name (roku_device);
        set_channel_icon (roku_device);
	}

	private void device_added (string usn){
        string current_usn = settings.get_string("last-used-device-usn");

        if(current_usn == usn && device_list.active_id == null){
            device_list.active_id = usn;
        }

        var roku_device = roku_manager.get_device(device_list.active_id);

        roku_device.play_state_changed.connect((is_playing) => {
            if(device_list.active_id == roku_device.usn){

                var play_button = button_map["Play"];
                var pause_button = button_map["Pause"];

                if (is_playing) {
                    play_button.visible = false;
                    pause_button.visible = true;
                } else {
                    play_button.visible = true;
                    pause_button.visible = false;
                }
            }
        });

        roku_device.notify["icon-pixbuf"].connect(() => {

            print("icon changed");

            if(device_list.active_id == roku_device.usn){
                set_channel_icon(roku_device);
            }
        });

        roku_device.notify["channel-name"].connect(() => {
            if(device_list.active_id == roku_device.usn){
                set_channel_name (roku_device);
            }
        });
	}

	private void set_channel_icon (RokuDevice roku_device) {
        if (roku_device.icon_pixbuf != null) {
            channel_image.pixbuf = roku_device.icon_pixbuf;
        } else {
            var icon_theme = Gtk.IconTheme.get_default ();
            var icon_pixbuf = icon_theme.load_icon("video-display-tv", 128, Gtk.IconLookupFlags.FORCE_REGULAR);
            var target_height = (int)((125 / (double)icon_pixbuf.width) * icon_pixbuf.height);
            channel_image.pixbuf = icon_pixbuf.scale_simple(125, target_height, Gdk.InterpType.BILINEAR);
        }
	}

	private void set_channel_name (RokuDevice roku_device) {
	    if (roku_device.channel_name != null) {
	        channel_name_label.label = roku_device.channel_name;
	    } else {
	        channel_name_label.label = roku_device.model_name;
	    }
	}

	private void press_roku_key(string key){
        var roku_device = roku_manager.get_device(device_list.active_id);
	    roku_device.press_key(key);
	}
}

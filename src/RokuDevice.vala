public class RokuDevice : Object {

    private uint media_player_source;

    private Soup.Session _session;

    public RokuDevice(string usn,GLib.List<string> locations){
        this.usn = usn;
        this.location = locations.nth_data(0);
        this.is_active = false;
        this.icon_pixbuf = null;

        _session = new Soup.Session ();

        this.notify["is-active"].connect(() => {

            load_media_player ();

            if (is_active) {
                media_player_source = Timeout.add_full(Priority.DEFAULT,10000,on_mediaplayer_timer);
            } else {
                Source.remove(media_player_source);
            }
        });

        this.notify["channel-id"].connect(load_channel_icon);
    }

    public string usn { get; private set; }
    public string location { get; private set; }
    public string name { get; private set; }
    public string model_name { get; private set; }
    public string application_name { get; private set; }
    public bool is_television { get; private set; }
    public bool is_power_on { get; private set; }
    public bool is_playing { get; private set; }
    public bool is_active { get; set; }
    public string channel_name { get; set; }
    public int channel_id { get; set; }
    public Gdk.Pixbuf? icon_pixbuf { get; set; }

    public signal void play_state_changed (bool is_playing);
    public signal void device_info_loaded ();

    public async void load_device_info(){
        var device_info_url = "%squery/device-info".printf(_location);

        var response_data = yield http_get_string_async (device_info_url);

        if (response_data == null) {
            return;
        }

        print ("device info:\n%s\n", response_data);

        var document = new GXml.Document.from_string (response_data);

        name = get_node_value(document,"friendly-device-name");

        var power_mode = get_node_value(document,"power-mode");

        if (power_mode == "Ready") {
            is_power_on = false;
        }

        if (power_mode == "PowerOn") {
            is_power_on = true;
        }

        var television = get_node_value(document,"is-tv");

        is_television = false;

        if (television == "true"){
            is_television = true;
        }

        model_name = get_node_value(document,"friendly-model-name");

        device_info_loaded ();
    }

    private void load_media_player() {
        var media_player_info_url = "%squery/media-player".printf(location);

        var message = new Soup.Message("GET",media_player_info_url);

        print("sending message for %s to %s\n", usn, media_player_info_url);

        _session.queue_message(message, (sess,mess) => {

            print("received message for %s, status code: %u\n",usn,mess.status_code);

            var is_successful = mess.status_code >= 200 && mess.status_code < 300;

            if (!is_successful) {
                print ("did not receive success status. not proceeding");
                return;
            }

            var response_xml = (string) mess.response_body.data;
            print ("%s\n",response_xml);

            var memory_input_stream = new MemoryInputStream.from_data(mess.response_body.data);
            var document = new GXml.Document.from_stream(memory_input_stream);

            var player_element = document.query_selector("player");
            var state_attribute = player_element.get_attribute("state");

            print("play state: %s\n",state_attribute);

            var current_state = is_playing;

            if(state_attribute == "play") {
                is_playing = true;
            } else {
                is_playing = false;
            }

            if (current_state != is_playing) {
                play_state_changed(is_playing);
            }

            var plugin_element = document.query_selector("plugin");

            if( plugin_element != null) {

                print("plugin element is not null\n");

                channel_name = plugin_element.get_attribute("name");
                channel_id = int.parse(plugin_element.get_attribute("id"));

                print("channel name: %s\n",channel_name);
                print("channel id: %d\n",channel_id);

            } else {
                channel_name = null;
                channel_id = 0;
            }
        });
    }

    private void load_channel_icon () {

        print ("load channel icon for channel id: %d",channel_id);

        if(channel_id == 0) {
            this.icon_pixbuf = null;
            return;
        }

        var channel_icon_url = "%squery/icon/%d".printf(location,channel_id);

        var message = new Soup.Message("GET",channel_icon_url);

        _session.queue_message(message,(sess,mess) => {
            var stream = new MemoryInputStream.from_data(mess.response_body.data);

            var pixbuf = new Gdk.Pixbuf.from_stream (stream);

            print("size: %d x %d\n",pixbuf.width,pixbuf.height);

            var target_height = (int)((125 / (double)pixbuf.width) * pixbuf.height);

            print("target height %d\n",target_height);

            icon_pixbuf = pixbuf.scale_simple(125, target_height, Gdk.InterpType.BILINEAR);
        });
    }

    private bool on_mediaplayer_timer () {
        load_media_player ();
        return GLib.Source.CONTINUE;
    }

    private string get_node_value(GXml.Document document, string selector) {
        var node = document.query_selector(selector);
        return node.text_content;
    }

    public void press_key(string button){

        string button_to_send;

        switch(button){
            case "PowerToggle":
                load_device_info ();

                if(is_power_on) {
                    button_to_send = "PowerOff";
                    is_playing = false;
                } else {
                    button_to_send = "PowerOn";
                    is_playing = true;
                }

                play_state_changed(is_playing);

                break;
            case "OK":
                button_to_send = "Select";
                break;
            default:
                button_to_send = button;
                break;
        }

        send_key(button_to_send);
    }

    private void send_key(string button){


        var keypress_url = "%skeypress/%s".printf(_location,button);

        var session = new Soup.Session();
        var message = new Soup.Message("POST",keypress_url);

        session.queue_message(message, null);
    }

    public void load_current_application(){
        var app_info_url = "%squery/active-app".printf(_location);

        var session = new Soup.Session();
        var message = new Soup.Message("GET",app_info_url);

        session.queue_message(message,current_application_callback);
    }

    private void current_application_callback(Soup.Session session, Soup.Message message){
        var memory_input_stream = new MemoryInputStream.from_data(message.response_body.data);

        var document = new GXml.Document.from_stream(memory_input_stream);
        var app_node = document.query_selector("app");

        application_name = app_node.text_content;
    }

    private async string? http_get_string_async (string url) throws Gee.FutureError {

        print ("fetching url %s\n", url);

        var message = new Soup.Message ("GET", url);

        var message_promise = new Gee.Promise<string?> ();

        _session.queue_message(message, (sess,mess) => {

            print("received message for %s, status code: %u\n",usn,mess.status_code);

            var is_successful = mess.status_code >= 200 && mess.status_code < 300;

            if (!is_successful) {
                print ("did not receive success status. not proceeding\n");

                message_promise.set_value (null);

                return;
            }

            var response_data = (string)mess.response_body.data;

            print ("received response: %s\n", response_data);

            message_promise.set_value (response_data);
        });

        var value = yield message_promise.future.wait_async ();

        print ("future resolved\n");

        return value;
    }
}

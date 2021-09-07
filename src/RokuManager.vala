public class RokuManager : Object {
    private GUPnP.ContextManager context_manager;
    private GUPnP.ControlPoint control_point;

    private Gee.HashMap<string,RokuDevice> roku_device_map;
    private Gee.HashMap<string,Gtk.TreeIter?> roku_device_row_map;

    private Gtk.ListStore _roku_devices;

    public signal void device_added (string usn);
    public signal void device_removed ();

    public RokuManager(){
        roku_device_map = new Gee.HashMap<string,RokuDevice>();
        roku_device_row_map = new Gee.HashMap<string,Gtk.TreeIter?>();

        _roku_devices = new Gtk.ListStore(2, typeof(string), typeof(string));
    }

    public Gtk.ListStore roku_devices {
        get {
            return _roku_devices;
        }
    }

    public void find_devices(){
        context_manager = GUPnP.ContextManager.create(0);
        context_manager.context_available.connect(context_available);
    }

    public RokuDevice get_device(string usn){
        return roku_device_map.get(usn);
    }

    public RokuDevice set_active_device(string usn) {

        print("setting device active: %s\n",usn);

        var device = roku_device_map[usn];

        foreach(var other_device in roku_device_map.values) {
            if(other_device != device){
                other_device.is_active = false;
            }
        }

        device.is_active = true;

        return device;
    }

    private void context_available(GUPnP.ContextManager context_manager, GUPnP.Context context){
        control_point = new GUPnP.ControlPoint(context,"roku:ecp");
        control_point.resource_available.connect(resource_available_cb);
        control_point.resource_unavailable.connect(resource_unavailable_cb);

        control_point.set_active(true);

        context_manager.manage_control_point(control_point);
    }

    private void resource_available_cb(GSSDP.ResourceBrowser resource_browser, string usn, GLib.List<string> locations){

        print ("found device: %s\n", usn);

        var roku_device = new RokuDevice(usn,locations);
        roku_device_map.set(usn,roku_device);

        Gtk.TreeIter? device_row;

        _roku_devices.insert_with_values(out device_row,-1,0,roku_device.name,1,roku_device.usn);
        roku_device_row_map.set(usn,device_row);

        device_added (usn);
    }

    private void resource_unavailable_cb(GSSDP.ResourceBrowser resource_browser, string usn){
        roku_device_map.unset(usn);

        var tree_iter = roku_device_row_map.get(usn);
        _roku_devices.remove(ref tree_iter);

        roku_device_row_map.unset(usn);

        device_removed ();
    }
}

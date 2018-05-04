
using Gtk;
using Soup;

namespace Peek.Ui {

  [GtkTemplate (ui = "/com/uploadedlobster/peek/share-dialog.ui")]
  class ShareDialog : Window {
  private static Gtk.Window? instance;

    public static Gtk.Window present_single_instance (Gtk.Window main_window) {
      if (instance == null) {
        instance = new ShareDialog ();
        instance.delete_event.connect ((event) => {
          instance = null;
          main_window.set_keep_above (true);
          return false;
        });
      }

      instance.transient_for = main_window;
      main_window.set_keep_above (false);
      instance.present ();
      return instance;
    }

    public static string file { get; set; }
    public static string file_type { get; set; }

    public static void filename (string out_file) {
        file=out_file;
	}

    public static void get_file_ext (string file_ext) {
        file_type=file_ext;
	}

    [GtkChild]
    private Gtk.Image check_1;

    [GtkChild]
    private Gtk.Image check_2;

    [GtkChild]
    private Gtk.ListBox options_list;

    [GtkChild]
    private Gtk.ListBoxRow row_1;

    [GtkChild]
    private Gtk.ListBoxRow row_2;

    [GtkCallback]
    private void on_options_list_row_selected () {
      var selection = options_list.get_selected_row ();
      if(file_type == "webm" || file_type == "mp4"){
          row_1.set_selectable(false);
          check_2.show();
          check_1.hide();
          options_list.select_row(row_2);
          debug("WebM and Mp4 files are not supported with in imgur upload api");
      }else {
          row_1.set_selectable(true);
          check_1.show();
          if (selection == row_1) {
            check_2.hide();
         }else if (selection == row_2 ){
            check_2.show();
            check_1.hide();
            }
      }


    }
    [GtkCallback]
    private void on_confirm_option_clicked() {
      if (options_list.get_selected_row () == row_1) {
        string image_uri = file;
        string image=image_uri.replace("%20"," ");
        debug(image);
        uint8[] data;

        try {
            GLib.FileUtils.get_data(image.split("://")[1], out data);
        } catch (GLib.FileError e) {
            warning(e.message);
        }

        string image_test =GLib.Base64.encode(data);
        var mpart = new Multipart(FORM_MIME_TYPE_MULTIPART);
        var session = new Soup.Session ();
        mpart.append_form_string("image", image_test);
        var message = Soup.Form.request_new_from_multipart("https://api.imgur.com/3/image",mpart);
        message.request_headers.append("Authorization", "Client-ID bfb3ac58837a0d0");
        session.send_message(message);
        var response = (string) message.response_body.data;
        debug(response);
        try {
          var parser = new Json.Parser ();
          parser.load_from_data (response, -1);
          var root_object = parser.get_root ().get_object ();
          string link = root_object.get_object_member ("data")
                                   .get_string_member ("link");
          debug(link);
#if HAS_GTK_SHOW_URI_ON_WINDOW
          Gtk.show_uri_on_window(instance, link, Gdk.CURRENT_TIME);
#else
          Gtk.show_uri(null, link, Gdk.CURRENT_TIME);
#endif


         this.close();
       }catch(Error e) {
          error("%s", e.message);
            }
        }
    }
    [GtkCallback]
    private void on_sharing_cancel_clicked() {
      this.close ();
        }
    }
    }

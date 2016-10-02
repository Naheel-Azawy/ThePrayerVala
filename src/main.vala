using Gtk;
using Utils;
using TH;
using Prefs;
using Strings;
using Hijri;

string[] prayerTimes;
static PrayCard[] pray_cards;

// colors --------------------

const string yellow = "#FFC107";
const string dark = "#333333";
const string light = "#dddddd";
const string black = "#000000";
const string white = "#ffffff";
const string bg_dark = "#222222";
const string bg_light = "#eeeeee";

string card_color;
string bg_color;
string font_color;

Window window_main;

static void main (string[] args) {

	var d = new DateTime.now_local();
	var v = to_hijri_dt (d);
	print(@"$(v[0]) - $(v[1]) - $(v[2]) ");

	update_main (true);

        prayerTimes = get_times ();

        // --------------------------

	Gtk.init (ref args);

	window_main = new Window ();
	window_main.title = app_name;
	//window_main.set_default_size (320, 100);
	window_main.destroy.connect (() => {
		GLib.Process.exit (0);
	});

	var vbox_main = new Box (Orientation.VERTICAL, 0);

	pray_cards = new PrayCard[prayerTimes.length];
        for (int i = 0; i < prayerTimes.length; i++) {
                pray_cards [i] = new PrayCard (i);
                vbox_main.add (pray_cards [i]);
        }

        //var hijri_lbl = new Label ()

	var wHolder = new Label ("");
	wHolder.width_request = 320;
	vbox_main.add (wHolder);

	window_main.add (vbox_main);

	try {
	    window_main.icon = new Gdk.Pixbuf.from_file ("ic_launcher.png");
	} catch (Error e) {
	    stderr.printf ("Could not load application icon: %s\n", e.message);
	}

	window_main.show_all ();

        window_main.set_resizable (false);

	var update_loop = new GLib.MainLoop ();
	update_main_thread.begin ((obj, async_res) => {
		update_loop.quit ();
	});
	update_loop.run ();

	Gtk.main();

}

void update_main (bool b = false) {
	P.init ();
	initStrings ();

	if (P.isLight) {
		card_color = light;
		bg_color = bg_light;
		font_color = black;
	} else {
		card_color = dark;
		bg_color = bg_dark;
		font_color = white;
	}

	if (window_main != null) {
		set_bg_color (window_main, bg_color);
		foreach (PrayCard p in pray_cards) p.updateCard ();
	}
	if (!b) {
		send_notif ();
		pray_cards [get_next_position_pray_only ()].activateCard ();
	}
	var dt = new DateTime.now_local ();
	if (dt.get_hour () == 0 && dt.get_minute () == 0) {
		get_times ();
	}
}

public async void nap (uint interval, int priority = GLib.Priority.DEFAULT) {
	GLib.Timeout.add (interval, () => {
		nap.callback ();
		return false;
	}, priority);
	yield;
}

private async void update_main_thread () {
	update_main ();
	DateTime t = new DateTime.now_local ();
	yield nap (60000 - ( t.get_microsecond () /1000 + t.get_second () *1000 ));
	while (true) {
		yield nap (60000);
		update_main ();
	}
}

class PrayCard : Button {

	public bool active = false;
	public int i;

	private Label txt;
	private Label time;
	private Label rem;
	private Box vBox;

	public PrayCard (int i, bool active = false) {
		this.i = i;
		this.active = active;

		margin = 10;
		vBox = new Box (Orientation.VERTICAL, 0);
		var hBox = new Box (Orientation.HORIZONTAL, 0);
		hBox.homogeneous = true;
		vBox.homogeneous = true;

		time = new Label (TH.twelveHourMode(prayerTimes[i]));
		hBox.add (time);
		txt = new Label (pray_names[i]);
		hBox.add (txt);

		vBox.add (hBox);

		rem = new Label ("");
		vBox.add (rem);

		add (vBox);

		colorize ();

		clicked.connect (activateCard);
	}

	public void updateCard () {
		time.label = twelveHourMode(prayerTimes[i]);
		txt.label = pray_names[i];
		colorize ();
		if (active) rem.label = get_remaining_time (i);
	}

	public void activateCard () {
		for (int j = 0; j<pray_cards.length; j++) {
			if (this == pray_cards [j]) {
				pray_cards [j].active = true;
				pray_cards [j].rem.show ();
			} else {
				pray_cards [j].active = false;
				pray_cards [j].rem.hide ();
			}
			pray_cards [j].colorize ();
		}
		rem.label = get_remaining_time (i);
		update_main (true);
	}

	private void colorize () {
		if (active) {
			set_bg_color (this, yellow);
			set_color (txt, black);
			set_color (time, black);
			set_color (rem, black);
		} else {
			set_bg_color (this, card_color);
			set_color (txt, font_color);
			set_color (time, font_color);
			set_color (rem, font_color);
		}
	}

}

void set_color (Widget w, string color) {
	var css = @"* { color: $color; text-shadow: none; }";
	var p = new Gtk.CssProvider ();
	try {
		p.load_from_data (css, css.length);
		w.get_style_context ().add_provider (p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	} catch (Error err) {
		stderr.printf ("Could not set color: %s\n", err.message);
	}
}

void set_bg_color (Widget w, string color) {
	var css = @"* { background: $color; }";
	var p = new Gtk.CssProvider ();
	try {
		p.load_from_data (css, css.length);
		w.get_style_context ().add_provider (p, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
	} catch (Error err) {
		stderr.printf ("Could not set background: %s\n", err.message);
	}
}

//valac --ccode --pkg gtk+-3.0 *.vala && gcc -Wall *.c -lm `pkg-config --cflags --libs glib-2.0` `pkg-config --cflags --libs gtk+-3.0` `pkg-config --cflags --libs gee-1.0` && rm *.c && ./a.out

/*static void main (string[] args) { // testing main

	P.init ();
	initStrings ();

	get_times ();
	prayerTimes = _times_iq;
	//print ("\n\n" + prayerTimes.length.to_string () + "\n\n");
	for (int i =0; i<prayerTimes.length; i++)
		print (TH.twelveHourMode (prayerTimes[i] )+ "\t" + get_remaining_time (i) + "\n");

	Gtk.init (ref args);

	var window_main = new Window ();
	window_main.title = "test";
	window_main.set_default_size (320, 100);
	window_main.destroy.connect (() => {
		GLib.Process.exit (0);
	});

	var b = new Button ();
	b.label = "test";
	b.margin = 10;
	b.override_background_color (Gtk.StateFlags.NORMAL, color (yellow));

	window_main.add (b);

	window_main.show_all ();
	Gtk.main();

}*/

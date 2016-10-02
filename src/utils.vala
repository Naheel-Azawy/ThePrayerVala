using Strings;
using Prefs;
using TH;
using Notify;

namespace Utils {

	string[] _times = null;
	string[] _times_iq = null;

	string[] get_times () {

		_times = new string[6];
		_times_iq = new string[11];

		PrayTime prayers = new PrayTime();

		prayers.timeFormat = PrayTime.TIME_24;
		prayers.calcMethod = calc_method_str_to_int (P.calc_method);
		prayers.asrJuristic = asr_juristic_str_to_int (P.asr_juristic);
		prayers.adjustHighLats = high_lats_str_to_int (P.high_lats_method);

		var cal = new DateTime.now_local ();

		string[] prayerTimes = prayers.getPrayerTimes(cal, P.latitude, P.longitude, P.timezone);

		_times[0] = prayerTimes[0];
		_times[1] = prayerTimes[1];
		_times[2] = prayerTimes[2];
		_times[3] = prayerTimes[3];
		_times[4] = prayerTimes[5];
		_times[5] = prayerTimes[6];

		_times_iq[0] = prayerTimes[0];
		_times_iq[1] = TH.sec2Time (TH.time2Sec (prayerTimes[0]) + P.iqamaFajr *60);
		_times_iq[2] = prayerTimes[1];
		_times_iq[3] = prayerTimes[2];
		_times_iq[4] = TH.sec2Time (TH.time2Sec (prayerTimes[2]) + P.iqamaDuhr *60);
		_times_iq[5] = prayerTimes[3];
		_times_iq[6] = TH.sec2Time (TH.time2Sec (prayerTimes[3]) + P.iqamaAsr *60);
		_times_iq[7] = prayerTimes[5];
		_times_iq[8] = TH.sec2Time (TH.time2Sec (prayerTimes[5]) + P.iqamaMagrib *60);
		_times_iq[9] = prayerTimes[6];
		_times_iq[10] = TH.sec2Time (TH.time2Sec (prayerTimes[6]) + P.iqamaIsha *60);

		return _times;
	}

	string get_remaining_time (int position) {

		if (_times == null || _times_iq == null) get_times ();

		string rem_word = remainingTimeHintString;

		position = position_no_to_iq (position);

		int now = now_in_sec ();
		int next_position = get_next_position_iq ();

		int next = time2Sec (_times_iq [next_position]);
		int wanted = time2Sec (_times_iq [position]);
		bool wanted_is_next = position_iq_to_no (next_position) == position_iq_to_no (position);
		int time = wanted_is_next ? next : wanted;
		int diff = time - now;
		if (diff == 0) {
			return is_iqama_time (next_position) ? prayTimeEnteredFullIq : prayTimeEnteredFull;
		} else if (diff < 0) {
			diff = -diff;
			rem_word = remainingTimePasssedHintString;
			if (next_position == 0 && position == 0) {
				diff = time + 24*3600 - now;
				rem_word = remainingTimeHintString;
			}
		} else if (is_iqama_time (next_position) && wanted_is_next) {
			rem_word = remainingTimeHintString + " " + remainingTimeHintToIqamaString;
		}

		return P.isAr ? rem_word + " " + secondsToTimeInWords(diff) :
				TH.secondsToTimeInWords(diff) + " " + rem_word;

	}

	bool is_iqama_time (int next_position) {
		return next_position == 1 || next_position == 4 || next_position == 6 ||
					next_position == 8 || next_position == 10;
	}

	int get_next_position_pray_only () {
		return position_iq_to_no (get_next_position_iq ());
	}

	int get_next_position_iq () {

		if (_times == null || _times_iq == null) get_times ();

		int time_sec = now_in_sec ();
		int next = 0;
		int least = -1;
		for (int i = 0; i<_times_iq.length; i++) {
			int t = time2Sec (_times_iq [i]);
			if (t - time_sec < 0) continue;
			if (time2Sec (_times_iq [i]) < least || least <0) {
				least = time2Sec (_times_iq [i]);
				next = i;
			}
		}

		return next;

	}

	bool is_now (int position) {
		int time_sec = now_in_sec ();
		int next = time2Sec (_times [position]);
/*
		print ("\n\n");
		foreach (string s in _times)
			print (s + "\n");
		print ("\n\n");
*/
		return (next - time_sec) == 0;
	}

	int position_iq_to_no (int i) {
		switch (i) {
			case 0: return 0;  // fajr
			case 1: return 0;  // fajr iq
			case 2: return 1;  // sunrise
			case 3: return 2;  // duhr
			case 4: return 2;  // duhr iq
			case 5: return 3;  // asr
			case 6: return 3;  // asr iq
			case 7: return 4;  // magrib
			case 8: return 4;  // magrib iq
			case 9: return 5;  // isha
			case 10: return 5; // isha iq
			default: return 0;
		}
	}

	int position_no_to_iq (int i) {
		switch (i) {
			case 0: return 0; // fajr
			case 1: return 2; // sunrise
			case 2: return 3; // duhr
			case 3: return 5; // asr
			case 4: return 7; // magrib
			case 5: return 9; // isha
			default: return 0;
		}
	}

	//const string TEST_TIME = "20:10";

	int now_in_sec () {
		var now = new DateTime.now_local ();
		return now.get_hour () * 3600 + now.get_minute () * 60;
		//return TH.time2Sec (TEST_TIME);
	}

	void send_notif (string s = "no") {

		if (s == "no") {
			for (int i =0; i<7; i++)
				if (is_now (i)) {
					s = pray_names[i];
					break;
				}
		}

		if (s == "no") return;

		Notify.init (app_name);
		try {
			Notify.Notification notification = new Notify.Notification (s, prayTimeEntered + " " + s, null);
			notification.set_image_from_pixbuf (new Gdk.Pixbuf.from_file ("ic_launcher.png"));
			notification.show ();
		} catch (Error e) {
			error ("Error: %s", e.message);
		}

		/*string dir = GLib.Environment.get_current_dir ().to_string ();
		var str = @"notify-send -i $dir/ic_launcher.png \"$s\" \"$prayTimeEntered $s\"";

		try {
			Process.spawn_command_line_sync (str);
		} catch (SpawnError e) {
			stdout.printf ("Error: %s\n", e.message);
		}*/

	}

	public static int calc_method_str_to_int (string s) {
		switch (s.down ()) {
			case "karachi":	return 0;
			case "isna":	return 1;
			case "mwl":	return 2;
			case "makkah":	return 3;
			case "egypt":	return 4;
			case "qatar":	return 6;
			default:	return 3;
		}
	}

	public static int asr_juristic_str_to_int (string s) {
		switch (s.down ()) {
			case "shafii":	return 0;
			case "hanafi":	return 1;
			default:	return 0;
		}
	}

	public static int high_lats_str_to_int (string s) {
		switch (s.down ()) {
			case "none":		return 0;
			case "midnight":	return 1;
			case "oneseventh":	return 2;
			case "anglebased":	return 3;
			default:		return 3;
		}
	}

}

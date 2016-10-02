using Prefs;

namespace Strings {

	public static string[] pray_names;
	public static string app_name;
	public static string remainingTimeHintString;
	public static string remainingTimePasssedHintString;
	public static string remainingTimeHintToPrayString;
	public static string remainingTimeHintToString;
	public static string remainingTimeHintToIqamaString;
	public static string remainingTimeHintToImsakString;
	public static string prayTimeEntered;
	public static string prayTimeEnteredFull;
	public static string prayTimeEnteredFullIq;
	public static string iqamaString;
	public static string fajrTxt;
	public static string sunriseTxt;
	public static string duhrTxt;
	public static string jumuahTxt;
	public static string asrTxt;
	public static string magribTxt;
	public static string ishaTxt;


	public static void initStrings() {
		if (P.isAr) {
			app_name = "الصلاة";
			pray_names = new string[] {"الفجر", "الشروق", "الظهر", "العصر", "المغرب", "العشاء"};
			remainingTimeHintString = "المتبقي";
			remainingTimePasssedHintString = "مرت";
			remainingTimeHintToPrayString = "لصلاة";
			remainingTimeHintToString = "إلى";
			remainingTimeHintToIqamaString = "للإقامة";
			remainingTimeHintToImsakString = "للإمساك";
			prayTimeEntered = "دخل وقت";
			prayTimeEnteredFull = "دخل وقت الصلاة";
			prayTimeEnteredFullIq = "دخل وقت الإقامة";
			iqamaString = "إقامة";
			fajrTxt = "الفجر";
			sunriseTxt = "الشروق";
			duhrTxt = "الظهر";
			jumuahTxt = "الجمعة";
			asrTxt = "العصر";
			magribTxt = "المغرب";
			ishaTxt = "العشاء";
		} else {
			app_name = "The Prayer";
			pray_names = new string[] {"Fajr", "Sunrise", "Duhr", "Asr", "Maghrib", "Isha"};
			remainingTimeHintString = "remaining";
			remainingTimePasssedHintString = "passed";
			remainingTimeHintToPrayString = "to";
			remainingTimeHintToString = "to";
			remainingTimeHintToIqamaString = "to iqama";
			remainingTimeHintToImsakString = "to imsak";
			prayTimeEntered = "It's time for";
			prayTimeEnteredFull = "It's praying time";
			prayTimeEnteredFullIq = "It's iqama time";
			iqamaString = "iqama";
			fajrTxt = "Fajr";
			sunriseTxt = "Sunrise";
			duhrTxt = "Duhr";
			jumuahTxt = "Jumuah";
			asrTxt = "Asr";
			magribTxt = "Magrib";
			ishaTxt = "Isha";
		}

		if (new DateTime.now_local ().get_day_of_week () == 5) {
			duhrTxt = jumuahTxt;
			pray_names [2] = jumuahTxt;
		}
	}

}

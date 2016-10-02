using Prefs;

namespace TH {
    // Time Helper

    int[] sec2TimeArr(int timeInSec) {
        int s = timeInSec % 60;
        int totalMinutes = timeInSec / 60;
        int m = totalMinutes % 60;
        int h = totalMinutes / 60;
        return new int[]{s, m, h};
    }

    int time2Sec(string time) {
        string[] arr = time.split(":");
        return int.parse(arr[0]) * 3600 + int.parse(arr[1]) * 60;
    }

    string sec2Time(int sec) {
        int[] arr = sec2TimeArr(sec);
        return ((arr[2] < 10) ? "0" + arr[2].to_string () : arr[2].to_string ()) +
        	":" + ((arr[1] < 10) ? "0" + arr[1].to_string () : arr[1].to_string ());
    }

    int[] timeStr2Arr(string time) {
        return sec2TimeArr(time2Sec(time));
    }

    string secondsToTimeInWords(int time) {

        string stringHour = "ساعة";
        string stringHours = "ساعات";
        string string2Hours = "ساعتان";

        string stringHourEn = "hr";

        string stringMinute = "دقيقة";
        string stringMinutes = "دقائق";
        string string2Minutes = "دقيقتان";

        string stringMinuteEn = "min";

        string and = " و ";
        string andEn = " and ";

        int hours = time / 3600;
        time = time - (hours * 3600);
        int minutes = time / 60;

        string hoursstring = hours.to_string ();
        string minutesstring = minutes.to_string ();

        if (P.isAr) {
            if (minutes > 10) {
                stringMinutes = stringMinute;
            }
            if (hours > 10) {
                stringHours = stringHour;
            }
            if (minutes == 1) {
                stringMinutes = stringMinute;
                minutesstring = "";
            }
            if (hours == 1) {
                stringHours = stringHour;
                hoursstring = "";
            }
            if (minutes == 2) {
                stringMinutes = string2Minutes;
                minutesstring = "";
            }
            if (hours == 2) {
                stringHours = string2Hours;
                hoursstring = "";
            }
            if (minutes == 0) {
                stringMinutes = "";
                minutesstring = "";
                and = "";
            }
            if (hours == 0) {
                stringHours = "";
                hoursstring = "";
                and = "";
            }
        } else {

            stringHours = stringHourEn;
            stringMinutes = stringMinuteEn;
            and = andEn;

            if (minutes == 1) {
                stringMinutes = stringMinuteEn;
            }
            if (hours == 1) {
                stringHours = stringHourEn;
            }
            if (minutes == 0) {
                stringMinutes = "";
                minutesstring = "";
                and = "";
            }
            if (hours == 0) {
                stringHours = "";
                hoursstring = "";
                and = "";
            }
        }

        string remTime = hoursstring + (hoursstring == "" ? "" : " ") +
        	stringHours + and + minutesstring + (minutesstring == "" ? "" : " ") + stringMinutes;

        return remTime;
    }

    string twelveHourMode(string time) {

        if (P.is24HourFormat)
            return time;
        else {
            string[] t = time.split(":");
            string amPm = "AM";
            int hours = int.parse(t[0]);
            if (hours > 12) {
                hours = hours - 12;
                amPm = "PM";
            }
            string hoursstring = hours.to_string ();
            if (hours < 10)
                hoursstring = "0" + hours.to_string ();

            string beforeAmPmLang = hoursstring + ":" + t[1] + " " + amPm;

            string result;
            if (P.isAr)
                result = beforeAmPmLang.replace("AM", "ص").replace("PM", " م ");
            else
                result = beforeAmPmLang;

            return result;
        }
    }

}

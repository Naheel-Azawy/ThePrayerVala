public class PrayTime {

    // ------------------------ Constants --------------------------

    // Calculation Methods
    public static const int KARACHI = 0; // University of Islamic Sciences, Karachi
    public static const int ISNA = 1; // Islamic Society of North America (ISNA)
    public static const int MWL = 2; // Muslim World League (MWL)
    public static const int MAKKAH = 3; // Umm al-Qura, Makkah
    public static const int EGYPT = 4; // Egyptian General Authority of Survey
    public static const int CUSTOM = 5; // Custom Setting
    public static const int QATAR = 6; // Qatar Calendar House

    // Juristic Methods
    public static const int SHAFII = 0; // Shafii (standard)
    public static const int HANAFI = 1; // Hanafi

    // Adjusting Methods for Higher Latitudes
    public static const int NONE = 0; // No adjustment
    public static const int MIDNIGHT = 1; // middle of night
    public static const int ONE_SEVENTH = 2; // 1/7th of night
    public static const int ANGLE_BASED = 3; // angle/60th of night

    // Time Formats
    public static const int TIME_24 = 0; // 24-hour format
    public static const int TIME_12 = 1; // 12-hour format
    public static const int TIME_12_NS = 2; // 12-hour format with no suffix
    public static const int FLOATING = 3; // floating point number

    // Time Names
    public static const string[] TIMES_NAMES = {"Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha"};
    public static const string INVALID_TIME = "-----"; // The string used for invalid times

    // --------------------- Technical Settings --------------------

    private static const int NUM_ITERATIONS = 1; // number of iterations needed to compute times

    // ------------------- Calc Method Parameters --------------------

    /*
     * fa : fajr angle
     * ms : maghrib selector (0 = angle; 1 = minutes after sunset)
     * mv : maghrib parameter value (in angle or minutes)
     * is : isha selector (0 = angle; 1 = minutes after maghrib)
     * iv : isha parameter value (in angle or minutes)
     */
    private double[,] _methodParams = {
            {18, 1, 0, 0, 18},                       // Karachi
            {15, 1, 0, 0, 15},                       // ISNA
            {18, 1, 0, 0, 17},                       // MWL
            {18.5, 1, 0, 1, 90},                     // Makkah
            {19.5, 1, 0, 0, 17.5},                   // Egypt
            {18, 1, 0, 0, 17},                       // Custom
            {18, 1, 0, 1, 90}                        // Qatar
    };

    private double getMethodParams(int i, int j) {
        return _methodParams[i, j];
    }

    private void setMethodParams(int i, int j, double v) {
        _methodParams[i, j] = v;
    }

    // ---------------------- Global Variables --------------------

    public int calcMethod = 0; // caculation method
    public int asrJuristic = 0; // Juristic method for Asr
    public int dhuhrMinutes = 0; // minutes after mid-day for Dhuhr
    public int adjustHighLats = 1; // adjusting method for higher latitudes

    public int timeFormat = 0; // time format

    public double lat; // latitude
    public double lng; // longitude
    public double timeZone; // time-zone
    public double jDate; // Julian date

    public int[] offsets = new int[7];

    // ---------------------- Trigonometric Functions -----------------------

    // range reduce angle in degrees.
    public double fixangle(double a) {
        a = a - (360 * (Math.floor(a / 360.0)));
        a = a < 0 ? (a + 360) : a;
        return a;
    }

    // range reduce hours to 0..23
    public double fixhour(double a) {
        a = a - 24.0 * Math.floor(a / 24.0);
        a = a < 0 ? (a + 24) : a;
        return a;
    }

    // radian to degree
    public double radiansToDegrees(double alpha) {
        return ((alpha * 180.0) / Math.PI);
    }

    // deree to radian
    public double DegreesToRadians(double alpha) {
        return ((alpha * Math.PI) / 180.0);
    }

    // degree sin
    public double dsin(double d) {
        return (Math.sin(DegreesToRadians(d)));
    }

    // degree cos
    public double dcos(double d) {
        return (Math.cos(DegreesToRadians(d)));
    }

    // degree tan
    public double dtan(double d) {
        return (Math.tan(DegreesToRadians(d)));
    }

    // degree arcsin
    public double darcsin(double x) {
        return radiansToDegrees(Math.asin(x));
    }

    // degree arccos
    public double darccos(double x) {
        return radiansToDegrees(Math.acos(x));
    }

    // degree arctan
    public double darctan(double x) {
        return radiansToDegrees(Math.atan(x));
    }

    // degree arctan2
    public double darctan2(double y, double x) {
        return radiansToDegrees(Math.atan2(y, x));
    }

    // degree arccot
    public double darccot(double x) {
        return radiansToDegrees(Math.atan2(1.0, x));
    }

    // ---------------------- Time-Zone Functions -----------------------
/*
    // compute base time-zone of the system
    public static double getBaseTimeZone() {
        return (TimeZone.getDefault().getRawOffset() / 1000.0) / 3600;

    }

    // detect daylight saving in a given date
    public static double detectDaylightSaving() {
        return (double) TimeZone.getDefault().getDSTSavings();
    }
*/
    // ---------------------- Julian Date Functions -----------------------

    // calculate julian date from a calendar date
    public double julianDate(int year, int month, int day) {
        if (month <= 2) {
            year -= 1;
            month += 12;
        }
        double A = Math.floor(year / 100.0);
        double B = 2 - A + Math.floor(A / 4.0);
        return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + B - 1524.5;
    }

    // ---------------------- Calculation Functions -----------------------

    // References:
    // http://www.ummah.net/astronomy/saltime
    // http://aa.usno.navy.mil/faq/docs/SunApprox.html
    // compute declination angle of sun and equation of time
    public double[] sunPosition(double jd) {
        double D = jd - 2451545;
        double g = fixangle(357.529 + 0.98560028 * D);
        double q = fixangle(280.459 + 0.98564736 * D);
        double L = fixangle(q + (1.915 * dsin(g)) + (0.020 * dsin(2 * g)));

        double e = 23.439 - (0.00000036 * D);
        double d = darcsin(dsin(e) * dsin(L));
        double RA = (darctan2((dcos(e) * dsin(L)), (dcos(L)))) / 15.0;
        RA = fixhour(RA);
        double EqT = q / 15.0 - RA;
        double[] sPosition = new double[2];
        sPosition[0] = d;
        sPosition[1] = EqT;

        return sPosition;
    }

    // compute equation of time
    public double equationOfTime(double jd) {
        return sunPosition(jd)[1];
    }

    // compute declination angle of sun
    public double sunDeclination(double jd) {
        return sunPosition(jd)[0];
    }

    // compute mid-day (Dhuhr, Zawal) time
    public double computeMidDay(double t) {
        double T = equationOfTime(jDate + t);
        return fixhour(12 - T);
    }

    // compute time for a given angle G
    public double computeTime(double G, double t) {
        double D = sunDeclination(jDate + t);
        double Z = computeMidDay(t);
        double Beg = -dsin(G) - dsin(D) * dsin(lat);
        double Mid = dcos(D) * dcos(lat);
        double V = darccos(Beg / Mid) / 15.0;
        return Z + (G > 90 ? -V : V);
    }

    // compute the time of Asr
    // Shafii: step=1, Hanafi: step=2
    public double computeAsr(double step, double t) {
        double D = sunDeclination(jDate + t);
        double G = -darccot(step + dtan(Math.fabs(lat - D)));
        return computeTime(G, t);
    }

    // ---------------------- Misc Functions -----------------------

    // compute the difference between two times
    public double timeDiff(double time1, double time2) {
        return fixhour(time2 - time1);
    }

    // -------------------- Interface Functions --------------------

    // return prayer times for a given date
    public string[] getDatePrayerTimes(int year, int month, int day, double latitude, double longitude, double tZone) {
        lat = latitude;
        lng = longitude;
        timeZone = tZone;
        jDate = julianDate(year, month, day);
        double lonDiff = longitude / (15.0 * 24.0);
        jDate = jDate - lonDiff;
        return computeDayTimes();
    }

    // return prayer times for a given date
    public string[] getPrayerTimes(DateTime date, double latitude, double longitude, double tZone) {
        int year = date.get_year ();
        int month = date.get_month ();
        int day = date.get_day_of_month ();
        return getDatePrayerTimes(year, month, day, latitude, longitude, tZone);
    }

    // set custom values for calculation parameters
    public void setCustomParams(double[] params) {
        for (int i = 0; i < 5; i++) {
            if (params[i] == -1)
                setMethodParams(CUSTOM, i, getMethodParams(calcMethod, i));
            else
                setMethodParams(CUSTOM, i, params[i]);
        }
        calcMethod = CUSTOM;
    }

    // set the angle for calculating Fajr
    public void setFajrAngle(double angle) {
        double[] params = {angle, -1, -1, -1, -1};
        setCustomParams(params);
    }

    // set the angle for calculating Maghrib
    public void setMaghribAngle(double angle) {
        double[] params = {-1, 0, angle, -1, -1};
        setCustomParams(params);
    }

    // set the angle for calculating Isha
    public void setIshaAngle(double angle) {
        double[] params = {-1, -1, -1, 0, angle};
        setCustomParams(params);
    }

    // set the minutes after Sunset for calculating Maghrib
    public void setMaghribMinutes(double minutes) {
        double[] params = {-1, 1, minutes, -1, -1};
        setCustomParams(params);
    }

    // set the minutes after Maghrib for calculating Isha
    public void setIshaMinutes(double minutes) {
        double[] params = {-1, -1, -1, 1, minutes};
        setCustomParams(params);
    }

    // convert double hours to 24h format
    public string floatToTime24(double time) {
        string result;

        if (isNaN(time)) {
            return INVALID_TIME;
        }

        time = fixhour(time + 0.5 / 60.0); // add 0.5 minutes to round
        int hours = (int) Math.floor(time);
        double minutes = Math.floor((time - hours) * 60.0);

        if ((hours >= 0 && hours <= 9) && (minutes >= 0 && minutes <= 9)) {
            result = "0" + hours.to_string () + ":0" + Math.round(minutes).to_string ();
        } else if ((hours >= 0 && hours <= 9)) {
            result = "0" + hours.to_string () + ":" + Math.round(minutes).to_string ();
        } else if ((minutes >= 0 && minutes <= 9)) {
            result = hours.to_string () + ":0" + Math.round(minutes).to_string ();
        } else {
            result = hours.to_string () + ":" + Math.round(minutes).to_string ();
        }
        return result;
    }

    // convert double hours to 12h format
    public string floatToTime12(double time, bool noSuffix) {

        if (isNaN(time)) {
            return INVALID_TIME;
        }

        time = fixhour(time + 0.5 / 60); // add 0.5 minutes to round
        int hours = (int) Math.floor(time);
        double minutes = Math.floor((time - hours) * 60);
        string suffix, result;
        if (hours >= 12) {
            suffix = "pm";
        } else {
            suffix = "am";
        }
        hours = ((((hours + 12) - 1) % (12)) + 1);
        if (!noSuffix) {
            if ((hours >= 0 && hours <= 9) && (minutes >= 0 && minutes <= 9)) {
                result = "0" + hours.to_string () + ":0" + Math.round(minutes).to_string () + " " + suffix;
            } else if ((hours >= 0 && hours <= 9)) {
                result = "0" + hours.to_string () + ":" + Math.round(minutes).to_string () + " " + suffix;
            } else if ((minutes >= 0 && minutes <= 9)) {
                result = hours.to_string () + ":0" + Math.round(minutes).to_string () + " " + suffix;
            } else {
                result = hours.to_string () + ":" + Math.round(minutes).to_string () + " " + suffix;
            }

        } else {
            if ((hours >= 0 && hours <= 9) && (minutes >= 0 && minutes <= 9)) {
                result = "0" + hours.to_string () + ":0" + Math.round(minutes).to_string ();
            } else if ((hours >= 0 && hours <= 9)) {
                result = "0" + hours.to_string () + ":" + Math.round(minutes).to_string ();
            } else if ((minutes >= 0 && minutes <= 9)) {
                result = hours.to_string () + ":0" + Math.round(minutes).to_string ();
            } else {
                result = hours.to_string () + ":" + Math.round(minutes).to_string ();
            }
        }
        return result;

    }

    // convert double hours to 12h format with no suffix
    public string floatToTime12NS(double time) {
        return floatToTime12(time, true);
    }

    // ---------------------- Compute Prayer Times -----------------------

    // compute prayer times at given julian date
    public double[] computeTimes(double[] times) {

        double[] t = dayPortion(times);

        double Fajr = this.computeTime(180 - getMethodParams(calcMethod, 0), t[0]);
        double Sunrise = this.computeTime(180 - 0.833, t[1]);
        double Dhuhr = this.computeMidDay(t[2]);
        double Asr = this.computeAsr(1 + asrJuristic, t[3]);
        double Sunset = this.computeTime(0.833, t[4]);
        double Maghrib = this.computeTime(getMethodParams(calcMethod, 2), t[5]);
        double Isha = this.computeTime(getMethodParams(calcMethod, 4), t[6]);

        return new double[]{Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha};
    }

    // compute prayer times at given julian date
    public string[] computeDayTimes() {
        double[] times = {5, 6, 12, 13, 18, 18, 18}; // default times

        for (int i = 1; i <= NUM_ITERATIONS; i++) {
            times = computeTimes(times);
        }

        times = adjustTimes(times);
        times = tuneTimes(times);

        return adjustTimesFormat(times);
    }

    // adjust times in a prayer time array
    public double[] adjustTimes(owned double[] times) {
        for (int i = 0; i < times.length; i++) {
            times[i] += timeZone - lng / 15;
        }

        times[2] += dhuhrMinutes / 60; // Dhuhr
        if (getMethodParams(calcMethod, 1) == 1) // Maghrib
            times[5] = times[4] + getMethodParams(calcMethod, 2) / 60;
        if (getMethodParams(calcMethod, 3) == 1) // Isha
            times[6] = times[5] + getMethodParams(calcMethod, 4) / 60;

        if (adjustHighLats != NONE)
            times = adjustHighLatTimes(times);

        return times;
    }

    // convert times array to given time format
    public string[] adjustTimesFormat(double[] times) {
        string[] result = new string[7];

        if (timeFormat == FLOATING) {
            for (int i = 0; i < 7; i++)
                result[i] = times[i].to_string ();
            return result;
        }

        for (int i = 0; i < 7; i++) {
            if (timeFormat == TIME_12) {
                result[i] = floatToTime12(times[i], false);
            } else if (timeFormat == TIME_12_NS) {
                result[i] = floatToTime12(times[i], true);
            } else {
                result[i] = floatToTime24(times[i]);
            }
        }
        return result;
    }

    // adjust Fajr, Isha and Maghrib for locations in higher latitudes
    public double[] adjustHighLatTimes(double[] times) {
        double nightTime = timeDiff(times[4], times[1]); // sunset to sunrise

        // Adjust Fajr
        double FajrDiff = nightPortion(getMethodParams(calcMethod, 0)) * nightTime;

        if (isNaN(times[0]) || timeDiff(times[0], times[1]) > FajrDiff) {
            times[0] = times[1] - FajrDiff;
        }

        // Adjust Isha
        double IshaAngle = (getMethodParams(calcMethod, 3) == 0) ? getMethodParams(calcMethod, 4) : 18;
        double IshaDiff = this.nightPortion(IshaAngle) * nightTime;
        if (isNaN(times[6]) || this.timeDiff(times[4], times[6]) > IshaDiff) {
            times[6] = times[4] + IshaDiff;
        }

        // Adjust Maghrib
        double MaghribAngle = (getMethodParams(calcMethod, 1) == 0) ? getMethodParams(calcMethod, 2) : 4;
        double MaghribDiff = nightPortion(MaghribAngle) * nightTime;
        if (isNaN(times[5]) || this.timeDiff(times[4], times[5]) > MaghribDiff) {
            times[5] = times[4] + MaghribDiff;
        }

        return times;
    }

    // the night portion used for adjusting times in higher latitudes
    public double nightPortion(double angle) {
        switch (adjustHighLats) {
            case ANGLE_BASED:
                return angle / 60.0;
            case MIDNIGHT:
                return 0.5;
            case ONE_SEVENTH:
                return 0.14286;
            default:
                return 0;
        }
    }

    // convert hours to day portions
    public double[] dayPortion(double[] times) {
        for (int i = 0; i < 7; i++)
            times[i] /= 24;
        return times;
    }

    // Tune timings for adjustments
    // Set time offsets
    public void tune(int[] offsetTimes) {
        for (int i = 0; i < offsetTimes.length; i++)
            this.offsets[i] = offsetTimes[i];
    }

    public double[] tuneTimes(double[] times) {
        for (int i = 0; i < times.length; i++) {
            times[i] = times[i] + this.offsets[i] / 60.0;
        }
        return times;
    }

    private static bool isNaN(double d) {
    	return d < 0;
    }

    /*public static void main(string[] args) {
        double latitude = 25.2899589;
        double longitude = 51.4974742;
        double timezone = 3;

        PrayTime prayers = new PrayTime();

        prayers.timeFormat = TIME_12;
        prayers.calcMethod = QATAR;
        prayers.asrJuristic = SHAFII;
        prayers.adjustHighLats = ANGLE_BASED;
        int[] offsets = {0, 0, 0, 0, 0, 0, 0}; // {Fajr,Sunrise,Dhuhr,Asr,Sunset,Maghrib,Isha}
        prayers.tune(offsets);

        var cal = new DateTime.now_local ();

        string[] prayerTimes = prayers.getPrayerTimes(cal, latitude, longitude, timezone);

        for (int i = 0; i < prayerTimes.length; i++) {
            print (TIMES_NAMES[i] + "\t\t" + prayerTimes[i] + "\n");
        }

    }*/

}


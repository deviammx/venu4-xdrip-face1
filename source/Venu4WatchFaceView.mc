import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! Floral digital watch face for the Venu 4 (41mm): glucose trend above a
//! smaller, left-of-center time, left-aligned date, battery icon
//! bottom-left.
class Venu4WatchFaceView extends WatchUi.WatchFace {

    private const ACCENT_COLOR = 0x46C8BE;
    private const TEXT_COLOR = Graphics.COLOR_WHITE;
    private const DIM_COLOR = 0x8A8A8A;
    private const BG_COLOR = Graphics.COLOR_BLACK;

    // Weekday color depends on the selected background (BackgroundIndex).
    private const MAGNOLIA_WEEKDAY_COLOR = 0x6F1C48;
    private const GOLDEN_WEEKDAY_COLOR = 0xEEB83D;

    private const TIME_FONT = Graphics.FONT_NUMBER_MILD; // ~30% smaller than FONT_NUMBER_HOT
    private const DATE_FONT = Graphics.FONT_SMALL; // ~20% smaller than FONT_MEDIUM
    private const LEFT_X = 46; // stays clear of the round bezel for the left-aligned date/battery
    private const TOP_SAFE_MARGIN = 36; // keeps the glucose row clear of the round bezel
    private const TIME_GAP = 22; // extra breathing room below the glucose row
    private const ROW_GAP = 6;
    private const DATE_WEEKDAY_GAP = 10;
    private const BATTERY_GAP = 18;
    private const GLUCOSE_DOWN_NUDGE = 12; // slight extra drop below the safe margin
    private const BATTERY_SCALE = 0.25;
    private const BATTERY_NATIVE_WIDTH = 126;
    private const BATTERY_NATIVE_HEIGHT = 71;

    private const WEEKDAY_ABBREVIATIONS = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

    private var _maxWeekdayWidth as Number?;

    public function initialize() {
        WatchFace.initialize();
        _maxWeekdayWidth = null;
    }

    public function onLayout(dc as Dc) as Void {
    }

    public function onShow() as Void {
    }

    public function onHide() as Void {
    }

    public function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }

    public function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

    public function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;

        drawBackground(dc, width, height);

        // The day number always starts at the same x regardless of which
        // weekday is showing, since it's offset by a slot reserved for the
        // widest possible weekday abbreviation rather than today's actual
        // weekday width. It's also always 2 digits (zero-padded), so its
        // own width - and everything measured from it below - is constant.
        var weekdayText = getWeekdayText();
        var dayText = getDayText();
        var dayNumberX = LEFT_X + getMaxWeekdayWidth(dc) + DATE_WEEKDAY_GAP;
        var dayTextWidth = dc.getTextWidthInPixels(dayText, DATE_FONT);
        var dateRightEdge = dayNumberX + dayTextWidth;
        var dateCenterX = (LEFT_X + dateRightEdge) / 2;

        // Time's right edge aligns with the date's right edge (the end of
        // the day number).
        var timeText = getTimeText();
        var timeTextWidth = dc.getTextWidthInPixels(timeText, TIME_FONT);
        var timeCenterX = dateRightEdge - (timeTextWidth / 2);

        // Glucose values are centered on the date block as a whole (from
        // the weekday's start to the day number's end).
        var glucoseValuesCenterX = dateCenterX;

        // Everything below is built top-down so rows can never overlap,
        // regardless of font metrics.
        var glucoseFontHeight = Graphics.getFontHeight(Graphics.FONT_SMALL);
        var glucoseY = TOP_SAFE_MARGIN + glucoseFontHeight + GLUCOSE_DOWN_NUDGE;

        var timeFontHeight = Graphics.getFontHeight(TIME_FONT);
        var timeY = glucoseY + glucoseFontHeight + TIME_GAP;

        var dateFontHeight = Graphics.getFontHeight(DATE_FONT);
        var dateY = (timeY + timeFontHeight + ROW_GAP) - (dateFontHeight / 2); // moved half a height up

        var batteryIconWidth = (BATTERY_NATIVE_WIDTH * BATTERY_SCALE).toNumber();
        var batteryIconHeight = (BATTERY_NATIVE_HEIGHT * BATTERY_SCALE).toNumber();
        var batteryX = LEFT_X + batteryIconWidth; // moved 1 icon length right
        var batteryY = (dateY + dateFontHeight + BATTERY_GAP) + (2 * batteryIconHeight); // moved 2 icon heights down

        drawGlucose(dc, centerX, glucoseValuesCenterX, glucoseY); // fallback centered on screen, values centered on date
        drawTime(dc, timeCenterX, timeY, timeText);
        drawDate(dc, dayNumberX, dateY, weekdayText, dayText);
        drawBattery(dc, batteryX, batteryY, centerX, centerY);
    }

    private function getWeekdayText() as String {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return now.day_of_week.toString().toUpper();
    }

    //! Always 2 digits (zero-padded) so the day number's width - and
    //! anything aligned to it - never shifts with the day of the month.
    private function getDayText() as String {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return now.day.format("%02d");
    }

    private function getTimeText() as String {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;

        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }

        return Lang.format("$1$:$2$", [hour.format("%02d"), clockTime.min.format("%02d")]);
    }

    //! Widest of the 7 weekday abbreviations at DATE_FONT, cached after the
    //! first computation since it never changes at runtime.
    private function getMaxWeekdayWidth(dc as Dc) as Number {
        if (_maxWeekdayWidth != null) {
            return _maxWeekdayWidth;
        }

        var maxWidth = 0;
        for (var i = 0; i < WEEKDAY_ABBREVIATIONS.size(); i += 1) {
            var w = dc.getTextWidthInPixels(WEEKDAY_ABBREVIATIONS[i], DATE_FONT);
            if (w > maxWidth) {
                maxWidth = w;
            }
        }

        _maxWeekdayWidth = maxWidth;
        return maxWidth;
    }

    private function drawBackground(dc as Dc, width as Number, height as Number) as Void {
        var index = Properties.getValue("BackgroundIndex") as Number?;
        var bitmap = (index != null) ? BackgroundStore.getBitmap(index) : null;

        if (bitmap == null) {
            dc.setColor(BG_COLOR, BG_COLOR);
            dc.clear();
            return;
        }

        dc.drawBitmap(0, 0, bitmap);
    }

    //! @param fallbackCenterX Where to center the "NO CONNECTION"/"NO DATA"
    //!        text - screen-centered since it's much wider than the actual
    //!        sgv/delta reading and would clip if centered over time.
    //! @param valuesCenterX Where to center the sgv | icon | delta row.
    private function drawGlucose(dc as Dc, fallbackCenterX as Number, valuesCenterX as Number, y as Number) as Void {
        if (!GlucoseStore.isOk()) {
            dc.setColor(DIM_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawText(fallbackCenterX, y, Graphics.FONT_SMALL, GlucoseStore.getStatusText(), Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        // sgv | trend icon | delta, icon centered on the line.
        var icon = TrendIconStore.getBitmap(GlucoseStore.getTrendIcon());
        var iconScale = 0.7; // reduced 30% from native size
        var iconWidth = (icon.getWidth() * iconScale).toNumber();
        var iconHeight = (icon.getHeight() * iconScale).toNumber();
        var iconHalfWidth = iconWidth / 2;
        var gap = 10;

        var textCenterY = y + (Graphics.getFontHeight(Graphics.FONT_SMALL) / 2);
        var iconY = textCenterY - (iconHeight / 2);

        dc.setColor(TEXT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(valuesCenterX - iconHalfWidth - gap, y, Graphics.FONT_SMALL, GlucoseStore.getSgvText(), Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(valuesCenterX + iconHalfWidth + gap, y, Graphics.FONT_SMALL, GlucoseStore.getDeltaText(), Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawScaledBitmap(valuesCenterX - iconHalfWidth, iconY, iconWidth, iconHeight, icon);
    }

    private function drawTime(dc as Dc, centerX as Number, y as Number, timeText as String) as Void {
        dc.setColor(TEXT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, TIME_FONT, timeText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Weekday (colored per background) and day number (white), drawn as
    //! two segments so each can have its own color. The day number sits at
    //! the fixed dayNumberX, and the weekday is right-aligned to end just
    //! before it - so the day number's position (and time's/glucose's
    //! alignment to it) stays stable regardless of weekday width, while the
    //! weekday sits snugly against the day number instead of trailing off
    //! after a fixed-width gap.
    private function drawDate(dc as Dc, dayNumberX as Number, y as Number, weekdayText as String, dayText as String) as Void {
        dc.setColor(getWeekdayColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(dayNumberX - DATE_WEEKDAY_GAP, y, DATE_FONT, weekdayText, Graphics.TEXT_JUSTIFY_RIGHT);

        dc.setColor(TEXT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dayNumberX, y, DATE_FONT, dayText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function getWeekdayColor() as ColorType {
        var index = Properties.getValue("BackgroundIndex") as Number?;
        if (index == 1) {
            return MAGNOLIA_WEEKDAY_COLOR;
        } else if (index == 2) {
            return GOLDEN_WEEKDAY_COLOR;
        }
        return ACCENT_COLOR;
    }

    private function drawBattery(dc as Dc, x as Number, y as Number, centerX as Number, centerY as Number) as Void {
        var battery = System.getSystemStats().battery;
        var icon = BatteryIconStore.getBitmap(BatteryIconStore.iconFor(battery));
        var iconWidth = (icon.getWidth() * BATTERY_SCALE).toNumber();
        var iconHeight = (icon.getHeight() * BATTERY_SCALE).toNumber();

        // Keep the icon's bottom-left corner (the tightest point against the
        // round bezel) inside the circular display, regardless of layout
        // math pushing it further out than expected.
        var radius = centerX;
        var dx = centerX - x;
        var safetyBuffer = 8;
        var maxBottom = centerY + Math.sqrt((radius * radius - dx * dx).toFloat()).toNumber() - safetyBuffer;
        var maxY = maxBottom - iconHeight;
        if (y > maxY) {
            y = maxY;
        }

        dc.drawScaledBitmap(x, y, iconWidth, iconHeight, icon);
    }
}

import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.ActivityMonitor;
import Toybox.SensorHistory;

//! Simple, battery-friendly digital watch face for the Venu 4 (41mm).
//! Shows time, date, battery, step count and last known heart rate.
class Venu4WatchFaceView extends WatchUi.WatchFace {

    private const ACCENT_COLOR = 0x46C8BE;
    private const TEXT_COLOR = Graphics.COLOR_WHITE;
    private const DIM_COLOR = 0x8A8A8A;
    private const BG_COLOR = Graphics.COLOR_BLACK;

    private const TIME_FONT = Graphics.FONT_NUMBER_HOT;
    private const DATE_FONT = Graphics.FONT_TINY; // ~20% smaller than FONT_SMALL, closest built-in size
    private const ROW_GAP = 3;
    private const STATS_GAP = 10; // pulled up closer to the time block
    private const TOP_SAFE_MARGIN = 36; // keeps the top row clear of the round bezel

    public function initialize() {
        WatchFace.initialize();
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

        // Time is vertically centered on the screen at its full (unchanged) size.
        var timeFontHeight = Graphics.getFontHeight(TIME_FONT);
        var timeY = centerY - (timeFontHeight / 2);

        // Glucose and date are built top-down from a fixed safe margin so they
        // can never overlap each other, regardless of font metrics.
        var glucoseY = TOP_SAFE_MARGIN;
        var glucoseFontHeight = Graphics.getFontHeight(Graphics.FONT_SMALL);

        var dateY = glucoseY + glucoseFontHeight + ROW_GAP;

        drawGlucose(dc, centerX, glucoseY);
        drawDate(dc, centerX, dateY);
        drawTime(dc, centerX, timeY);
        drawStats(dc, centerX, timeY + timeFontHeight + STATS_GAP);
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

    private function drawGlucose(dc as Dc, centerX as Number, y as Number) as Void {
        if (!GlucoseStore.isOk()) {
            dc.setColor(DIM_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_SMALL, GlucoseStore.getStatusText(), Graphics.TEXT_JUSTIFY_CENTER);
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
        dc.drawText(centerX - iconHalfWidth - gap, y, Graphics.FONT_SMALL, GlucoseStore.getSgvText(), Graphics.TEXT_JUSTIFY_RIGHT);
        dc.drawText(centerX + iconHalfWidth + gap, y, Graphics.FONT_SMALL, GlucoseStore.getDeltaText(), Graphics.TEXT_JUSTIFY_LEFT);

        dc.drawScaledBitmap(centerX - iconHalfWidth, iconY, iconWidth, iconHeight, icon);
    }

    private function drawDate(dc as Dc, centerX as Number, y as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateText = Lang.format("$1$, $2$ $3$", [now.day_of_week, now.month, now.day]);

        dc.setColor(ACCENT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, DATE_FONT, dateText.toUpper(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawTime(dc as Dc, centerX as Number, y as Number) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;

        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }

        var timeText = Lang.format("$1$:$2$", [hour.format("%02d"), clockTime.min.format("%02d")]);

        dc.setColor(TEXT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, y, TIME_FONT, timeText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawStats(dc as Dc, centerX as Number, y as Number) as Void {
        var colWidth = 110;

        drawStat(dc, centerX - colWidth, y, "HR", getHeartRateText());
        drawStat(dc, centerX, y, "STEPS", getStepsText());
        drawStat(dc, centerX + colWidth, y, "BATT", getBatteryText());
    }

    private function drawStat(dc as Dc, x as Number, y as Number, label as String, value as String) as Void {
        dc.setColor(DIM_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(TEXT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + 18, Graphics.FONT_SMALL, value, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function getBatteryText() as String {
        var battery = System.getSystemStats().battery;
        return battery.format("%d") + "%";
    }

    private function getStepsText() as String {
        var info = ActivityMonitor.getInfo();
        if (info != null && info.steps != null) {
            return info.steps.toString();
        }
        return "--";
    }

    private function getHeartRateText() as String {
        if (Toybox has :SensorHistory && (SensorHistory has :getHeartRateHistory)) {
            var iterator = SensorHistory.getHeartRateHistory({:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
            if (iterator != null) {
                var sample = iterator.next();
                if (sample != null && sample.data != null) {
                    return sample.data.toString();
                }
            }
        }
        return "--";
    }
}

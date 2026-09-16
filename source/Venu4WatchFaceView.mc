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

        drawGlucose(dc, centerX, centerY);
        drawDate(dc, centerX, centerY);
        drawTime(dc, centerX, centerY);
        drawStats(dc, centerX, centerY);
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

    private function drawGlucose(dc as Dc, centerX as Number, centerY as Number) as Void {
        var y = centerY - 140;

        if (GlucoseStore.isOk()) {
            var text = Lang.format("$1$  $2$  $3$", [GlucoseStore.getSgvText(), GlucoseStore.getDeltaText(), GlucoseStore.getArrow()]);
            dc.setColor(ACCENT_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_SMALL, text, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.setColor(DIM_COLOR, Graphics.COLOR_TRANSPARENT);
            dc.drawText(centerX, y, Graphics.FONT_SMALL, GlucoseStore.getStatusText(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    private function drawDate(dc as Dc, centerX as Number, centerY as Number) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateText = Lang.format("$1$, $2$ $3$", [now.day_of_week, now.month, now.day]);

        dc.setColor(ACCENT_COLOR, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY - 92, Graphics.FONT_MEDIUM, dateText.toUpper(), Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawTime(dc as Dc, centerX as Number, centerY as Number) as Void {
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
        dc.drawText(centerX, centerY - 40, Graphics.FONT_NUMBER_HOT, timeText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawStats(dc as Dc, centerX as Number, centerY as Number) as Void {
        var y = centerY + 78;
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

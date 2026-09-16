import Toybox.Test;
import Toybox.Lang;

(:test)
function testBatteryIconStoreThresholds(logger as Logger) as Boolean {
    var cases = [
        [100, Rez.Drawables.Battery100],
        [90, Rez.Drawables.Battery100],
        [89, Rez.Drawables.Battery75],
        [60, Rez.Drawables.Battery75],
        [59, Rez.Drawables.Battery50],
        [35, Rez.Drawables.Battery50],
        [34, Rez.Drawables.Battery25],
        [12, Rez.Drawables.Battery25],
        [11, Rez.Drawables.BatteryLow],
        [0, Rez.Drawables.BatteryLow]
    ];

    for (var i = 0; i < cases.size(); i += 1) {
        var percent = cases[i][0];
        var expected = cases[i][1];
        Test.assertEqualMessage(BatteryIconStore.iconFor(percent), expected, "percent " + percent + " should map to the right icon");
    }
    return true;
}

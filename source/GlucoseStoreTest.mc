import Toybox.Test;
import Toybox.Lang;

//! Verifies GlucoseStore against the exact JSON shape returned by the real
//! xdrip-server-mock /pebble endpoint (captured via curl), plus the
//! no-connection / no-data fallback paths.

(:test)
function testGlucoseStoreSuccess(logger as Logger) as Boolean {
    var data = {
        "status" => [{"now" => 1789500521}],
        "bgs" => [
            {
                "sgv" => "128",
                "trend" => 4,
                "direction" => "Flat",
                "slopeArrow" => "Flat",
                "filtered" => 127995,
                "unfiltered" => 128135,
                "noise" => 1,
                "bgdelta" => 1,
                "battery" => "100"
            },
            {
                "sgv" => "127",
                "trend" => 4,
                "direction" => "Flat",
                "bgdelta" => 3,
                "battery" => "100"
            }
        ]
    };

    GlucoseStore.ingest(200, data);

    Test.assertEqual(GlucoseStore.isOk(), true);
    Test.assertEqualMessage(GlucoseStore.getSgvText(), "128", "sgv should use first (most recent) entry");
    Test.assertEqualMessage(GlucoseStore.getDeltaText(), "+1", "positive delta should get a + sign");
    Test.assertEqualMessage(GlucoseStore.getArrow(), "-", "Flat should map to -");
    return true;
}

(:test)
function testGlucoseStoreNegativeDeltaAndArrows(logger as Logger) as Boolean {
    var cases = [
        ["DoubleUp", "^^"],
        ["SingleUp", "^"],
        ["FortyFiveUp", "/"],
        ["FortyFiveDown", "\\"],
        ["SingleDown", "v"],
        ["DoubleDown", "vv"],
        ["NOT COMPUTABLE", "?"]
    ];

    for (var i = 0; i < cases.size(); i += 1) {
        var direction = cases[i][0];
        var expectedArrow = cases[i][1];

        var data = {
            "bgs" => [
                { "sgv" => 95, "direction" => direction, "bgdelta" => -4 }
            ]
        };
        GlucoseStore.ingest(200, data);

        Test.assertEqualMessage(GlucoseStore.isOk(), true, "should be ok for direction " + direction);
        Test.assertEqualMessage(GlucoseStore.getSgvText(), "95", "numeric sgv should format cleanly");
        Test.assertEqualMessage(GlucoseStore.getDeltaText(), "-4", "negative delta keeps its own minus sign");
        Test.assertEqualMessage(GlucoseStore.getArrow(), expectedArrow, "direction " + direction + " should map to " + expectedArrow);
    }
    return true;
}

(:test)
function testGlucoseStoreNoConnection(logger as Logger) as Boolean {
    // Non-200 response code (unreachable / phone not connected / etc).
    GlucoseStore.ingest(-104, null);
    Test.assertEqual(GlucoseStore.isOk(), false);
    Test.assertEqualMessage(GlucoseStore.getStatusText(), "NO CONNECTION", "non-200 response should show NO CONNECTION");
    return true;
}

(:test)
function testGlucoseStoreNoData(logger as Logger) as Boolean {
    // Reachable, but no readings available.
    GlucoseStore.ingest(200, {"bgs" => []});
    Test.assertEqual(GlucoseStore.isOk(), false);
    Test.assertEqualMessage(GlucoseStore.getStatusText(), "NO DATA", "empty bgs array should show NO DATA");

    // Reachable, malformed/missing sgv field.
    GlucoseStore.ingest(200, {"bgs" => [{"direction" => "Flat"}]});
    Test.assertEqual(GlucoseStore.isOk(), false);
    Test.assertEqualMessage(GlucoseStore.getStatusText(), "NO DATA", "missing sgv should show NO DATA");
    return true;
}

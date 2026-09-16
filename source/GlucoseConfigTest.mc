import Toybox.Test;
import Toybox.Lang;
import Toybox.Application.Properties;

(:test)
function testGlucoseConfigUsesConfiguredBaseUrl(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "http://192.168.1.50");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "http://192.168.1.50:17581/pebble", "should build URL from configured base");
    return true;
}

(:test)
function testGlucoseConfigFallsBackWhenEmpty(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "http://127.0.0.1:17581/pebble", "empty base URL should fall back to default");
    return true;
}

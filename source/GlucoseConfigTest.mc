import Toybox.Test;
import Toybox.Lang;
import Toybox.Application.Properties;

(:test)
function testGlucoseConfigUsesConfiguredBaseUrlAndPort(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "http://192.168.1.50");
    Properties.setValue("XdripBasePort", "17581");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "http://192.168.1.50:17581/pebble", "should build URL from configured base + port");
    return true;
}

(:test)
function testGlucoseConfigFallsBackWhenUrlEmpty(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "");
    Properties.setValue("XdripBasePort", "17581");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "http://127.0.0.1:17581/pebble", "empty base URL should fall back to default host");
    return true;
}

(:test)
function testGlucoseConfigAddsSchemeWhenMissing(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "192.168.1.50");
    Properties.setValue("XdripBasePort", "17581");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "http://192.168.1.50:17581/pebble", "missing scheme should default to http://");
    return true;
}

(:test)
function testGlucoseConfigStripsTrailingSlash(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "http://192.168.1.50/");
    Properties.setValue("XdripBasePort", "17581");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "http://192.168.1.50:17581/pebble", "trailing slash on base URL should not duplicate the slash before the port");
    return true;
}

//! An empty/unset port falls back to xDrip+'s default HTTP port (17580),
//! rather than being omitted - so a hosted endpoint on a standard port (e.g.
//! Railway's HTTPS on 443) now needs its port typed explicitly if it must
//! differ from that default.
(:test)
function testGlucoseConfigFallsBackToDefaultPortWhenEmpty(logger as Logger) as Boolean {
    Properties.setValue("XdripBaseUrl", "https://xdrip-server-mock-production.up.railway.app");
    Properties.setValue("XdripBasePort", "");
    Test.assertEqualMessage(GlucoseConfig.getApiUrl(), "https://xdrip-server-mock-production.up.railway.app:17580/pebble", "empty port should fall back to the default HTTP port, and https:// should be preserved");
    return true;
}

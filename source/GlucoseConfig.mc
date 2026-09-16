import Toybox.Application.Properties;
import Toybox.Lang;

//! Shared config for the xDrip+ polling. The base URL is user-configurable
//! via app settings ("xDrip+ Base URL") - requests are relayed through the
//! paired phone by the system, so the default "http://127.0.0.1" refers to
//! the phone running xDrip+, not the watch.
//!
//! Annotated (:background) because getApiUrl() (and the Properties read it
//! does) is called from GlucoseServiceDelegate.onTemporalEvent(), which runs
//! in the system's restricted background execution context - without this
//! annotation the symbol isn't linked into that binary and calling it
//! crashes with "Illegal Access (Out of Bounds)".
(:background)
module GlucoseConfig {
    const DEFAULT_BASE_URL = "http://127.0.0.1";
    const DEFAULT_BASE_PORT = "17580";
    const API_PATH = "/pebble";

    // Minimum enforced by Background.registerForTemporalEvent() is 5 minutes.
    const REFRESH_SECONDS = 300;

    function getApiUrl() as String {
        var baseUrl = Properties.getValue("XdripBaseUrl") as String?;
        if (baseUrl == null || baseUrl.length() == 0) {
            baseUrl = DEFAULT_BASE_URL;
        }
        if (baseUrl.find("://") == null) {
            baseUrl = "http://" + baseUrl;
        }

        // Strip a trailing slash so it can't collide with the port/path we append.
        if (baseUrl.substring(baseUrl.length() - 1, baseUrl.length()).equals("/")) {
            baseUrl = baseUrl.substring(0, baseUrl.length() - 1);
        }

        // An empty/unset port falls back to xDrip+'s default HTTP port.
        var basePort = Properties.getValue("XdripBasePort") as String?;
        var portSegment = (basePort != null && basePort.length() > 0) ? (":" + basePort) : (":" + DEFAULT_BASE_PORT);

        return baseUrl + portSegment + API_PATH;
    }
}

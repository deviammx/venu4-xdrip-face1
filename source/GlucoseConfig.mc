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
    const PORT_AND_PATH = ":17581/pebble";

    // Minimum enforced by Background.registerForTemporalEvent() is 5 minutes.
    const REFRESH_SECONDS = 300;

    function getApiUrl() as String {
        var baseUrl = Properties.getValue("XdripBaseUrl") as String?;
        if (baseUrl == null || baseUrl.length() == 0) {
            baseUrl = DEFAULT_BASE_URL;
        }
        return baseUrl + PORT_AND_PATH;
    }
}

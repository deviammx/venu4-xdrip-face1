import Toybox.Lang;
import Toybox.System;
import Toybox.Communications;
import Toybox.Background;
import Toybox.PersistedContent;

//! Runs in the system's background execution slot (separate, memory-limited
//! context) and does the actual network call. Keep this class minimal -
//! everything else (parsing, formatting, caching) lives in GlucoseStore,
//! which only runs in the foreground.
(:background)
class GlucoseServiceDelegate extends System.ServiceDelegate {

    public function initialize() {
        ServiceDelegate.initialize();
    }

    public function onTemporalEvent() as Void {
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(GlucoseConfig.getApiUrl(), null, options, method(:onReceive));
    }

    public function onReceive(responseCode as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        Background.exit({
            "responseCode" => responseCode,
            "data" => data
        });
    }
}

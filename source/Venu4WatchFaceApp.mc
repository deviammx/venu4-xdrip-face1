import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

(:background)
class Venu4WatchFaceApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
        // Communications is only usable from the background ServiceDelegate
        // for a watchface app type - the system enforces a 5 minute minimum
        // between temporal events, so that's also the floor for how soon
        // the first reading can appear.
        Background.registerForTemporalEvent(new Time.Duration(GlucoseConfig.REFRESH_SECONDS));
    }

    public function onStop(state as Dictionary?) as Void {
    }

    //! Called when the user changes a setting (e.g. background image) via
    //! Garmin Connect Mobile / Garmin Express.
    public function onSettingsChanged() as Void {
        WatchUi.requestUpdate();
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        Background.registerForTemporalEvent(new Time.Duration(GlucoseConfig.REFRESH_SECONDS));
        return [new Venu4WatchFaceView()];
    }

    //! Get service delegates to run background tasks for the app
    public function getServiceDelegate() as [ServiceDelegate] {
        return [new GlucoseServiceDelegate()];
    }

    //! Handle data passed from the background service delegate.
    public function onBackgroundData(data as PersistableType) as Void {
        var payload = data as Dictionary;
        GlucoseStore.ingest(payload.get("responseCode") as Number, payload.get("data"));
        Background.registerForTemporalEvent(new Time.Duration(GlucoseConfig.REFRESH_SECONDS));
        WatchUi.requestUpdate();
    }
}

function getApp() as Venu4WatchFaceApp {
    return Application.getApp() as Venu4WatchFaceApp;
}

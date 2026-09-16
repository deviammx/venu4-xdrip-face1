import Toybox.Lang;
import Toybox.WatchUi;

//! Picks and caches the battery bitmap matching the current charge level.
module BatteryIconStore {

    var cache = {} as Dictionary<ResourceId, WatchUi.BitmapResource>;

    //! @param percent Battery charge, 0-100.
    function iconFor(percent as Float or Number) as ResourceId {
        if (percent >= 90) {
            return Rez.Drawables.Battery100;
        } else if (percent >= 60) {
            return Rez.Drawables.Battery75;
        } else if (percent >= 35) {
            return Rez.Drawables.Battery50;
        } else if (percent >= 12) {
            return Rez.Drawables.Battery25;
        }
        return Rez.Drawables.BatteryLow;
    }

    function getBitmap(id as ResourceId) as WatchUi.BitmapResource {
        if (cache.hasKey(id)) {
            return cache.get(id);
        }

        var bitmap = WatchUi.loadResource(id) as WatchUi.BitmapResource;
        cache.put(id, bitmap);
        return bitmap;
    }
}

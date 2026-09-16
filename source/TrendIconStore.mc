import Toybox.Lang;
import Toybox.WatchUi;

//! Loads and caches the trend arrow bitmaps selected by GlucoseStore.
module TrendIconStore {

    var cache = {} as Dictionary<ResourceId, WatchUi.BitmapResource>;

    function getBitmap(id as ResourceId) as WatchUi.BitmapResource {
        if (cache.hasKey(id)) {
            return cache.get(id);
        }

        var bitmap = WatchUi.loadResource(id) as WatchUi.BitmapResource;
        cache.put(id, bitmap);
        return bitmap;
    }
}

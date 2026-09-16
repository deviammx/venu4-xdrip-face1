import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

//! Loads and caches the selected background image. Index 0 means "no
//! image" (plain black background).
module BackgroundStore {

    var cache = {} as Dictionary<Number, WatchUi.BitmapResource>;

    function getBitmap(index as Number) as WatchUi.BitmapResource? {
        if (index <= 0) {
            return null;
        }
        if (cache.hasKey(index)) {
            return cache.get(index);
        }

        var bitmap = null;
        if (index == 1) {
            bitmap = WatchUi.loadResource(Rez.Drawables.BackgroundImage1) as WatchUi.BitmapResource;
        } else if (index == 2) {
            bitmap = WatchUi.loadResource(Rez.Drawables.BackgroundImage2) as WatchUi.BitmapResource;
        }

        if (bitmap != null) {
            cache.put(index, bitmap);
        }
        return bitmap;
    }
}

import Toybox.Lang;
import Toybox.Math;

//! Foreground-only cache of the latest glucose reading delivered by
//! GlucoseServiceDelegate. The watch face view reads from here; nothing
//! here runs in the background execution context.
module GlucoseStore {

    var status as Symbol = :noConnection;
    var sgvText as String = "";
    var deltaText as String = "";
    var arrow as String = "?";

    function ingest(responseCode as Number, data) as Void {
        if (responseCode != 200) {
            status = :noConnection;
            return;
        }

        var entry = extractLatestEntry(data);
        if (entry == null) {
            status = :noData;
            return;
        }

        var sgv = toNumberOrNull(entry.get("sgv"));
        if (sgv == null) {
            status = :noData;
            return;
        }

        var delta = toNumberOrNull(entry.get("bgdelta"));
        var direction = entry.get("direction");

        sgvText = formatValue(sgv, false);
        deltaText = formatValue(delta, true);
        arrow = arrowFor(direction);
        status = :ok;
    }

    function isOk() as Boolean {
        return status == :ok;
    }

    //! Human readable fallback shown instead of sgv/delta/direction.
    function getStatusText() as String {
        if (status == :noConnection) {
            return "NO CONNECTION";
        }
        return "NO DATA";
    }

    function getSgvText() as String {
        return sgvText;
    }

    function getDeltaText() as String {
        return deltaText;
    }

    function getArrow() as String {
        return arrow;
    }

    function extractLatestEntry(data) as Dictionary? {
        if (data == null || !(data instanceof Dictionary)) {
            return null;
        }
        var bgs = data.get("bgs");
        if (bgs == null || !(bgs instanceof Array) || bgs.size() == 0) {
            return null;
        }
        var entry = bgs[0];
        if (entry instanceof Dictionary) {
            return entry;
        }
        return null;
    }

    function toNumberOrNull(value) as Numeric? {
        if (value == null) {
            return null;
        }
        if (value instanceof Number || value instanceof Float) {
            return value;
        }
        if (value instanceof String) {
            return value.toFloat();
        }
        return null;
    }

    //! Formats a numeric reading, dropping a trailing ".0" and adding a
    //! leading "+" for non-negative deltas.
    function formatValue(value as Numeric?, signed as Boolean) as String {
        if (value == null) {
            return "--";
        }

        var rounded = Math.round(value).toNumber();
        var text = (rounded.toFloat() == value.toFloat()) ? rounded.toString() : value.format("%.1f");

        if (signed && value >= 0) {
            text = "+" + text;
        }
        return text;
    }

    function arrowFor(direction) as String {
        if (!(direction instanceof String)) {
            return "?";
        }
        if (direction.equals("DoubleUp")) {
            return "^^";
        } else if (direction.equals("SingleUp")) {
            return "^";
        } else if (direction.equals("FortyFiveUp")) {
            return "/";
        } else if (direction.equals("Flat")) {
            return "-";
        } else if (direction.equals("FortyFiveDown")) {
            return "\\";
        } else if (direction.equals("SingleDown")) {
            return "v";
        } else if (direction.equals("DoubleDown")) {
            return "vv";
        }
        return "?";
    }
}

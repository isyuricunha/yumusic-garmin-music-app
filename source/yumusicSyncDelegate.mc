import Toybox.Communications;
import Toybox.Lang;

class yumusicSyncDelegate extends Communications.SyncDelegate {

    function initialize() {
        SyncDelegate.initialize();
    }

    // Called when the system starts a sync of the app.
    // The app should begin to download songs chosen in the configure
    // sync view .
    function onStartSync() as Void {
        Communications.notifySyncComplete(null);
    }

    // Called by the system to determine if the app needs to be synced.
    function isSyncNeeded() as Boolean {
        return false;
    }

    // Called when the user chooses to cancel an active sync.
    function onStopSync() as Void {
        Communications.cancelAllRequests();
        Communications.notifySyncComplete(null);
    }
}

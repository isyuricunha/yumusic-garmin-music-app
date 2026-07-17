import Toybox.Lang;

// Returns a configured backend chosen by config["serverType"].
// Both backends expose the same *Neutral methods + getStreamUrl/getDownloadUrl
// (duck-typed; Monkey C has no interfaces).
module YuMusicApiFactory {
    function create(config as Dictionary) as YuMusicBackend {
        var type = config["serverType"] as String?;
        var maxBitRate = config["maxBitRate"] as String?;
        if (type != null && type.equals("jellyfin")) {
            var api = new YuMusicJellyfinAPI();
            api.configureJellyfin(config["serverUrl"] as String, config["apiKey"] as String, maxBitRate);
            return api;
        }
        var s = new YuMusicSubsonicAPI();
        s.configure(config["serverUrl"] as String, config["username"] as String,
                    config["password"] as String, maxBitRate, config["legacyAuth"] as Boolean?);
        return s;
    }
}

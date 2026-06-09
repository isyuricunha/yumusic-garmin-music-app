using Toybox.Test;

(:test)
function subsonicLegacyAuthBuildsEncodedUrl(logger) {
    var api = new YuMusicSubsonicAPI();
    var configured = api.configure({
        "serverUrl" => "http://192.168.1.10/music///",
        "username" => "runner@example.com",
        "password" => "p&ss word",
        "maxBitRate" => "192",
        "authMode" => YUMUSIC_AUTH_PASSWORD
    });
    var url = api.buildRequestUrl("ping");

    logger.debug(url);
    return configured
        && url.find("http://192.168.1.10/music/rest/ping.view?") == 0
        && url.find("u=runner%40example.com") != null
        && url.find("p=p%26ss%20word") != null
        && url.find("&t=") == null;
}

(:test)
function subsonicTokenAuthRemainsDefault(logger) {
    var api = new YuMusicSubsonicAPI();
    var configured = api.configure({
        "serverUrl" => "https://music.example.com",
        "username" => "runner",
        "password" => "secret",
        "maxBitRate" => "320"
    });
    var url = api.buildRequestUrl("ping");

    logger.debug(url);
    return configured
        && url.find("u=runner") != null
        && url.find("&t=") != null
        && url.find("&s=") != null
        && url.find("&p=") == null;
}

(:test)
function nextcloudApiKeyDoesNotRequireUsername(logger) {
    var api = new YuMusicSubsonicAPI();
    var configured = api.configure({
        "serverUrl" => "https://cloud.example.com/index.php/apps/music/subsonic",
        "username" => null,
        "password" => "key+value",
        "maxBitRate" => "128",
        "authMode" => YUMUSIC_AUTH_API_KEY
    });
    var url = api.buildRequestUrl("ping");

    logger.debug(url);
    return configured
        && url.find("apiKey=key%2Bvalue") != null
        && url.find("&u=") == null
        && url.find("&t=") == null;
}

(:test)
function subsonicProtocolErrorsAreReported(logger) {
    var api = new YuMusicSubsonicAPI();
    var error = api.getResponseError(200, {
        "subsonic-response" => {
            "status" => "failed",
            "error" => {
                "code" => 41,
                "message" => "Token authentication not supported"
            }
        }
    });

    logger.debug(error);
    return error != null && error.equals("41 token unsupported");
}

(:test)
function successfulSubsonicResponseHasNoError(logger) {
    var api = new YuMusicSubsonicAPI();
    var error = api.getResponseError(200, {
        "subsonic-response" => {
            "status" => "ok",
            "version" => "1.16.1"
        }
    });

    return error == null;
}

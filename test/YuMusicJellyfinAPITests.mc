using Toybox.Test;
import Toybox.Lang;

(:test)
function jellyfinDownloadUrlForcesBoundedMp3(logger) {
    var api = new YuMusicJellyfinAPI();
    var configured = api.configure({
        "serverUrl" => "http://192.168.1.20:8096///",
        "username" => "runner",
        "password" => "",
        "maxBitRate" => "128",
        "backendType" => YUMUSIC_BACKEND_JELLYFIN
    });
    api.onAuthenticated(200, {
        "AccessToken" => "access+token",
        "User" => {
            "Id" => "user-id"
        }
    });

    var url = api.getDownloadUrlForSong({
        "id" => "jellyfin:item-id",
        "sourceId" => "item-id"
    });

    logger.debug(url);
    return configured
        && url.find("http://192.168.1.20:8096/Audio/item-id/stream.mp3?") == 0
        && url.find("AudioCodec=mp3") != null
        && url.find("AudioBitRate=128000") != null
        && url.find("AudioChannels=2") != null
        && url.find("EnableAutoStreamCopy=false") != null
        && url.find("AllowAudioStreamCopy=false") != null
        && url.find("api_key=access%2Btoken") != null;
}

(:test)
function jellyfinExtractsNormalizedPlaylistsAndSongs(logger) {
    var api = new YuMusicJellyfinAPI();
    var playlists = api.extractPlaylists({
        "Items" => [
            {
                "id" => "jellyfin:playlist-id",
                "sourceId" => "playlist-id",
                "name" => "Morning Run",
                "songCount" => 2
            }
        ]
    });
    var details = api.extractPlaylist({
        "Playlist" => {
            "id" => "jellyfin:playlist-id",
            "name" => "Morning Run"
        },
        "Items" => [
            {
                "id" => "jellyfin:song-id",
                "sourceId" => "song-id",
                "title" => "First Track"
            }
        ]
    });
    var songs = details != null ? details["songs"] as Array? : null;

    return playlists.size() == 1
        && details != null
        && songs != null
        && songs.size() == 1;
}

(:test)
function jellyfinReportsAuthenticationFailures(logger) {
    var api = new YuMusicJellyfinAPI();
    var unauthorized = api.getResponseError(401, null);
    var memory = api.getResponseError(-403, null);

    logger.debug(unauthorized);
    logger.debug(memory);
    return unauthorized != null
        && unauthorized.equals("401 invalid Jellyfin credentials")
        && memory != null
        && memory.equals("-403 out of memory");
}

(:test)
function backendFacadeKeepsSubsonicAsDefault(logger) {
    var backend = new YuMusicBackend();
    var configured = backend.configure({
        "serverUrl" => "https://music.example.com",
        "username" => "runner",
        "password" => "secret",
        "maxBitRate" => "192",
        "authMode" => YUMUSIC_AUTH_PASSWORD
    });
    var playlists = backend.extractPlaylists({
        "subsonic-response" => {
            "status" => "ok",
            "playlists" => {
                "playlist" => {
                    "id" => "playlist-id",
                    "name" => "Legacy Library"
                }
            }
        }
    });

    return configured && playlists.size() == 1;
}

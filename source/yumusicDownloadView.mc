import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// View for showing download progress
class yumusicDownloadView extends WatchUi.View {
    private var _playlistName as String;
    private var _status as String;
    private var _progress as Number;
    private var _totalSongs as Number;
    private var _currentSong as String;
    private var _isComplete as Boolean;
    private var _hasError as Boolean;
    private var _errorMessage as String;
    private const ORANGE = 0xFF6600;
    private const DARK_ORANGE = 0xCC5200;

    function initialize() {
        View.initialize();
        _playlistName = "";
        _status = "Preparing...";
        _progress = 0;
        _totalSongs = 0;
        _currentSong = "";
        _isComplete = false;
        _hasError = false;
        _errorMessage = "";
    }

    // Set playlist name
    function setPlaylistName(name as String) as Void {
        _playlistName = name;
        WatchUi.requestUpdate();
    }

    // Update progress
    function updateProgress(current as Number, total as Number, songName as String) as Void {
        _progress = current;
        _totalSongs = total;
        _currentSong = songName;
        _status = "Downloading...";
        _hasError = false;
        WatchUi.requestUpdate();
    }

    // Set complete
    function setComplete() as Void {
        _isComplete = true;
        _status = "Complete!";
        _hasError = false;
        WatchUi.requestUpdate();
    }

    // Set error
    function setError(message as String) as Void {
        _hasError = true;
        _errorMessage = message;
        _status = "Error";
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;
        var centerY = height / 2;
        
        // Pure black background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Title at top
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        var title = _playlistName;
        if (title.length() > 18) {
            title = title.substring(0, 15) + "...";
        }
        dc.drawText(
            centerX,
            height * 0.12,
            Graphics.FONT_TINY,
            title.toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
        
        // Draw orange line under title
        dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(centerX - 50, height * 0.16, centerX + 50, height * 0.16);
        
        if (_hasError) {
            // Show error
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 30,
                Graphics.FONT_SMALL,
                "✗ " + _status,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 10,
                Graphics.FONT_XTINY,
                _errorMessage,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                height * 0.85,
                Graphics.FONT_XTINY,
                "BACK to return",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else if (_isComplete) {
            // Show completion
            dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 30,
                Graphics.FONT_MEDIUM,
                "✓ Complete!",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY + 20,
                Graphics.FONT_SMALL,
                _totalSongs + " songs ready",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            dc.setColor(DARK_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                height * 0.85,
                Graphics.FONT_XTINY,
                "Go to Music Player",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        } else {
            // Show progress
            dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                centerY - 50,
                Graphics.FONT_SMALL,
                _status,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            
            // Progress bar
            if (_totalSongs > 0) {
                var percentage = (_progress * 100) / _totalSongs;
                var barWidth = width * 0.6;
                var barHeight = 8;
                var barX = centerX - (barWidth / 2);
                var barY = centerY - 10;
                
                // Background bar
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(barX, barY, barWidth, barHeight, 4);
                
                // Progress bar
                var progressWidth = (barWidth * percentage) / 100;
                dc.setColor(ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(barX, barY, progressWidth, barHeight, 4);
                
                // Progress text
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    centerY + 20,
                    Graphics.FONT_XTINY,
                    _progress + " / " + _totalSongs,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            
            // Current song
            if (_currentSong.length() > 0) {
                var songName = _currentSong;
                if (songName.length() > 20) {
                    songName = songName.substring(0, 17) + "...";
                }
                
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    centerX,
                    height * 0.75,
                    Graphics.FONT_XTINY,
                    songName,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
    }

    function onHide() as Void {
    }
}

# Development Guide

This guide is for developers looking to contribute, build, or test YuMusic locally.

## Prerequisites
1. Download and install the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/).
2. Install the **Monkey C** extension for Visual Studio Code.
3. Generate a Developer Key (`developer_key.der`) via the Monkey C extension.

## Building the App
YuMusic is compiled using the `monkeyc` compiler. The project configuration is managed by the `monkey.jungle` file, which tells the compiler where to find source code and resources.

To compile the app via command line for a specific device (e.g., Fenix 7):
```bash
monkeyc -d fenix7 -f monkey.jungle -y /path/to/your/developer_key.der -o app.prg
```

## Running in the Simulator
1. Start the Connect IQ Simulator from VS Code (`Ctrl+Shift+P` -> `Monkey C: Start Simulator`).
2. Run the app (`F5` in VS Code).
3. **Important**: In the simulator Settings, ensure you test with **Use Device HTTPS Requirements** enabled to simulate real-world networking constraints.

## Architecture Notes
* **Audio Content Provider**: YuMusic operates as a Garmin Audio Content Provider. 
* **State Management**: The app uses `Toybox.Application.Storage` and `Toybox.Application.Properties` to manage playlists and auth tokens.
* **Sync Flow**: Syncing is initiated by the Garmin OS over Wi-Fi, calling `yumusicSyncDelegate.mc`. Downloads must provide a valid `Content-Length` and `audio/*` content type.

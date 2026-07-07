# CrystalClear AI Audio Enhancer

A Flutter application for enhancing audio (and recording when available) by sending audio to a local enhancement API.

## Features

- Upload an audio file
- (Optional) Record audio from the microphone
- Play / pause the input
- Send audio to an enhancement endpoint
- Cancel enhancement
- Play and download the enhanced result

## Prerequisites

- Flutter (stable)
- An enhancement API running locally (or adjust the endpoint in the app code as needed)

## Setup

```bash
flutter pub get
```

## Run

### Mobile

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

## User flow (screenshots)

1. **Select file**
   - Tap **Select file**.
   - ![select files](ScreenShot/gh-resized/select%20files.jpg)

2. **Enhanced Audio - tap Enhance**
   - After selecting a file, tap **Enhance**.
   - ![tap enhanced audio](ScreenShot/gh-resized/tap%20enhanced%20audio.jpg)

3. **After enhancement is requested - load & play button becomes available**
   - Wait for the enhanced audio to load.
   - ![after enhenced load and play](ScreenShot/gh-resized/after%20enhenced%20load%20and%20play.jpg)

4. **Tap Load & Play**
   - Tap **Load and Play**.
   - ![after load and play then tap to play](ScreenShot/gh-resized/after%20enhenced%20load%20and%20play%20then%20tap%20to%20play.jpg)

> Note: Steps 5–6 (tap Play / remove background) are shown inside the last screenshot above.

## Notes

- This project is designed to call your own enhancement service. Do **not** hardcode API keys in the client.
- If recording is enabled on Android, ensure the microphone permission is configured via the relevant platform files.

## License

MIT


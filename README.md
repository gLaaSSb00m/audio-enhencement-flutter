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

## Notes

- This project is designed to call your own enhancement service. Do **not** hardcode API keys in the client.
- If recording is enabled on Android, ensure the microphone permission is configured via the relevant platform files.

## License

MIT


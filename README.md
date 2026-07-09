# CrystalClear AI Audio Enhancer

A Flutter application for enhancing audio (and recording when available) by sending audio to an enhancement API and then playing/downloading the enhanced result.

## Features

- Select an audio file
- (Optional) Record audio from the microphone
- Play / pause the input audio
- Send the selected audio to an enhancement endpoint
- Cancel an in-progress enhancement request
- Load and play the enhanced audio
- Save/download the enhanced output

## Architecture (high level)

- The app uploads the selected/recorded audio as `multipart/form-data`.
- The enhancement service returns enhanced audio bytes.
- The app writes the returned bytes to a temporary `.wav` file and uses Flutter audio playback (`just_audio`) to play it.

## Prerequisites

- Flutter (stable)
- An enhancement API endpoint that accepts an uploaded file and returns enhanced audio bytes.

> The API URL is defined in the app code. If you host your own service, update the endpoint accordingly.

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

## App source / where the apps were found

The reference where the apps were found is here:
- [Download Apps](https://drive.google.com/file/d/10aseyOg_ZM7HSBZYG3Vb34Xuwq3L6Hxu/view?usp=sharing)

## User flow (screenshots)



1. **Select file**
   - Tap **Select file**.
   <img src="ScreenShot/select%20files.jpg" width="280" alt="select files" />

2. **Enhanced Audio - tap Enhance**
   - After selecting a file, tap **Enhance**.
   <img src="ScreenShot/tap%20enhanced%20audio.jpg" width="280" alt="tap enhanced audio" />

3. **During enhancement**
   - Wait for the enhancement request to complete (progress is shown).


4. **Load & Play**
   - Tap **Load and Play** when the enhanced audio is ready.
   <img src="ScreenShot/after%20enhenced%20load%20and%20play.jpg" width="280" alt="after load and play then tap to play" />

5. **Play the enhanced result**
   - Tap **Play** to listen.
   <img src="ScreenShot/after%20load%20and%20play%20then%20tap%20to%20play.jpg" width="280" alt="after enhancement" />

6. **Use the enhanced output**
   - Use the enhanced result for clarity/improved audio quality.

## Notes / Considerations

- Do **not** hardcode API keys in the Flutter client. Put secrets in your server.
- If recording is enabled on Android, ensure microphone permission is configured for the target platforms.

## License

MIT


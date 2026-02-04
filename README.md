# CrystalClear AI Audio Enhancer (Vanilla HTML/CSS/JS)

A minimal, client‑side web interface for enhancing audio files via a local HTTP API. This version is framework‑free (no React/TypeScript/Vite) and runs as a static site consisting of `index.html`, `index.css`, and `index.js`.

## Overview

- Upload an audio file
- Play/Pause with a simple canvas waveform visualizer
- Send the file to your local enhancement API as `multipart/form-data` with field name `file`
- Receive the enhanced audio as binary and download or play it in the browser
- Shows upload progress and a processing indicator
- API endpoint is hardcoded (not visible in the UI)

By default, the client targets the local endpoint:

```
POST http://127.0.0.1:7860/direct-enhance
Form field: file
Response: audio/wav (or other binary audio)
```

This matches the curl you provided:

```
curl.exe -X POST "http://127.0.0.1:7860/direct-enhance" -F "file=@.\mixed_nosie\mixed_noisem01.wav" --output enhanced.wav
```

## Project Structure

- `index.html` – Static UI layout (file input, controls, progress bars, results)
- `index.css` – Global styles and basic layout helpers
- `index.js` – All application logic (audio playback, visualization, XHR upload, handling response)
- `.gitignore` – Common ignores for a static site repo
- `README.md` – This document

All React/TypeScript/Vite files were removed to keep the project as a clean static site.

## Features

- File selection: accepts standard audio types
- Playback controls: play/pause with HTMLAudioElement
- Visualizer: simple time‑domain waveform using Web Audio API (AnalyserNode)
- Enhancement request: multipart upload via XMLHttpRequest (shows true upload progress)
- Progress UI:
  - Upload progress bar: reflects real percent uploaded
  - Processing bar: animated while awaiting the server response after upload completes
- Result handling: provides a download link and an inline audio player for the enhanced file
- Cancel: aborts in‑flight request

## Configuration

- API endpoint is hardcoded inside `index.js` to avoid exposing it in the UI:

```js
// index.js
const API_URL = 'http://127.0.0.1:7860/direct-enhance';
```

Change this constant if your server runs elsewhere or under a different path.

## Running Locally

Because browsers may restrict file access and CORS when opening `index.html` directly via `file://`, use one of the following approaches:

1) Open directly (quick test)
- Double‑click `index.html` and test. If you see network or CORS issues, use a static server.

2) Serve with a static server (recommended)
- Use any static server you prefer (examples):
  - Python: `python -m http.server 8080`
  - Node: `npx http-server -p 8080`
  - BusyBox: `busybox httpd -f -p 8080`
- Then open `http://127.0.0.1:8080` in your browser.

Ensure your backend is running and reachable at the URL in `API_URL`.

## API Expectations

- Method: `POST`
- URL: `http://127.0.0.1:7860/direct-enhance` (configurable in `index.js`)
- Request body: `multipart/form-data`
  - Field name: `file`
  - Value: selected audio file (the browser supplies the filename)
- Response: binary audio data (e.g., `audio/wav`)

The client treats the response as a `Blob`, creates an object URL, and enables download/playback.

## CORS

If you encounter CORS errors:
- Enable CORS in your backend to allow requests from your site origin
- Or serve this frontend through a proxy that forwards to your backend
- When testing locally via static server, your backend should allow `http://127.0.0.1:<port>`

## Troubleshooting

- No file selected / Enhance button disabled
  - Choose an audio file first; buttons become enabled after selection.
- Upload progress never starts
  - Verify backend URL in `index.js` is correct and the server is reachable.
- CORS error
  - Adjust backend CORS settings or use a local static server with matching origin.
- Response downloads but won’t play
  - Confirm the backend returns a valid audio format playable by your browser.
- Visualization not drawing
  - Some browsers require user interaction to resume the AudioContext. Start playback using the Play button.

## Browser Support

- Modern Chromium, Firefox, and Safari should work. Web Audio API and `XMLHttpRequest` upload progress are widely supported in modern browsers.

## License

This project is provided as‑is for local usage scenarios. Adapt as required for your environment.

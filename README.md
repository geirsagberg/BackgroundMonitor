# BackgroundMonitor

A tiny native macOS app for seeing processes you started from a shell that are still running in the background.

## What counts as a background process

A process you own that is not a shell, is not the foreground job of a terminal, and either:

- has a shell among its ancestors (a `&` job, or a command run by an agent's shell), or
- was orphaned while still attached to a terminal (`disown`, `nohup`).

Processes started by a listed process are grouped under it.

## Features

- Shows name, working folder, command, uptime, memory, PID, and terminal.
- Kill sends `SIGTERM` to the process and its children. Force Kill sends `SIGKILL`.
- Ignore hides every process with the same command line. Toggle "Show ignored" to see and unignore them.
- Sorts by name or PID.
- Refreshes every 2 seconds.
- Includes a macOS menu bar extra. The Dock icon shows only while the window is open.
- Uses a custom app icon built from the open-source Lucide `terminal` icon.

## Run

```sh
swift run BackgroundMonitor
```

## Build a `.app`

```sh
./scripts/build-app.sh
open .build/BackgroundMonitor.app
```

The build script needs either `rsvg-convert` from librsvg or ImageMagick's `magick` command to render `Resources/AppIcon.svg` into a macOS `.icns`.

## Manual GitHub Release

Run the `Build macOS Release` workflow from the GitHub Actions tab. It creates a GitHub Release and attaches both a zipped `.app` bundle and the raw macOS executable.

Ignored commands are stored in `~/Library/Application Support/BackgroundMonitor/Ignored.json`.

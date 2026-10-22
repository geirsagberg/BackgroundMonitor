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
- Ignore hides every process with the same command line. Ignore rules also take glob patterns such as `*gitstatusd*`, matched against the full command line. Toggle "Show ignored" to see ignored processes.
- Sorts by name or PID.
- Refreshes every 2 seconds. Use the refresh button or ⌘R to refresh the current view immediately.
- Includes a macOS menu bar extra. The Dock icon shows only while the window is open.
- Uses a custom app icon built from the open-source Lucide `terminal` icon.

## tmux sessions

Switch to **tmux** to see local sessions, their window counts, and attached or detached state. **Open** attaches in the default macOS application for Unix executables without disconnecting existing clients. Sessions are also available from **tmux Sessions** in the menu bar.

To use iTerm2, choose **iTerm2 > Make iTerm2 Default Term** in iTerm2. BackgroundMonitor respects that association; it does not change your default terminal.

Install tmux separately, for example with `brew install tmux`. BackgroundMonitor checks `PATH`, `/opt/homebrew/bin`, `/usr/local/bin`, and `~/.local/bin`, and refreshes sessions every two seconds.

Discovery covers sockets owned by you in `/tmp/tmux-<uid>` and `$TMUX_TMPDIR/tmux-<uid>`, plus the socket in an inherited `$TMUX` variable. This includes named servers in those directories. Arbitrary `tmux -S` paths outside those locations and sessions on remote hosts are not discovered automatically. GUI launches only see environment variables inherited by the app.

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

Ignore rules are stored in `~/Library/Application Support/BackgroundMonitor/Ignored.json`.

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
- Includes a menu bar extra.

## Run

```sh
swift run BackgroundMonitor
```

## Build a `.app`

```sh
./scripts/build-app.sh
open .build/BackgroundMonitor.app
```

Ignored commands are stored in `~/Library/Application Support/BackgroundMonitor/Ignored.json`.

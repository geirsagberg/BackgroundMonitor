# BackgroundMonitor

BackgroundMonitor is a native macOS app for seeing and stopping processes started from a shell that keep running in the background. This context names the app concepts that should shape modules and tests.

## Language

**Background job**:
A user-owned process that is not a shell and not in the terminal foreground, and that either has a shell among its ancestors or was orphaned while still attached to a terminal. Processes it started are grouped under it rather than listed on their own.
_Avoid_: task, service, daemon

**Shell**:
A command interpreter such as `zsh`, `bash`, or `fish`. Shells are never listed; they only mark where background jobs come from.
_Avoid_: terminal, session

**Terminal foreground**:
The process group a terminal is currently showing. Processes in it are visible in their terminal already and are not background jobs.
_Avoid_: active, attached

**Ignored command**:
A command line the user chose to hide. Every background job with the same command line is ignored, and ignored jobs show only when the user asks for them.
_Avoid_: hidden, muted, excluded

**Job presentation**:
The view of a background job used by the window and menu bar. It adds the display name, command line, working folder, total memory, and ignored state to the discovered process facts, keeping each one as a separate fact.
_Avoid_: row, view model row

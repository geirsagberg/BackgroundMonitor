---
name: BackgroundMonitor
description: Native macOS utility for seeing and stopping background jobs started from a shell.
colors:
  window-background: "#F5F5F5"
  control-background: "#FFFFFF"
  primary-text: "#1D1D1F"
  secondary-text: "#6E6E73"
  separator: "#D2D2D7"
  accent: "#0A84FF"
  destructive: "#D70015"
  badge-fill: "#E8E8ED"
typography:
  display:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.2
  title:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.25
  body:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.35
  command:
    fontFamily: "SF Mono, ui-monospace, monospace"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.2
  label:
    fontFamily: "SF Pro, -apple-system, BlinkMacSystemFont, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.2
rounded:
  sm: "7px"
  md: "8px"
spacing:
  xs: "6px"
  sm: "8px"
  md: "10px"
  lg: "12px"
  xl: "14px"
  xxl: "16px"
  empty: "32px"
components:
  button-kill:
    backgroundColor: "{colors.control-background}"
    textColor: "{colors.destructive}"
    rounded: "{rounded.md}"
    padding: "5px 10px"
  metadata-badge:
    backgroundColor: "{colors.badge-fill}"
    textColor: "{colors.secondary-text}"
    rounded: "999px"
    padding: "2px 6px"
  job-row:
    backgroundColor: "{colors.control-background}"
    textColor: "{colors.primary-text}"
    rounded: "{rounded.md}"
    padding: "10px"
---

# Design System: BackgroundMonitor

## 1. Overview

BackgroundMonitor should feel like the small native console a developer opens to see what they left running: quiet, sharp, and instantly readable. It shares its visual system with LocalHostMonitor. It favors native macOS controls, system colors, compact rhythm, and clear action hierarchy over brand theatrics.

It is not Activity Monitor. It lists only background jobs the user started from a shell, keeps job identity separate from process facts, and makes stopping a job obvious without making the interface loud.

**Key Characteristics:**
- Native macOS materials and controls first.
- Restrained density with enough spacing to scan rows quickly.
- Metadata stays compact, separate, and factual.
- Kill is the one row action that is always visible, and it is clearly destructive.

## 2. Colors

The palette is the native macOS system palette. Semantic platform colors do the work.

- **Destructive Red**: Used only for Kill. In SwiftUI, use a destructive button role, a red icon, and an explicit label in primary text. Red text on a bordered button has too little contrast in dark mode.
- **Window Background**: `Color(nsColor: .windowBackgroundColor)`.
- **Control Background**: Job rows and the filter field, through `Color(nsColor: .controlBackgroundColor)`.
- **Primary and Secondary Text**: `.foregroundStyle(.primary)` for names; `.secondary` for folders, commands, counts, and badges.
- **Separator**: Row outlines and dividers through `Color(nsColor: .separatorColor)` with reduced opacity.
- **Badge Fill**: `Color(nsColor: .quaternaryLabelColor)` at reduced opacity.

**The Platform Color Rule.** Use semantic macOS colors in SwiftUI, not fixed hex values.

## 3. Typography

- **Display** (semibold, 22px): Window header title only.
- **Title** (semibold, 14px): Job name.
- **Body** (callout): Working folder next to the name.
- **Command** (monospaced caption): The full command line, truncated in the middle.
- **Label** (caption, monospaced digits): Uptime, memory, PID, terminal, and child count badges.

**The Native Scale Rule.** Use platform text styles and small explicit sizes. No decorative type or marketing hierarchy.

## 4. Elevation

Tonal layering, no shadows. Rows are a control background with a one-pixel separator stroke at 35% opacity.

## 5. Components

### Buttons
- **Kill:** Bordered, destructive role, primary-text label with a red `stop.circle` symbol. Sends SIGTERM to the job and its children.
- **More actions:** Borderless `ellipsis.circle` menu with Force Kill, Ignore or Unignore, Copy Command, and Show Folder in Finder. A job ignored only by a broader pattern offers Edit Ignore Rules… instead of Unignore.
- **Header:** A Processes / tmux segmented picker beside the title. A second row holds the filter and, for processes, a segmented Name / PID sort picker, a "Show ignored" switch, and an `eye.slash` button that opens the Ignore Rules sheet.

### Ignore Rules Sheet
A native sheet with a monospaced pattern field, an Add button, and a list of rules showing how many running jobs each one matches.

### Badges
Compact capsules with secondary text and an optional SF Symbol. Badges are informational only.

### Job Rows
8px corners, 10px padding, 8px list spacing, 14px scroll padding. Ignored jobs render at reduced opacity and carry an "Ignored" badge, so opacity is never the only cue.

### tmux Sessions
Session rows follow the job row spacing and colors. Show the session name, window count, attached or detached state, and socket path. Open is the visible row action and attaches in the default terminal. Session discovery errors offer Refresh.

### Menu Bar
Native menu UI: Show Window, one submenu per job with Kill, Force Kill, and Ignore, a tmux Sessions submenu with one Open action per session, then Quit.

## 6. Do's and Don'ts

### Do:
- **Do** use native macOS semantic colors and controls.
- **Do** keep name, folder, command, uptime, memory, PID, and terminal as distinct facts.
- **Do** keep destructive actions explicit and labeled.

### Don't:
- **Don't** add CPU graphs, dashboards, gradients, or terminal-cosplay styling.
- **Don't** list system or app processes the user did not start from a shell.
- **Don't** add card shadows, glassmorphism, or oversized rounded containers.
- **Don't** hide Kill behind an ambiguous icon.

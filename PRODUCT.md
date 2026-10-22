# Product

## Register

product

## Users

BackgroundMonitor is for developers on macOS who start long-running commands from terminals and coding agents. Dev servers, watchers, and scripts pile up across tabs and agent sessions, and some keep running after their terminal or agent is gone. Users want to see what is still running, where it was started, and stop it without hunting through `ps` output.

## Product Purpose

BackgroundMonitor finds background jobs started from a shell, presents the useful facts about each one in a native macOS window and menu bar extra, and lets users act on each job directly. It also lists local tmux sessions and opens them in the default terminal. Success means a developer can understand what they left running at a glance, stop the right job with confidence, and hide the noise they never want to see.

## Brand Personality

Quiet, sharp, native. The product should feel like a focused macOS utility: restrained, legible, fast, and trustworthy. It belongs next to LocalHostMonitor and should feel like the same family.

## Anti-references

Avoid Activity Monitor clones, decorative dashboards, CPU graphs, loud gradients, terminal-cosplay styling, and anything that makes cleaning up processes feel heavier than the task itself. Avoid system-monitoring language when the app is specifically about jobs the user started. Avoid visual treatments that fight native macOS affordances or make destructive actions feel casual.

## Design Principles

Make what is still running legible at a glance.

Show only what the user started; leave system and app processes out.

Use native macOS patterns as the baseline for trust, speed, and accessibility.

Keep identity separate from metadata: name, folder, command, uptime, memory, PID, and terminal remain distinct facts.

Treat destructive actions as precise tools, not dramatic moments.

## Accessibility & Inclusion

Target WCAG AA contrast and preserve macOS accessibility conventions for focus, keyboard access, VoiceOver labeling, native controls, and system color behavior. Color should never be the only cue for state or destructive actions.

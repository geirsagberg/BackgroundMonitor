# Issue tracker: GitHub

Issues and PRDs for this repo live as GitHub issues in `geirsagberg/BackgroundMonitor`. Use the `gh` CLI for all issue-tracker operations.

## Conventions

- **Create an issue**: `gh issue create --repo geirsagberg/BackgroundMonitor --title "..." --body-file <file> --label "ready-for-agent"`
- **Read an issue**: `gh issue view <number> --repo geirsagberg/BackgroundMonitor --comments`
- **List issues**: `gh issue list --repo geirsagberg/BackgroundMonitor --state open --json number,title,body,labels,comments`
- **Comment on an issue**: `gh issue comment <number> --repo geirsagberg/BackgroundMonitor --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --repo geirsagberg/BackgroundMonitor --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --repo geirsagberg/BackgroundMonitor --comment "..."`

## When a skill says "publish to the issue tracker"

Create a GitHub issue in `geirsagberg/BackgroundMonitor`.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --repo geirsagberg/BackgroundMonitor --comments`.

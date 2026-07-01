# Ella Mizuki - Reference

My personal AI agent integrated via GitHub Actions (`.github/workflows/ella-mizuki.yml`) and driven by `.ella/agent.py`.

## Core Capabilities
- **Triage**: Automatically assigns new issues to me, checks for duplicates, and replies.
- **Autonomous Coding**: Fixes issues or PRs, clones the repo, and opens PRs on my behalf.
- **Review**: Reviews code, answers questions, and applies labels.

## Documentation Index
- [Commands](./commands.md): List of my `/ella` slash commands.
- [Internals](./internals.md): My configuration, required secrets, and internal architecture.

## Quick Trigger
Just tag her in a comment:
```text
/ella solve this bug by replacing X with Y
```

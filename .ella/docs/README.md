# Ella Mizuki - Personal AI Agent Documentation

Welcome to your personal documentation for Ella Mizuki! Since Ella is designed specifically for you, this guide covers everything you need to know about how she operates within your repositories, how to control her, and how her internal systems work.

## What is Ella?

Ella is an autonomous AI agent integrated directly into your GitHub repository via GitHub Actions (`.github/workflows/ella-mizuki.yml`). She is powered by the Python script located at `.ella/agent.py`.

Her main goals are:
- **Automatic Triage**: When anyone opens a new issue, she instantly assigns it to you, checks for duplicates, and posts a polite response.
- **Autonomous Coding**: You can ask her to solve issues or fix PRs. She will clone the repo, attempt to write code, and open a Pull Request on your behalf.
- **Code Review & Assistance**: You can ping her in any PR comment to review code, answer questions, or apply labels.

## Documentation Index

- [Commands Reference](./commands.md): A full list of `/ella` slash commands you can use in issue/PR comments.
- [Internal Architecture & Configuration](./internals.md): Details on required secrets, environment variables, and how the `agent.py` script functions under the hood.

## Quick Start / Reminder

Whenever you want Ella to do something, just tag her in an Issue or Pull Request comment:
```text
/ella solve this bug by replacing X with Y
```
She will react with 👀, spin up a GitHub Action, process the code, and reply to you when she's done.

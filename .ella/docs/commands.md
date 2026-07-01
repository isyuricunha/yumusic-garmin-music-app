# Ella Commands

Slash commands I can use to trigger Ella. For security, she only responds to my GitHub account (`isyuricunha`).

### General
- `/ella ask <question>`: Answers questions based on issue/PR context.
- `/ella help`: Lists available commands.
- `/ella label`: Applies the most relevant labels defined in `.ella/labels.json`.

### Pull Requests
*(Only work in PR comments)*
- `/ella pr <request>`: Short PR analysis (changes, risks, safe to merge).
- `/ella review <request>`: Strict code review (bugs, security, missing tests).
- `/ella plan <request>`: Writes an implementation plan without modifying code.
- `/ella fix <request>`: Checks out the branch, applies a fix, and commits directly.
- `/ella continue <request>`: Continues trying to fix if the time/attempt limit was hit.

### Issues
*(Only work in Issue comments)*
- `/ella solve <request>`: Creates a new branch, attempts a fix, and opens a new PR.

### Automated
- **Triage**: Runs automatically when any issue is opened. Assigns it to me, checks for similar open issues, and leaves a welcome message.

# Ella Commands Reference

Ella listens to specific slash commands when you post a comment on an Issue or Pull Request. Remember: For security reasons, Ella only responds to commands executed by **your GitHub account** (`isyuricunha`).

### General Commands
- `/ella ask <question>`: Ella will answer your question based on the context of the issue or PR using the configured LLM.
- `/ella help`: Displays a quick list of all available commands.
- `/ella label`: Reads the context of the issue/PR and automatically applies the most relevant labels defined in `.ella/labels.json`.

### Pull Request Commands
*(These commands only work when used in a comment inside an existing Pull Request)*
- `/ella pr <request>`: Gives a short, practical PR analysis. Explains what changed, possible risks, and if it's safe to merge.
- `/ella review <request>`: Performs a strict code review. Looks for bugs, security risks, regressions, type issues, and missing tests.
- `/ella plan <request>`: Writes an implementation plan for a change without actually modifying any code.
- `/ella fix <request>`: Ella checks out the PR branch, attempts to fix the problem you described, and commits the code directly to the branch.
- `/ella continue <request>`: If Ella hit her time/attempt limit while trying to fix something, this tells her to keep trying from where she left off.

### Issue Commands
*(These commands only work when used in a comment inside an existing Issue)*
- `/ella solve <request>`: Ella will create a new branch, attempt to solve the issue with the smallest safe change possible, run checks, and automatically open a new Pull Request fixing the issue.

### Automated Behaviors
- **Triage**: Ella doesn't need a slash command to triage. The moment an issue is opened by anyone, she will assign it to you, search for similar open issues, and leave a polite welcome message.

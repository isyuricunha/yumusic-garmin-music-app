# Ella Internal Architecture & Configuration

Ella is essentially a standalone Python script (`.ella/agent.py`) that gets executed by a GitHub Actions workflow (`.github/workflows/ella-mizuki.yml`). She uses the `gh` CLI for all GitHub interactions and an OpenAI-compatible API for her reasoning.

## How it Works

1. **Trigger**: The GitHub Action is triggered by `issues: [opened]` or `issue_comment: [created]`.
2. **Authentication**: The workflow uses `actions/create-github-app-token@v3` to generate a temporary, highly-privileged token so Ella can push code, edit issues, and leave comments.
3. **Execution**: The workflow runs `python3 .ella/agent.py`.
4. **Context Gathering**: Ella reads the `GITHUB_EVENT_PATH` JSON to understand what issue/PR she's in, who commented, and what they said. She uses `gh` CLI commands to fetch PR diffs, issue descriptions, and directory structures.
5. **AI Interaction**: She sends the context and instructions to the configured AI Model. For complex commands like `/ella fix`, she does this in a continuous loop until tests pass or she hits her limits.
6. **Actions**: She uses Git and `gh` to commit code, push branches, open PRs, and leave comments.

## Configuration (Secrets)

Ella requires several secrets to be set in your GitHub Repository settings (`Settings > Secrets and variables > Actions`):

### Required Secrets
- `ELLA_AI_BASE_URL`: The base URL for the OpenAI-compatible API (e.g., `https://api.openai.com/v1`).
- `ELLA_AI_MODEL`: The specific model to use (e.g., `gpt-4o`, `claude-3-5-sonnet`).
- `ELLA_AI_API_KEY`: The API key for the AI provider.
- `ELLA_APP_CLIENT_ID` / `ELLA_APP_PRIVATE_KEY`: Credentials for the GitHub App used to generate the temporary token.
- `YURI_COMMIT_NAME` / `YURI_COMMIT_EMAIL`: The Git author details she will use when committing code on your behalf.

### Optional Limits & Token Controls
You can fine-tune Ella's token usage and attempt limits using these optional secrets:

- `ELLA_MAX_ATTEMPTS`: Max loops she will try to fix a bug (Default: 15).
- `ELLA_TIME_LIMIT_SECONDS`: Max execution time (Default: 3600s / 1hr).
- `ELLA_MAX_TOKENS_*`: Set limits for specific modes (e.g., `_ASK`, `_PR`, `_FIX`, `_SOLVE`, `_TRIAGE`).
- `ELLA_MAX_CONTEXT_*_BYTES`: Limits the amount of raw diff/file data she reads into context to save tokens.

## Internal Files
- `.ella/agent.py`: The brain of the operation.
- `.ella/instructions.md`: Custom instructions/context fed to Ella on every run.
- `.ella/labels.json`: The definitions of labels used by `/ella label`.
- `.ella/ignore`: Globs/patterns of files Ella should ignore when searching or fixing code.

# Ella Internals & Configuration

Architecture details and configuration for my Ella agent.

## Execution Flow
1. **Trigger**: Triggered by `issues: [opened]` or `issue_comment: [created]`.
2. **Auth**: Uses `actions/create-github-app-token@v3` for a temporary, highly-privileged token.
3. **Run**: Executes `python3 .ella/agent.py`.
4. **Context**: Reads `GITHUB_EVENT_PATH` and uses `gh` CLI to fetch PR diffs, issues, and directories.
5. **AI**: Sends context to the configured LLM. For complex tasks (e.g., `/ella fix`), loops until tests pass or limits hit.
6. **Actions**: Uses Git and `gh` to commit, push, open PRs, and comment.

## Secrets
My required repository secrets (`Settings > Secrets and variables > Actions`):

- `ELLA_AI_BASE_URL`: Base URL for the OpenAI-compatible API.
- `ELLA_AI_MODEL`: Model name (e.g., `gpt-4o`, `claude-3-5-sonnet`).
- `ELLA_AI_API_KEY`: API key.
- `ELLA_APP_CLIENT_ID` / `ELLA_APP_PRIVATE_KEY`: GitHub App credentials for token generation.
- `YURI_COMMIT_NAME` / `YURI_COMMIT_EMAIL`: My Git author details for her commits.

### Limits & Token Controls
Optional secrets to fine-tune her limits:
- `ELLA_MAX_ATTEMPTS`: Max loops for fixes (Default: 15).
- `ELLA_TIME_LIMIT_SECONDS`: Max execution time (Default: 3600s).
- `ELLA_MAX_TOKENS_*`: Limits for specific modes (`_ASK`, `_PR`, `_FIX`, `_SOLVE`, `_TRIAGE`).
- `ELLA_MAX_CONTEXT_*_BYTES`: Limits raw diff/file data context size.

## Files
- `.ella/agent.py`: Core script.
- `.ella/instructions.md`: Custom system instructions I feed to her on every run.
- `.ella/labels.json`: Definitions for `/ella label`.
- `.ella/ignore`: Globs/patterns of files she should ignore.

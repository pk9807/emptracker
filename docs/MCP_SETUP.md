# MCP TOOLING & ENVIRONMENT CAPABILITIES

## 1. Detected Tooling & Integrations
- **Filesystem & Git Tooling:** Git CLI initialized, native file editing (`write_to_file`, `replace_file_content`, `multi_replace_file_content`), directory inspection (`list_dir`, `grep_search`).
- **Terminal Execution:** Bash command execution (`run_command`) with process management (`manage_task`).
- **Web & Inspection Tools:** `read_url_content`, `search_web`, `browser_subagent` for automated browser dashboard validation.
- **Asset Generation:** `generate_image` for realistic mock assets, company logos, and product badges.

## 2. MCP Usage Policy
- Production secrets (.env, service accounts) are never committed.
- Offline-first code logic uses local mocks and emulators during development.
- UI validation for Admin Web Dashboard performed via browser tools.

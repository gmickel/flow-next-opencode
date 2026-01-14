# rp-cli Reference

> Requires RepoPrompt v1.5.62+

## Command Syntax

```bash
rp-cli -w <window_id> -e '<command>'
rp-cli -w <window_id> -t <tab> -e '<command>'   # Target specific tab (v1.5.62+)
```

## Quick Reference

| MCP Tool | CLI Command |
|----------|-------------|
| `list_windows` | `rp-cli -e 'windows'` |
| `get_file_tree` | `rp-cli -w <id> -e 'tree'` |
| `file_search` | `rp-cli -w <id> -e 'search "pattern"'` |
| `read_file` | `rp-cli -w <id> -e 'read path/file'` |
| `manage_selection` | `rp-cli -w <id> -e 'select add path/'` |
| `context_builder` | `rp-cli -w <id> -e 'builder "instructions"'` |
| `chat_send` | `rp-cli -w <id> -e 'chat "message" --mode chat'` |
| `chats` | `rp-cli -w <id> -e 'chats list'` |
| `list_tabs` | `rp-cli -w <id> -e 'workspace tabs'` |
| `select_tab` | `rp-cli -w <id> -t "name" -e '...'` |
| `prompt export` | `rp-cli -w <id> -e 'prompt export /path/file.md'` |
| `prompt presets` | `rp-cli -w <id> -e 'prompt presets'` |

## Common Commands

### Window Management
```bash
# List all windows
rp-cli -e 'windows'

# Get file tree (folders only)
rp-cli -w 1 -e 'tree --folders'
```

### File Operations
```bash
# Search for files by path
rp-cli -w 1 -e 'search "pattern" --mode path'

# Read a file
rp-cli -w 1 -e 'read path/to/file.ts'
```

### Selection Management
```bash
# Add file to selection
rp-cli -w 1 -e 'select add path/to/file.ts'

# Get current selection
rp-cli -w 1 -e 'select get'

# Clear selection
rp-cli -w 1 -e 'select clear'
```

### Context Builder
```bash
# Build context (takes 30s-5min)
rp-cli -w 1 -e 'builder "Build context for [TASK]. Focus on [AREAS]."'
```

### Chat
```bash
# Start new chat (MUST use raw call - shorthand --new-chat is broken)
rp-cli -w 1 -e 'call chat_send {"message": "Your prompt", "mode": "chat", "new_chat": true, "chat_name": "Chat Name"}'

# Continue most recent chat (shorthand works for this)
rp-cli -w 1 -e 'chat "Follow-up question" --mode chat'

# List chats (get IDs and names)
rp-cli -w 1 -e 'chats list'

# Continue specific chat by ID
rp-cli -w 1 -e 'chat "Follow-up" --mode chat --chat-id <id>'
```

### Tab Management
```bash
# List tabs (chats are bound to tabs)
rp-cli -w 1 -e 'workspace tabs'

# Target tab directly (v1.5.62+ - preferred)
rp-cli -w 1 -t "TabName" -e 'select get'
rp-cli -w 1 -t "<UUID>" -e 'chat "follow-up" --mode chat'

# Or bind via command (legacy)
rp-cli -w 1 -e 'workspace tab "TabName"'
```

### Prompt Export
```bash
# Export full context (files, tree, codemaps) to file
rp-cli -w 1 -e 'prompt export /path/to/output.md'
```

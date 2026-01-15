---
name: browser
description: Browser automation via agent-browser CLI. Use when you need to navigate websites, verify deployed UI, test web apps, read online documentation, scrape data, fill forms, capture baseline screenshots before design work, or inspect current page state. Triggers on "check the page", "verify UI", "test the site", "read docs at", "look up API", "visit URL", "browse", "screenshot", "scrape", "e2e test", "login flow", "capture baseline", "see how it looks", "inspect current", "before redesign".
---

# Browser Automation

Browser automation via Vercel's agent-browser CLI. Runs headless by default; use `--headed` for visible window. Uses ref-based selection (@e1, @e2) from accessibility snapshots.

## Setup

```bash
command -v agent-browser >/dev/null 2>&1 && echo "OK" || echo "MISSING: npm i -g agent-browser && agent-browser install"
```

## Core Workflow

1. **Open** URL
2. **Snapshot** to get refs
3. **Interact** via refs
4. **Re-snapshot** after DOM changes

```bash
agent-browser open https://example.com
agent-browser snapshot -i              # Interactive elements with refs
agent-browser click @e1
agent-browser wait --load networkidle  # Wait for SPA to settle
agent-browser snapshot -i              # Re-snapshot after change
```

## Essential Commands

### Navigation

```bash
agent-browser open <url>       # Navigate
agent-browser back             # Go back
agent-browser forward          # Go forward
agent-browser reload           # Reload
agent-browser close            # Close browser
```

### Snapshots

```bash
agent-browser snapshot           # Full accessibility tree
agent-browser snapshot -i        # Interactive only (recommended)
agent-browser snapshot -i --json # JSON for parsing
agent-browser snapshot -c        # Compact (remove empty)
agent-browser snapshot -d 3      # Limit depth
agent-browser snapshot -s "#main" # Scope to selector
```

### Interactions

```bash
agent-browser click @e1              # Click
agent-browser dblclick @e1           # Double-click
agent-browser fill @e1 "text"        # Clear + fill input
agent-browser type @e1 "text"        # Type without clearing
agent-browser press Enter            # Key press
agent-browser press Control+a        # Key combination
agent-browser hover @e1              # Hover
agent-browser check @e1              # Check checkbox
agent-browser uncheck @e1            # Uncheck
agent-browser select @e1 "option"    # Dropdown
agent-browser scroll down 500        # Scroll direction + pixels
agent-browser scrollintoview @e1     # Scroll element visible
```

### Get Info

```bash
agent-browser get text @e1       # Element text
agent-browser get value @e1      # Input value
agent-browser get html @e1       # Element HTML
agent-browser get attr href @e1  # Attribute
agent-browser get title          # Page title
agent-browser get url            # Current URL
agent-browser get count "button" # Count matches
```

### Check State

```bash
agent-browser is visible @e1    # Check visibility
agent-browser is enabled @e1    # Check enabled
agent-browser is checked @e1    # Check checkbox state
```

### Wait

```bash
agent-browser wait @e1                 # Wait for element visible
agent-browser wait 2000                # Wait milliseconds
agent-browser wait --text "Success"    # Wait for text
agent-browser wait --url "**/dashboard" # Wait for URL pattern
agent-browser wait --load networkidle  # Wait for network idle (SPAs)
agent-browser wait --fn "window.ready" # Wait for JS condition
```

### Screenshots

```bash
agent-browser screenshot              # Viewport to stdout
agent-browser screenshot out.png      # Save to file
agent-browser screenshot --full       # Full page
agent-browser pdf out.pdf             # Save as PDF
```

### Semantic Locators

Alternative when you know the element (no snapshot needed, see [advanced.md](references/advanced.md) for tabs, frames, network mocking):

```bash
agent-browser find role button click --name "Submit"
agent-browser find text "Sign In" click
agent-browser find label "Email" fill "user@test.com"
agent-browser find placeholder "Search" fill "query"
agent-browser find first ".item" click
agent-browser find nth 2 "a" text
```

## Sessions

Parallel isolated browsers (see [auth.md](references/auth.md) for multi-user auth):

```bash
agent-browser --session test1 open site-a.com
agent-browser --session test2 open site-b.com
agent-browser session list
```

## JSON Output

Add `--json` for machine-readable output:

```bash
agent-browser snapshot -i --json
agent-browser get text @e1 --json
agent-browser is visible @e1 --json
```

## Examples

### Form Submission

```bash
agent-browser open https://example.com/form
agent-browser snapshot -i
# textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser snapshot -i  # Verify result
```

### Auth with Saved State

```bash
# Login once
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser state save auth.json

# Later: reuse saved auth
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

More auth patterns in [auth.md](references/auth.md).

### Token Auth (Skip Login)

```bash
# Headers scoped to origin only
agent-browser open api.example.com --headers '{"Authorization": "Bearer <token>"}'
agent-browser snapshot -i --json
```

## Debugging

```bash
agent-browser --headed open example.com  # Show browser window
agent-browser console                    # View console messages
agent-browser errors                     # View page errors
agent-browser highlight @e1              # Highlight element
```

See [debugging.md](references/debugging.md) for traces, common issues.

## Troubleshooting

**"Browser not launched" error**: Daemon stuck. Kill and retry:
```bash
pkill -f agent-browser && agent-browser open <url>
```

**Element not found**: Re-snapshot after page changes. DOM may have updated.

## References

| Topic | File |
|-------|------|
| Debugging, traces, common issues | [debugging.md](references/debugging.md) |
| Auth, cookies, storage, state persistence | [auth.md](references/auth.md) |
| Network mocking, tabs, frames, dialogs, settings | [advanced.md](references/advanced.md) |

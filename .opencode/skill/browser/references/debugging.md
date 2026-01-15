# Debugging

When browser automation fails or behaves unexpectedly.

## Headed Mode

Show visible browser window to see what's happening:

```bash
agent-browser --headed open example.com
agent-browser --headed snapshot -i
agent-browser --headed click @e1
```

## Console & Errors

View browser console output and page errors:

```bash
agent-browser console          # View console messages
agent-browser console --clear  # Clear console log
agent-browser errors           # View page errors
agent-browser errors --clear   # Clear error log
```

## Highlight Elements

Visually identify elements (use with `--headed`):

```bash
agent-browser highlight @e1
agent-browser highlight "#selector"
```

## Traces

Record browser traces for detailed debugging:

```bash
agent-browser trace start           # Start recording
# ... do interactions ...
agent-browser trace stop trace.zip  # Save trace file
```

Open traces in Playwright Trace Viewer: `npx playwright show-trace trace.zip`

## State Checks

Verify element state before interacting:

```bash
agent-browser is visible @e1    # Returns true/false
agent-browser is enabled @e1    # Check if interactive
agent-browser is checked @e1    # Checkbox state
```

With JSON output:
```bash
agent-browser is visible @e1 --json
# {"success":true,"data":true}
```

## Common Issues

### Element not found
- Re-snapshot: DOM may have changed
- Check visibility: `is visible @e1`
- Try `--headed` to see actual page state

### Click does nothing
- Element may be covered: try `scrollintoview @e1` first
- Element may be disabled: check `is enabled @e1`
- SPA not ready: add `wait --load networkidle`

### Form not submitting
- Check for validation errors in snapshot
- Some forms need `press Enter` instead of button click
- Wait for network: `wait --load networkidle`

### Auth redirect loops
- Save state after successful login: `state save auth.json`
- Check cookies: `cookies`
- Verify URL pattern: `get url`

## Debug Output

Add `--debug` for verbose output:

```bash
agent-browser --debug open example.com
agent-browser --debug click @e1
```

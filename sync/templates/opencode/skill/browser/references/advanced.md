# Advanced Features

## Network Interception

Mock or block network requests:

```bash
# Intercept and track requests
agent-browser network route "**/api/*"

# Block requests (ads, analytics)
agent-browser network route "**/analytics/*" --abort

# Mock response
agent-browser network route "**/api/user" --body '{"name":"Test User"}'

# Remove route
agent-browser network unroute "**/api/*"

# View tracked requests
agent-browser network requests
agent-browser network requests --filter api
```

## Tabs

```bash
agent-browser tab                # List tabs
agent-browser tab new            # New blank tab
agent-browser tab new url.com    # New tab with URL
agent-browser tab 2              # Switch to tab 2
agent-browser tab close          # Close current tab
agent-browser tab close 2        # Close tab 2
```

## Windows

```bash
agent-browser window new         # New browser window
```

## Frames (iframes)

```bash
agent-browser frame "#iframe-selector"  # Switch to iframe
agent-browser snapshot -i               # Snapshot within iframe
agent-browser click @e1                 # Interact within iframe
agent-browser frame main                # Back to main frame
```

## Dialogs

Handle alert/confirm/prompt dialogs:

```bash
agent-browser dialog accept              # Accept dialog
agent-browser dialog accept "input text" # Accept prompt with text
agent-browser dialog dismiss             # Dismiss/cancel dialog
```

## Mouse Control

Low-level mouse operations:

```bash
agent-browser mouse move 100 200       # Move to coordinates
agent-browser mouse down               # Press left button
agent-browser mouse down right         # Press right button
agent-browser mouse up                 # Release button
agent-browser mouse wheel -500         # Scroll wheel (negative = up)
```

## Drag and Drop

```bash
agent-browser drag @e1 @e2             # Drag e1 to e2
agent-browser drag "#source" "#target"
```

## File Upload

```bash
agent-browser upload @e1 /path/to/file.pdf
agent-browser upload @e1 file1.jpg file2.jpg  # Multiple files
```

## Browser Settings

### Viewport

```bash
agent-browser set viewport 1920 1080
```

### Device Emulation

```bash
agent-browser set device "iPhone 14"
agent-browser set device "Pixel 5"
```

### Geolocation

```bash
agent-browser set geo 37.7749 -122.4194  # San Francisco
```

### Offline Mode

```bash
agent-browser set offline on
agent-browser set offline off
```

### Color Scheme

```bash
agent-browser set media dark
agent-browser set media light
```

## CDP Mode

Connect to existing browser via Chrome DevTools Protocol:

```bash
# Connect to Electron app or Chrome with remote debugging
# Start Chrome: google-chrome --remote-debugging-port=9222
agent-browser --cdp 9222 snapshot
agent-browser --cdp 9222 click @e1
```

Use cases:
- Control Electron apps
- Connect to existing Chrome sessions
- WebView2 applications

## JavaScript Evaluation

```bash
agent-browser eval "document.title"
agent-browser eval "window.scrollTo(0, 1000)"
agent-browser eval "localStorage.getItem('token')"
```

## Bounding Box

Get element position and size:

```bash
agent-browser get box @e1
# {"x":100,"y":200,"width":150,"height":40}
```

## Custom Browser Executable

Use system Chrome or lightweight builds:

```bash
agent-browser --executable-path /usr/bin/google-chrome open example.com

# Or via environment
AGENT_BROWSER_EXECUTABLE_PATH=/path/to/chromium agent-browser open example.com
```

Useful for:
- Serverless (use `@sparticuz/chromium`)
- System browser instead of bundled
- Custom Chromium builds

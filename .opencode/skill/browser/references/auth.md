# Authentication

Patterns for handling login, sessions, and auth state.

## State Persistence

Save and restore full browser state (cookies, localStorage, sessionStorage):

```bash
# After successful login
agent-browser state save auth.json

# In new session
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

## Token Auth via Headers

Skip login flows entirely with auth headers:

```bash
# Headers scoped to origin only (safe!)
agent-browser open api.example.com --headers '{"Authorization": "Bearer <token>"}'
```

Multiple origins:
```bash
agent-browser open api.example.com --headers '{"Authorization": "Bearer token1"}'
agent-browser open api.acme.com --headers '{"Authorization": "Bearer token2"}'
```

Global headers (all domains):
```bash
agent-browser set headers '{"X-Custom-Header": "value"}'
```

## Cookies

```bash
agent-browser cookies                    # Get all cookies
agent-browser cookies set name "value"   # Set cookie
agent-browser cookies clear              # Clear all cookies
```

## Local Storage

```bash
agent-browser storage local              # Get all localStorage
agent-browser storage local key          # Get specific key
agent-browser storage local set key val  # Set value
agent-browser storage local clear        # Clear all
```

## Session Storage

```bash
agent-browser storage session            # Get all sessionStorage
agent-browser storage session key        # Get specific key
agent-browser storage session set k v    # Set value
agent-browser storage session clear      # Clear all
```

## HTTP Basic Auth

```bash
agent-browser set credentials username password
agent-browser open https://protected-site.com
```

## Example: Full Login Flow with State Save

```bash
# First run: perform login
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"
agent-browser click @e3
agent-browser wait --url "**/dashboard"
agent-browser wait --load networkidle

# Verify logged in
agent-browser snapshot -i
# Should show dashboard elements, not login form

# Save state for future runs
agent-browser state save auth.json
agent-browser close
```

```bash
# Subsequent runs: skip login
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
# Already authenticated!
```

## Session Isolation

Different auth states in parallel:

```bash
# Admin session
agent-browser --session admin state load admin-auth.json
agent-browser --session admin open https://app.example.com/admin

# User session
agent-browser --session user state load user-auth.json
agent-browser --session user open https://app.example.com/profile
```

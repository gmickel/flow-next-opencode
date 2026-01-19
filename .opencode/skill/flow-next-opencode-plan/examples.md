# Flow Plan Examples

## The Golden Rule in Practice

Plans describe WHAT to build and WHERE to look — not HOW to implement.

---

## Good vs Bad: Epic Specs

### ❌ BAD: Epic with implementation code

```markdown
# Backend Abstraction

## Implementation

### WorkerBackend Interface

\`\`\`typescript
interface WorkerBackend {
  name: string;
  spawn(opts: SpawnOpts): Promise<WorkerHandle>;
  isAlive(handle: WorkerHandle): Promise<boolean>;
  kill(handle: WorkerHandle): Promise<void>;
}

interface SpawnOpts {
  prompt: string;
  cwd: string;
  logFile: string;
  env?: Record<string, string>;
}
\`\`\`

### Registry

\`\`\`typescript
const backends = new Map<string, WorkerBackend>();

export function registerBackend(backend: WorkerBackend): void {
  backends.set(backend.name, backend);
}

export function getBackend(name: string): WorkerBackend {
  const backend = backends.get(name);
  if (!backend) throw new Error(\`Unknown backend: \${name}\`);
  return backend;
}
\`\`\`
```

**Problems:**
- Complete interface definitions (implementer will write these anyway)
- Full registry implementation (copy-paste ready = wasted planning tokens)
- No references to existing patterns in the codebase

### ✅ GOOD: Epic without implementation code

```markdown
# Backend Abstraction

## Overview
Abstract worker spawning so any CLI (opencode, codex, gemini) can run workers.

## Approach
- Define `WorkerBackend` interface with spawn/isAlive/kill methods
- Registry pattern for backend lookup (similar to `src/lib/plugins.ts:15-30`)
- Each backend is a separate file in `src/lib/backends/`

## Key decisions
- File-based completion detection (not process exit codes) — workers are detached
- Prompt via CLI arg for opencode, stdin for codex (per their docs)

## Quick commands
\`\`\`bash
bun test src/lib/backend.test.ts
\`\`\`

## Acceptance
- [ ] WorkerBackend interface defined
- [ ] opencode and codex backends implemented
- [ ] Registry with registerBackend/getBackend
- [ ] Existing spawn.ts refactored to use backend abstraction
```

**Why this is better:**
- Describes the approach, not the code
- References existing pattern (`plugins.ts:15-30`)
- Key decisions captured (file-based detection, prompt delivery)
- Testable acceptance criteria

---

## Good vs Bad: Task Specs

### ❌ BAD: Task with full implementation

```markdown
# fn-2.3: Implement opencode backend

## Implementation

Create opencode backend in `src/lib/backends/opencode.ts`:

\`\`\`typescript
export const opencodeBackend: WorkerBackend = {
  name: 'opencode',

  async spawn({ prompt, cwd, logFile, env }) {
    const proc = Bun.spawn(['opencode', '-p', prompt], {
      cwd,
      stdout: Bun.file(logFile),
      stderr: 'inherit',
      env: { ...process.env, ...env },
    });
    return { pid: proc.pid, logFile };
  },

  async isAlive({ pid }) {
    try {
      process.kill(pid, 0);
      return true;
    } catch {
      return false;
    }
  },

  async kill({ pid }) {
    process.kill(pid, 'SIGTERM');
  },
};
\`\`\`

Register in `src/lib/backend.ts`:

\`\`\`typescript
import { opencodeBackend } from './backends/opencode';
registerBackend(opencodeBackend);
\`\`\`
```

**Problems:**
- This IS the implementation — nothing left for `/flow-next:work` to do
- Implementer will re-read this, then write essentially the same code
- If implementation differs slightly, causes plan-sync drift

### ✅ GOOD: Task spec without implementation

```markdown
# fn-2.3: Implement opencode backend

## Description
Create opencode backend following WorkerBackend interface.

**Size:** S
**Files:** `src/lib/backends/opencode.ts`, `src/lib/backend.ts` (registration)

## Approach
- Follow codex backend pattern at `src/lib/backends/codex.ts:15-40`
- Use `Bun.spawn` for process management
- Prompt via `-p` flag (not stdin) per opencode CLI

## Key context
- Must be detached process (background worker pattern)
- Log to `logFile` parameter for verdict parsing

## Acceptance
- [ ] Implements spawn/isAlive/kill per interface
- [ ] Registered on module import
- [ ] `bun test` passes
- [ ] `bun run lint` passes
```

**Why this is better:**
- Points to pattern to follow (`codex.ts:15-40`)
- Notes key decision (prompt via `-p` flag)
- Implementer has freedom to write the actual code
- Acceptance is testable, not "matches spec exactly"

---

## Task Breakdown Example

### ❌ BAD: Monolithic task

```markdown
# fn-1.1: Implement Google OAuth

Add Google OAuth authentication to the application.
```

**Problems:**
- Way too large (~200k+ tokens to implement)
- No clear boundaries
- Can't parallelize

### ✅ GOOD: Broken into sized tasks

```markdown
# fn-1.1: Add Google OAuth environment config
**Size:** S | **Files:** `.env.example`, `src/config/env.ts`

Add GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to .env.example
and environment validation.

---

# fn-1.2: Install and configure passport-google-oauth20
**Size:** S | **Files:** `package.json`, `src/auth/strategies/google.ts`

Add package, create passport strategy config following
pattern at `src/auth/strategies/local.ts`.

---

# fn-1.3: Create OAuth callback routes
**Size:** M | **Files:** `src/routes/auth.ts`, `src/routes/auth.test.ts`

Add /auth/google and /auth/google/callback routes
following pattern at `src/routes/auth.ts:50-80`.

---

# fn-1.4: Add Google sign-in button to login UI
**Size:** S | **Files:** `src/components/LoginForm.tsx`

Add button component following existing auth buttons
at `src/components/LoginForm.tsx:25-40`.
```

**Why this is better:**
- All tasks are S or M (completable in one context)
- Clear file references
- Can work on fn-1.1 and fn-1.4 in parallel
- Sizes based on observable metrics (files, pattern)

---

## When Code IS Appropriate

### Recent API changes (from docs-scout)

```markdown
## Key context

React 19 introduces `useOptimistic` for optimistic UI updates:
\`\`\`typescript
const [optimisticState, addOptimistic] = useOptimistic(state, updateFn);
\`\`\`
Use this instead of manual state management for the cart updates.
```

### Non-obvious gotcha (from practice-scout)

```markdown
## Key context

Bun.spawn with `stdout: file` requires explicit cleanup:
\`\`\`typescript
// MUST close file handle or truncation occurs
await proc.exited;
\`\`\`
See: https://github.com/oven-sh/bun/issues/1234
```

### Existing repo pattern (from repo-scout)

```markdown
## Approach

Follow the validation pattern at `src/lib/validators.ts:42-55`:
\`\`\`typescript
// Shows the pattern shape, not the implementation you'll write
export function validateX(input: T): Result<T, ValidationError>
\`\`\`
```

---

## Mermaid Diagrams

Include a mermaid diagram when the change involves:
- New database tables or schema changes
- New services or significant architecture changes
- Complex data flow between components

### ERD for data model changes

```markdown
## Data Model

\`\`\`mermaid
erDiagram
    User ||--o{ Session : has
    User ||--o{ OAuthToken : has
    OAuthToken {
        string provider
        string access_token
        string refresh_token
        datetime expires_at
    }
\`\`\`
```

### Flowchart for architecture/data flow

```markdown
## Architecture

\`\`\`mermaid
flowchart LR
    Client --> API
    API --> AuthService
    AuthService --> Google[Google OAuth]
    AuthService --> DB[(Database)]
\`\`\`
```

**Keep diagrams simple** — 5-10 nodes max. If it needs more, the feature may need splitting.

---

## Summary

| Include in specs | Don't include |
|------------------|---------------|
| What to build | How to build it |
| Where to look (file:line) | Full implementations |
| Key decisions + why | Copy-paste code |
| Recent/surprising APIs | Obvious patterns |
| Non-obvious gotchas | Every function body |
| Acceptance criteria | Redundant details |

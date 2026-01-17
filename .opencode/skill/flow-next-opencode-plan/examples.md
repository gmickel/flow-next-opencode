# Flow Plan Examples

## Example 1: Add OAuth login

**Request**: Add OAuth login

**Plan outline**:
- References: auth service, routes, session controller
- Reuse: existing token handler
- Acceptance: login, callback, failure cases

## Example 2: Fix N+1 on dashboard

**Request**: Fix N+1 on dashboard

**Plan outline**:
- References: dashboard query, serializer
- Reuse: existing preload helper
- Acceptance: query count reduced, tests updated

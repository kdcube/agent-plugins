---
name: kdcube-delegated-access
description: "Act on behalf of a KDCube user: obtain a bounded delegated credential (Connection Hub -> Delegated by KDCube -> manual automation token, or an OAuth/MCP connect) and call KDCube managed REST operations and MCP surfaces with it. Activate when the user wants Claude, a script, a CI job, or any automation to read or change things inside their KDCube — publish content, run admin operations, use named services — without being their browser session."
---

# kdcube-delegated-access — operate KDCube on the user's behalf

KDCube lets a signed-in user hand an automation a **bounded bearer
credential** that represents them on selected KDCube resources. You (Claude
Code) are such an automation. This is the sanctioned way to act inside a
user's KDCube — never scrape their session cookies, never ask for their
password, never embed platform admin tokens in scripts.

Ground truth (read via **kdcube-docs** before acting):

- recipe: `repo:kdcube-ai-app/app/ai-app/docs/recipes/connections/create-delegated-automation-access-README.md`
- guarded REST: `…/docs/recipes/connections/protect-bundle-rest-with-managed-credentials-README.md`
- guarded MCP: `…/docs/recipes/connections/protect-bundle-mcp-with-managed-credentials-README.md`
- named services over MCP: `…/docs/recipes/kdcube_for_agents/named-services-mcp-README.md`
- model: `…/docs/sdk/solutions/connections/delegated-connections/delegated-connections-README.md`

## The flow (manual token — fastest start)

Walk the user through it; the token is created by THEM in the UI:

```text
1. Open Connection Hub -> Delegated by KDCube.
2. "Create automation access": name it (e.g. "claude-code"),
   check the resource grants it needs, pick a TTL.
   - Regular users see only the resources they may delegate.
   - An admin can select "All platform and application APIs"
     (kdcube:role:super-admin) for a DevOps-grade token.
3. The token is shown ONCE — the user copies it to you.
4. The grant appears under "Granted access" (badge: manual token);
   the user can revoke it there at any time — revocation is immediate.
```

Then every call is plain HTTP:

```shell
curl -sS -H "Authorization: Bearer $KDCUBE_TOKEN" \
  "https://<host>/api/integrations/bundles/<tenant>/<project>/<app-id>/operations/<operation>"
```

The guard loads the server-side grant record by token hash and enforces
`resource_grants` per call: grants are scoped to the resource they belong to
(`{A: read, B: write}` cannot write on A). The route then runs as the
granting user with delegated provenance — application code sees a normal
user context.

Delegation is not blanket downstream authority. Every managed REST, MCP,
named-service, provider, or fenced operation validates its own required grant
against the carried edge. Provider credentials stay on the trusted side and
are never forwarded to the caller or a restricted executor.

## Storing the token

Treat it like any secret: environment variable or the local secret store the
user prefers. Never write it into files that reach git, never echo it into
logs or command output. If it leaks, tell the user to revoke it in Connection
Hub (Delegated by KDCube -> Granted access) and create a new one.

## The OAuth/MCP alternative

For interactive Claude (claude.ai connectors / Claude Code MCP), skip manual
tokens: add the KDCube named-services MCP URL as a connector and complete the
OAuth consent. That connection also lands in "Granted access" (badge:
connected app) with the same one-click revocation. Prefer it when the goal is
conversational access to namespaces (memories, tasks, mail, slack…); prefer
the manual token for scripts, CI, and scheduled jobs.

## Recognizing and fixing failures

| Symptom | Meaning | Fix |
| --- | --- | --- |
| 401 with no grant record | token expired, revoked, or wrong env | user creates a new token in Connection Hub |
| 403 from the managed guard | resource/operation outside `resource_grants` | recreate the token with the missing grant checked |
| `needs_connected_account_consent` payload | KDCube accepted YOU, but the user's provider account (Gmail/Slack…) needs connect/reconnect/approval | relay the payload's reason and `connection_hub_url` to the user; retry after they finish |
| grant visible but calls fail after config change | MCP namespace catalog is consent-time | user reconnects/reapproves the client |

## What this is not

Delegated access is a KDCube-issued credential for entering KDCube. The
user's external provider accounts (Gmail, Slack, iCloud) are the other
direction — "Delegated to KDCube" — and are resolved by KDCube tools
server-side; you never receive those provider tokens.

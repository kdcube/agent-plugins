---
id: <app>@<version>/agents
title: "<App> — Builder-Agent Onboarding"
summary: "<one line: what this app is + its surfaces>"
status: active
tags: ["agents", "builder", "onboarding", "<app>", "bundle"]
see_also:
  - "README.md"
  - "interface/README.md"
  - "interface/<app-slug>.openapi.yaml"
  - "docs/README.md"
  - "docs/storage/README.md"
  - "docs/journal/"
  - "config/bundles.template.yaml"
---

# &lt;App&gt; — Builder-Agent Onboarding

> The per-app builder **memory**. Drop at the app root (`<app_path>/AGENTS.md`)
> so any agent working inside picks up the *why* automatically.
>
> **What goes here:** the *why* and the *what*, not the *how*. The *how* lives in
> the code; the *why* is what an agent cannot infer from a fresh `git clone`.
>
> Keep this file under ~200 lines. If a section is genuinely empty, write
> `(none)` rather than deleting it — its absence is itself a useful signal.

## Read First

The canonical app set (shape in `canonical-app-form.md` and
`tier1/04-write.md#1b1-canonical-app-package`):

- [README.md](README.md) — what this app is + its layout.
- [interface/README.md](interface/README.md) — the surfaces contract.
- [interface/&lt;app-slug&gt;.openapi.yaml](interface/) — machine-readable HTTP
  and `x-kdcube-surfaces` declaration.
- [docs/README.md](docs/README.md) — architecture and module-owner index.
- [docs/storage/README.md](docs/storage/README.md) — storage ownership map.
- [docs/journal/](docs/journal/) — read the **latest dated entry** before touching
  in-flight work.

## Identity

- **Bundle id:** `<id>@<version>` (e.g., `task-and-memo-app@1-0`)
- **Repository:** `<git URL>`
- **Path inside repo:** `<relative path>`
- **Entrypoint:** `entrypoint.py` → `<EntrypointClass>`
- **Audience scope of this AGENTS.md:** `<user | engineering | maintainer | ...>`

## Why this bundle exists

One paragraph that an agent who has never worked here can read and
understand what business problem the bundle solves.

## Surface map

### Provides (`as_provider`)

- **Workflow:** `<short purpose>`
- **Public APIs:** `<list>` (or `(none)`)
- **Operations APIs:** `<list>` (or `(none)`)
- **MCP endpoints:** `<list>` (or `(none)`)
- **Widgets:** `<list>` (or `(none)`)
- **Scheduled jobs:** `<list>` (or `(none)`)
- **Background jobs:** `<list>` (or `(none)`)

### Consumes (`as_consumer`)

- **Agent tools and skills:** `<per-agent capability view>` (or `(none)`)
- **MCP servers:** `<server alias -> consuming agents -> allowed tools>` (or `(none)`)
- **Named services / connected capabilities:** `<list>` (or `(none)`)

## SDK building blocks reused

List each KDCube SDK block used and why. The point of this section
is to stop future agents from reimplementing what the SDK already
provides. Keep it explicit.

| SDK block | Why this bundle uses it | Where it's wired |
|---|---|---|
| `<e.g. SDK Automations Solution>` | `<one-line reason>` | `<file:line or symbol>` |

## Module ownership

The root is sparse: only `__init__.py`, `entrypoint.py`, `README.md`,
`AGENTS.md`, `release.yaml`, optional `requirements.txt`, and declaration
folders belong there. Product implementation belongs in responsibility-named,
documented folders.

| Folder/module | Owner and purpose | Public/runtime callers |
|---|---|---|
| `services/<domain>/` | `<domain behavior>` | `<surfaces/jobs/agents>` |
| `surfaces/<transport>/` | `<thin transport adapter>` | `<platform decorator>` |

Do not add root-level product modules or vague `logic.py`, `helpers.py`,
`misc.py`, or `utils.py` buckets.

## Async runtime invariant

KDCube proc is concurrent asyncio. Every lifecycle hook, decorated handler,
service operation, and I/O call chain is async end to end. Use async SDK,
storage, database, Redis, HTTP, and subprocess APIs. `async def` around blocking
code is still a bug; isolate an unavoidable bounded blocking call with
`await asyncio.to_thread(...)` and move long work to a worker/job.

## Configuration this bundle consumes

| Scope | Key | Purpose | Where read |
|---|---|---|---|
| bundle prop | `<key>` | `<purpose>` | `<file:line>` |
| bundle secret | `b:<key>` | `<purpose>` | `<file:line>` |
| user prop | `<key>` | `<purpose>` | `<file:line>` |
| user secret | `<key>` | `<purpose>` | `<file:line>` |

The non-secret descriptor shape is documented in
`config/bundles.template.yaml`. Secrets shape in
`config/bundles.secrets.template.yaml`. **Real secrets never go into
either file** — only safe example values.

## Runtime registration

How this bundle should be connected to a KDCube runtime:

- **Preferred source mode:** `<git | local | built-in>`
- **Git repo/ref/path:** `<repo URL, tag/branch/ref, path in repo>` (or `(none)`)
- **Local runtime-visible path:** `<path visible to processor runtime>` (or `(none)`)
- **Plain config set through CLI:** `<kdcube bundle ... --set-config keys>`
- **Secrets set through CLI/secret store:** `<secret key names only>`

Use `/kdcube:bundle-configure` for runtime registration. Do
not put real secrets in this file, source descriptors, README files,
logs, or journal entries.

## Decisions an agent should not relitigate

Bullet the decisions whose context lives outside the code:

- **Why &lt;decision&gt;:** &lt;1-2 sentence rationale&gt;.
- **Why not &lt;alternative&gt;:** &lt;1-2 sentences&gt;.

(If a future agent thinks a decision should change, that's fine —
but the agent should know the original *why* before suggesting a
flip, not after.)

## Recurring mistakes to avoid in this bundle

Bundle-specific guardrails that go beyond the global Tier 1 list. For
example:

- "do not hand-edit `data/<thing>.json` — it is regenerated by `<step>`."
- "user_id in this bundle is the resolved Telegram user identity, not the KDCube account id — see entrypoint.py:NN."

## How to test this bundle

- venv preflight: `<command>`
- run tests: `<command>`
- smoke test against a running runtime: `<command>` (or `(none)`)

## CLI workflow notes

- runtime init: `/kdcube:runtime-init`
- bundle config/reload: `/kdcube:bundle-configure`
- maintenance workflow: `/kdcube:bundle-maintain`
- release workflow: `/kdcube:bundle-release` after explicit approval

## Where to look when something breaks

| Symptom | First place to look |
|---|---|
| `<symptom>` | `<file or doc reference>` |

## Journal pointer

Decision history lives in `docs/journal/` as **dated entries**
(`YYYY-MM-DD-<topic>.md`, each with `## Summary / ## Decisions / ## Files /
## Follow-Up` — see `journal-entry.md`). Read the latest before assuming the
state of an in-flight feature, and add a new entry whenever you make a decision
worth remembering.

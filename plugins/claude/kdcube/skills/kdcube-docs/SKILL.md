---
name: kdcube-docs
description: "Read KDCube product, SDK, architecture, and operator knowledge from the LOCAL kdcube-ai-app repo (docs + source) — no hosted retrieval service. Activate whenever a task needs KDCube ground truth: building/serving/integrating an app (bundle), the CLI/operator level, descriptors, auth/sessions/dataflows, surfaces, runtimes, economics, connecting external accounts (Connection Hub / delegated credentials), named services and exposing them over MCP, external provider integrations and their error/observability contract, or how a reference app is wired. This is the source of truth; prefer it over memory."
---

# kdcube-docs — read KDCube ground truth from the local repo

KDCube's documentation AND source both live in the `kdcube-ai-app` repo. This
skill is how the agent reads them **directly from a local checkout** — the repo
is the source of truth; when unsure, read it instead of guessing.

A hosted documentation MCP also exists at `https://kdcube.tech/mcp/docs` — a
live search/read surface over the same docs. Use it when no local checkout is
available yet (or to cross-check freshness); the checkout remains the primary
source once onboarded, and the Tier 1 pack is the offline fallback.

## Get the repo (once per session)

1. Resolve the `kdcube-ai-app` repo via the **ref-resolver** skill — read
   `config/repos.yaml`, take `repos.kdcube-ai-app.local_path`. Everything below
   is a `repo:kdcube-ai-app/<path>` ref = `local_path` + `/<path>`.
2. If `config/repos.yaml` has no `kdcube-ai-app` entry, or `local_path` does not
   exist on disk, **onboard first**: run `/kdcube:init`. The default
   repo is the CLI-managed runtime checkout at `<workdir>/repo` (it matches the
   running platform); init pins it, or bootstraps a runtime if there is none. A
   hand-set `local_path` is the developer override. Do not fabricate answers from
   memory while the repo is unavailable — say it's missing and onboard.

The docs root is `repo:kdcube-ai-app/app/ai-app/docs/`. The master index is
`repo:kdcube-ai-app/app/ai-app/docs/README.md` — open it when a topic is not in
the map below.

## How to read

- Resolve the `repo:` ref to an absolute path, then **Read** the doc. For docs
  longer than ~500 lines or when digesting several at once, delegate to the
  **doc-reader** agent (it returns a compact digest without flooding context).
- For anything not in the index: `rg`/`find` inside the repo (docs first, then
  `app/ai-app/src`). The index is a starting map, not a wall — the whole repo is
  readable.
- Quote `repo:kdcube-ai-app/<path>:<line>` when you cite, so the operator can open it.

## Index — where to read each topic

### A. Onboarding / orientation
| Topic | repo: ref |
|-------|-----------|
| Docs master index | `repo:kdcube-ai-app/app/ai-app/docs/README.md` |
| What KDCube is / can do | `repo:kdcube-ai-app/app/ai-app/docs/what-you-can-do-with-kdcube-README.md` |
| Local quick start (init/start/refresh) | `repo:kdcube-ai-app/app/ai-app/docs/quick-start-README.md` |
| System architecture (current) | `repo:kdcube-ai-app/app/ai-app/docs/arch/architecture-of-what-we-built-README.md` |
| System architecture (short) | `repo:kdcube-ai-app/app/ai-app/docs/arch/architecture-short.md` |

### B. Architecture
| Topic | repo: ref |
|-------|-----------|
| Auth & authorization of a request; user classes | `repo:kdcube-ai-app/app/ai-app/docs/service/auth/auth-README.md` |
| Sessions (bundle-scoped, federated identity) | `repo:kdcube-ai-app/app/ai-app/docs/service/auth/bundle-session-auth-README.md` |
| Processor entry point (queue claim, execution) | `repo:kdcube-ai-app/app/ai-app/docs/arch/proc/processor-arch-README.md` |
| Ingress entry point (external event inception) | `repo:kdcube-ai-app/app/ai-app/docs/arch/ingress/events-inception-README.md` |
| Conversation event bus (chat stream) + data bus | `repo:kdcube-ai-app/app/ai-app/docs/service/comm/conversation-event-bus-and-data-bus-README.md` |
| Data bus (durable, non-conversation) | `repo:kdcube-ai-app/app/ai-app/docs/service/comm/data-bus-README.md` |
| App surfaces & access levels (communicator, ops API, widgets, jobs, artifacts) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/bundle-interfaces-README.md` |
| Per-surface runtimes / execution boundaries | `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/bundle-runtime-README.md` |
| Cross-runtime call context (REQUEST/BUNDLE_CALL/discovery) | `repo:kdcube-ai-app/app/ai-app/docs/runtime/cross-runtime-context-README.md` |
| Economics applied to flows | `repo:kdcube-ai-app/app/ai-app/docs/economics/economic-README.md` (+ `tier1/12-economics.md`) |
| Async hook → fair scheduling (resubmitter / event→turn) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/events/event-ingress-to-react-turn-README.md` — also `rg -i resubmit app/ai-app` |
| Singleton vs non-singleton apps | `how-to-write-bundle-README.md` §"Singleton And Exclusivity Rules" + `repo:kdcube-ai-app/app/ai-app/docs/configuration/bundles-descriptor-README.md` |
| Public surfaces (mcp/api/ui_widget) with app-owned request validation; public API as webhook/hook | `bundle-interfaces-README.md` + `repo:kdcube-ai-app/app/ai-app/docs/sdk/tools/mcp-README.md` |

### C. CLI / operator
| Topic | repo: ref |
|-------|-----------|
| CLI source (commands) | `repo:kdcube-ai-app/app/ai-app/src/kdcube-ai-app/kdcube_cli/src/kdcube_cli/cli.py` |
| CLI design / workdir / namespacing | `repo:kdcube-ai-app/app/ai-app/docs/service/cicd/cli-README.md` |
| Local CLI run sheet (operator quick ref) | `repo:kdcube-ai-app/app/ai-app/docs/recipes/operations/operate-runtime-README.md` |
| Descriptors overview | `repo:kdcube-ai-app/app/ai-app/docs/service/cicd/descriptors-README.md` |
| Assembly descriptor (tenant/project/auth/infra) | `repo:kdcube-ai-app/app/ai-app/docs/configuration/assembly-descriptor-README.md` |
| Bundles descriptor (app registry, sources, config) | `repo:kdcube-ai-app/app/ai-app/docs/configuration/bundles-descriptor-README.md` |
| Secrets descriptor (platform secrets) | `repo:kdcube-ai-app/app/ai-app/docs/configuration/secrets-descriptor-README.md` |
| How descriptors → props/secrets at ALL levels (platform/bundle/user) | `repo:kdcube-ai-app/app/ai-app/docs/configuration/service-runtime-configuration-mapping-README.md` |
| Edit descriptor YAML, then `kdcube refresh` | (operator edits `bundles.yaml`/`bundles.secrets.yaml`/`assembly.yaml`, then reloads — see CLI + quick-start) |
| Docker logs | `docker compose -f app/ai-app/deployment/docker/all_in_one/docker-compose.yml logs -f <service>` |

### D. App (bundle) authoring
| Topic | repo: ref |
|-------|-----------|
| Canonical app form / write a bundle | `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-write-bundle-README.md` |
| Configure & run | `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-configure-and-run-bundle-README.md` |
| Test | `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-test-bundle-README.md` |
| Release content | `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-release-bundle-content-README.md` |
| Contract test suite | `repo:kdcube-ai-app/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/tests/bundle/run_bundle_suite.py` — run `python -m kdcube_ai_app.apps.chat.sdk.tests.bundle.run_bundle_suite --bundle-path <app>` |

**The `tier1/` pack is a cache — the checkout wins.** The plugin ships these docs
as the `tier1/` pack for fast reading. Each file is a copy that keeps its source
`id:` and `updated_at`, so it is self-describing. Authority runs **runtime >
checkout > pack**: the pack never overrides the checkout or the running platform.

- On session start, `bin/check-tier1-freshness.sh` compares each pack file's
  frontmatter against the checkout. Read its notice.
- **BEHIND** (checkout newer): read the checkout doc for the task, then sync the
  pack yourself — run `bin/refresh-tier1.sh` — and tell the operator which files
  moved. Don't wait to be asked.
- **AHEAD** (pack newer — it describes a platform the checkout is not on): do NOT
  auto-refresh; that would downgrade the pack. Read from the checkout, and tell
  the operator to either pull the platform forward or run
  `/kdcube:knowledge-refresh` to align the pack down.
- Refreshing the doc cache is autonomous; editing the plugin's own skills/commands
  is not.
- Never silently prefer a `tier1/` snapshot over the checkout.

### E. Reference apps
| App | Path | Use it for |
|-----|------|-----------|
| workspace | `repo:kdcube-ai-app/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/workspace@2026-03-31-13-36/` | surface reference (React, economics, memory, canvas, Telegram, widgets, MCP) |
| user-memories | `repo:kdcube-ai-app/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/user-memories@2026-06-26/` | minimal app deriving the memory+economics mixin (widget + `mem` named service) |
| connection-hub | `repo:kdcube-ai-app/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/connection-hub@1-0/` | strong `AGENTS.md`, interface, and storage-ownership structure |
| kdcube-services | `repo:kdcube-ai-app/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/kdcube-services@1-0/` | MCP/service facade, widgets, Data Bus, signed files, OpenAPI, storage contract, and the **app-owned `@venv` + `requirements.txt`** pattern — its Google Sheets tools (served on both the productivity MCP and the `sheets` named service) run in an app venv because `gspread` is in neither base requirement — the point-need path, vs. adding a long-term dep to `requirements-chat.txt` + `requirements-chat-processor.txt`; the `@venv` contract is `repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/bundle-venv-README.md` (also `tier1/04-write.md` §`@venv`) |

Examples demonstrate surfaces; the canonical package in `tier1/04-write.md`
wins when an older example has a different layout.

### F. Connections, named services, and integrations

**Connection Hub owns external connections and delegated credentials.** Its
`bundles.yaml` config declares two things a bundle relies on but does not
reimplement: the OAuth authorization surface for external clients
(`connections.delegated_credentials.oauth`: `capabilities`, `resources`, and a
door claim's backing `connected_accounts`) and the delegated-to-KDCube provider
registry (`connections.delegated_to_kdcube.providers.<p>`: each claim's real
OAuth `provider_scopes`, and the `connector_apps`). A bundle only **declares**
the claims/tools it needs; Connection Hub resolves the user's token at runtime,
and the agent never sees a provider token.

Integration docs sit in three tiers: **bundle-local operator setup**
(`connection-hub@1-0/docs/integrations/<provider>.md`) → **SDK mechanics**
(`docs/sdk/integrations/<provider>/`) → **recipe** (`docs/recipes/connections/
integrations/`).

| Topic | repo: ref |
|-------|-----------|
| Connection Hub — what it owns; delegated-by vs delegated-to | `repo:kdcube-ai-app/app/ai-app/docs/sdk/solutions/connections/connection-hub-solution-README.md` |
| Act on a signed-in user's own external account (delegated-to; no bundle OAuth) | `repo:kdcube-ai-app/app/ai-app/docs/recipes/connections/README.md` |
| Authenticated MCP end-to-end: two gates, door claims, `connected_accounts` contract | `repo:kdcube-ai-app/app/ai-app/docs/sdk/solutions/connections/authenticated-mcp/authenticated-mcp-README.md` |
| KDCube as OAuth authorization server for external clients (Claude Code) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/solutions/connections/delegated-credentials/oauth-delegated-credential-protocol-adapter-README.md` |
| Named services — expose owned objects/actions as a namespace (SDK) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/namespace-services/README.md`, `.../providers-README.md` |
| **Make a named service** (recipe) | `repo:kdcube-ai-app/app/ai-app/docs/recipes/components/named-service-README.md` |
| **Expose a governed service over MCP** (recipe) | `repo:kdcube-ai-app/app/ai-app/docs/recipes/quickstart/expose-governed-service-mcp-README.md` |
| Expose named services as one generic MCP surface to external agents | `repo:kdcube-ai-app/app/ai-app/docs/recipes/apps/named-services-mcp-README.md` |
| Guard a bundle MCP/REST surface with managed credentials | `repo:kdcube-ai-app/app/ai-app/docs/recipes/connections/protect-bundle-mcp-with-managed-credentials-README.md` |
| **Provider error & observability contract** — how a provider failure must present and propagate across a tool/named-service/REST/MCP boundary (managed envelope, auth vs service failures, retries, partial results) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/integrations/provider-error-contract-README.md` |
| SDK integrations index (per-provider mechanics) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/integrations/README.md` |
| Google services (Gmail, Sheets) — recipe + SDK mechanics/scopes | `repo:kdcube-ai-app/app/ai-app/docs/recipes/connections/integrations/google-service-README.md`, `repo:kdcube-ai-app/app/ai-app/docs/sdk/integrations/google/google-README.md` |
| Generic OAuth/OIDC connect service (the framework Google/Slack instantiate) | `repo:kdcube-ai-app/app/ai-app/docs/sdk/integrations/custom-oauth-oidc-service-README.md` |

---
name: kdcube-docs
description: "Read KDCube product, SDK, architecture, and operator knowledge from the LOCAL KDCube repo (docs + source) — no hosted retrieval service. Activate whenever a task needs KDCube ground truth: building/serving/integrating an app (bundle), the CLI/operator level, descriptors, auth/sessions/dataflows, surfaces, runtimes, economics, connecting external accounts (Connection Hub / delegated credentials), named services and exposing them over MCP, external provider integrations and their error/observability contract, or how a reference app is wired. This is the source of truth; prefer it over memory."
---

# kdcube-docs — read KDCube ground truth from the local repo

KDCube's documentation AND source both live in the `kdcube` repo. This
skill is how the agent reads them **directly from a local checkout** — the repo
is the source of truth; when unsure, read it instead of guessing.

A hosted documentation MCP also exists at `https://kdcube.tech/mcp/docs` — a
live search/read surface over the same docs. Use it when no local checkout is
available yet (or to cross-check freshness); the checkout remains the primary
source once onboarded, and the Tier 1 pack is the offline fallback.

## Get the repo (once per session)

1. Resolve the `kdcube` repo via the **ref-resolver** skill — read
   `config/repos.yaml`, take `repos.kdcube.local_path`. Everything below
   is a `repo:kdcube/<path>` ref = `local_path` + `/<path>`.
2. If `config/repos.yaml` has no `kdcube` entry, or `local_path` does not
   exist on disk, **onboard first**: run `/kdcube:init`. The default
   repo is the CLI-managed runtime checkout at `<workdir>/repo` (it matches the
   running platform); init pins it, or bootstraps a runtime if there is none. A
   hand-set `local_path` is the developer override. Do not fabricate answers from
   memory while the repo is unavailable — say it's missing and onboard.

The docs root is `repo:kdcube/app/ai-app/docs/`. The master index is
`repo:kdcube/app/ai-app/docs/README.md` — open it when a topic is not in
the map below.

## How to read

- Resolve the `repo:` ref to an absolute path, then **Read** the doc. For docs
  longer than ~500 lines or when digesting several at once, delegate to the
  **doc-reader** agent (it returns a compact digest without flooding context).
- For anything not in the index: `rg`/`find` inside the repo (docs first, then
  `app/ai-app/src`). The index is a starting map, not a wall — the whole repo is
  readable.
- Quote `repo:kdcube/<path>:<line>` when you cite, so the operator can open it.

## Index — where to read each topic

### A. Onboarding / orientation
| Topic | repo: ref |
|-------|-----------|
| Docs master index | `repo:kdcube/app/ai-app/docs/README.md` |
| What KDCube is / can do | `repo:kdcube/app/ai-app/docs/what-you-can-do-with-kdcube-README.md` |
| Local quick start (init/start/refresh) | `repo:kdcube/app/ai-app/docs/quick-start-README.md` |
| System architecture (current) | `repo:kdcube/app/ai-app/docs/arch/architecture-of-what-we-built-README.md` |
| System architecture (short) | `repo:kdcube/app/ai-app/docs/arch/architecture-short.md` |

### B. Architecture
| Topic | repo: ref |
|-------|-----------|
| Auth & authorization of a request; user classes | `repo:kdcube/app/ai-app/docs/service/auth/auth-README.md` |
| Sessions (bundle-scoped, federated identity) | `repo:kdcube/app/ai-app/docs/service/auth/bundle-session-auth-README.md` |
| Processor entry point (queue claim, execution) | `repo:kdcube/app/ai-app/docs/arch/proc/processor-arch-README.md` |
| Ingress entry point (external event inception) | `repo:kdcube/app/ai-app/docs/arch/ingress/events-inception-README.md` |
| Conversation event bus (chat stream) + data bus | `repo:kdcube/app/ai-app/docs/service/comm/conversation-event-bus-and-data-bus-README.md` |
| Data bus (durable, non-conversation) | `repo:kdcube/app/ai-app/docs/service/comm/data-bus-README.md` |
| App surfaces & access levels (communicator, ops API, widgets, jobs, artifacts) | `repo:kdcube/app/ai-app/docs/sdk/bundle/bundle-interfaces-README.md` |
| Per-surface runtimes / execution boundaries | `repo:kdcube/app/ai-app/docs/sdk/bundle/bundle-runtime-README.md` |
| Cross-runtime call context (REQUEST/BUNDLE_CALL/discovery) | `repo:kdcube/app/ai-app/docs/runtime/cross-runtime-context-README.md` |
| Economics applied to flows | `repo:kdcube/app/ai-app/docs/economics/economic-README.md` (+ `tier1/12-economics.md`) |
| Async hook → fair scheduling (resubmitter / event→turn) | `repo:kdcube/app/ai-app/docs/sdk/events/event-ingress-to-react-turn-README.md` — also `rg -i resubmit app/ai-app` |
| Singleton vs non-singleton apps | `how-to-write-bundle-README.md` §"Singleton And Exclusivity Rules" + `repo:kdcube/app/ai-app/docs/configuration/bundles-descriptor-README.md` |
| Public surfaces (mcp/api/ui_widget) with app-owned request validation; public API as webhook/hook | `bundle-interfaces-README.md` + `repo:kdcube/app/ai-app/docs/sdk/tools/mcp-README.md` |

### C. CLI / operator
| Topic | repo: ref |
|-------|-----------|
| CLI source (commands) | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_cli/src/kdcube_cli/cli.py` |
| CLI design / workdir / namespacing | `repo:kdcube/app/ai-app/docs/service/cicd/cli-README.md` |
| Local CLI run sheet (operator quick ref) | `repo:kdcube/app/ai-app/docs/recipes/operations/operate-runtime-README.md` |
| Descriptors overview | `repo:kdcube/app/ai-app/docs/service/cicd/descriptors-README.md` |
| Assembly descriptor (tenant/project/auth/infra) | `repo:kdcube/app/ai-app/docs/configuration/assembly-descriptor-README.md` |
| Bundles descriptor (app registry, sources, config) | `repo:kdcube/app/ai-app/docs/configuration/bundles-descriptor-README.md` |
| Secrets descriptor (platform secrets) | `repo:kdcube/app/ai-app/docs/configuration/secrets-descriptor-README.md` |
| How descriptors → props/secrets at ALL levels (platform/bundle/user) | `repo:kdcube/app/ai-app/docs/configuration/service-runtime-configuration-mapping-README.md` |
| Edit descriptor YAML, then `kdcube refresh` | (operator edits `bundles.yaml`/`bundles.secrets.yaml`/`assembly.yaml`, then reloads — see CLI + quick-start) |
| Docker logs | `docker compose -f app/ai-app/deployment/docker/all_in_one/docker-compose.yml logs -f <service>` |

### D. App (bundle) authoring
| Topic | repo: ref |
|-------|-----------|
| Canonical app form / write a bundle | `repo:kdcube/app/ai-app/docs/sdk/bundle/build/how-to-write-bundle-README.md` |
| Configure & run | `repo:kdcube/app/ai-app/docs/sdk/bundle/build/how-to-configure-and-run-bundle-README.md` |
| Test | `repo:kdcube/app/ai-app/docs/sdk/bundle/build/how-to-test-bundle-README.md` |
| Release content | `repo:kdcube/app/ai-app/docs/sdk/bundle/build/how-to-release-bundle-content-README.md` |
| Contract test suite | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/tests/bundle/run_bundle_suite.py` — run `python -m kdcube_ai_app.apps.chat.sdk.tests.bundle.run_bundle_suite --bundle-path <app>` |

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
| workspace | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/workspace@2026-03-31-13-36/` | surface reference (React, economics, memory, canvas, Telegram, widgets, MCP) |
| user-memories | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/user-memories@2026-06-26/` | minimal app deriving the memory+economics mixin (widget + `mem` named service) |
| connection-hub | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/connection-hub@1-0/` | strong `AGENTS.md`, interface, and storage-ownership structure |
| kdcube-services | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/kdcube-services@1-0/` | MCP/service facade, widgets, Data Bus, signed files, OpenAPI, storage contract, and the **app-owned `@venv` + `requirements.txt`** pattern — its Google Sheets tools (served on both the productivity MCP and the `sheets` named service) run in an app venv because `gspread` is in neither base requirement — the point-need path, vs. adding a long-term dep to `requirements-chat.txt` + `requirements-chat-processor.txt`; the `@venv` contract is `repo:kdcube/app/ai-app/docs/sdk/bundle/bundle-venv-README.md` (also `tier1/04-write.md` §`@venv`) |

Examples demonstrate surfaces; the canonical package in `tier1/04-write.md`
wins when an older example has a different layout.

### F. Connection Hub — capability map

**Connection Hub is the center of KDCube's external-trust model.** It owns three
directions of trust; a bundle only **declares** what it needs and Connection Hub
resolves credentials at runtime (the agent never sees a provider token). This is
a capability map — pick the use case, then read its doc; the docs carry the
detail. Integration docs sit in three tiers: bundle-local operator setup
(`connection-hub@1-0/docs/integrations/<p>.md`) → SDK mechanics
(`docs/sdk/integrations/<p>/`) → recipe (`docs/recipes/connections/…`).

Concept + config first:

| Capability | repo: ref |
|---|---|
| Connection Hub concept: what it owns; delegated-TO vs delegated-BY vs app-as-authority | `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/connection-hub-solution-README.md` |
| Config it owns: `delegated_to_kdcube.providers.<p>` (claims→`provider_scopes`, `connector_apps`) and `delegated_credentials.oauth` (`capabilities`, `resources`, door-claim `connected_accounts`) | `repo:kdcube/app/ai-app/src/kdcube-ai-app/kdcube_ai_app/apps/chat/sdk/examples/bundles/connection-hub@1-0/` |

**Delegated TO KDCube** — the user connects an external account; the bundle acts on it:

| Capability | repo: ref |
|---|---|
| Simply connect an account and use its token in tool code (no bundle OAuth) | `repo:kdcube/app/ai-app/docs/recipes/connections/README.md`, `repo:kdcube/app/ai-app/docs/recipes/connections/integrations/resolve-connected-credential-README.md` |
| Use a connected identity in a product feature | `repo:kdcube/app/ai-app/docs/recipes/connections/use-connected-identities-in-product-feature-README.md` |
| OAuth provider (Google, Slack) vs no-OAuth (iCloud app-password) — operator setup | bundle-local `connection-hub@1-0/docs/integrations/{google,slack,icloud}.md` |
| Connect your own / any custom OAuth-2.0 or OIDC service (framework Google/Slack instantiate) | `repo:kdcube/app/ai-app/docs/sdk/integrations/custom-oauth-oidc-service-README.md`, recipe `repo:kdcube/app/ai-app/docs/recipes/connections/integrations/custom-oauth-oidc-service-README.md` |
| Google services (Gmail, Sheets) — recipe + SDK scope mechanics | `repo:kdcube/app/ai-app/docs/recipes/connections/integrations/google-service-README.md`, `repo:kdcube/app/ai-app/docs/sdk/integrations/google/google-README.md` |
| Wrap a connected-account capability as a provider-neutral **named service** | `repo:kdcube/app/ai-app/docs/recipes/components/named-service-README.md`, `repo:kdcube/app/ai-app/docs/recipes/connections/integrations/mail-named-service-README.md` |
| **More than one account connected**: `account_required` + labeled candidates, per-account binding, search fan-out | `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/authenticated-mcp/authenticated-mcp-README.md`, `repo:kdcube/app/ai-app/docs/recipes/connections/integrations/mail-named-service-README.md` |

**Delegated BY KDCube** — KDCube issues a bounded credential so an external client/agent enters the user's app:

| Capability | repo: ref |
|---|---|
| Expose your app's MCP to an external agent / Claude Code (managed credentials) | `repo:kdcube/app/ai-app/docs/recipes/connections/delegate-kdcube-service-to-external-client-README.md`, `repo:kdcube/app/ai-app/docs/recipes/connections/protect-bundle-mcp-with-managed-credentials-README.md` |
| Guard a bundle REST operation with managed credentials | `repo:kdcube/app/ai-app/docs/recipes/connections/protect-bundle-rest-with-managed-credentials-README.md` |
| Expose named services as ONE generic MCP surface to external agents | `repo:kdcube/app/ai-app/docs/recipes/apps/named-services-mcp-README.md` |
| The OAuth authorization-server protocol (PKCE, DCR, consent, token issue) | `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/delegated-credentials/oauth-delegated-credential-protocol-adapter-README.md` |
| Two gates + demand-driven per-agent/per-account consent; `connected_accounts` contract | `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/authenticated-mcp/authenticated-mcp-README.md`, `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/claim-driven-consent/claim-driven-consent-README.md` |
| Bounded automation access (script/CI token with a TTL) | `repo:kdcube/app/ai-app/docs/recipes/connections/create-delegated-automation-access-README.md` |

**App as platform authority** — the user's own app hosts login / is the auth provider:

| Capability | repo: ref |
|---|---|
| Host login / make your app KDCube's platform authority | `repo:kdcube/app/ai-app/docs/recipes/connections/platform-authority/host-platform-authority-in-bundle-README.md` |
| Authority provider runtime + projection into KDCube sessions | `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/authority-providers/authority-provider-runtime-README.md`, `repo:kdcube/app/ai-app/docs/sdk/solutions/connections/authority-projection/authority-projection-README.md` |

**Cross-cutting**

| Capability | repo: ref |
|---|---|
| Make a named service; expose a governed service over MCP (recipes) | `repo:kdcube/app/ai-app/docs/recipes/components/named-service-README.md`, `repo:kdcube/app/ai-app/docs/recipes/quickstart/expose-governed-service-mcp-README.md` |
| Named services as a namespace (SDK) | `repo:kdcube/app/ai-app/docs/sdk/namespace-services/README.md`, `repo:kdcube/app/ai-app/docs/sdk/namespace-services/providers-README.md` |
| How a provider failure presents/propagates across tool/named-service/REST/MCP | `repo:kdcube/app/ai-app/docs/sdk/integrations/provider-error-contract-README.md` |
| SDK integrations index (per-provider mechanics) | `repo:kdcube/app/ai-app/docs/sdk/integrations/README.md` |

# Canonical KDCube App Form

The shape every KDCube **app (bundle)** should converge on. `bundle-new`
scaffolds it; `bundle-maintain` keeps it true. The canonical authoring guide is
the authority; examples demonstrate individual surfaces but never override the
package contract. Use **connection-hub** for strong `AGENTS.md`/storage shape,
**kdcube-services** for interface and service-facade shape, and **workspace**
for full chat/scene/agent wiring. Authoring rules live in
`repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-write-bundle-README.md`
(also in `tier1/04-write.md`).

> Terminology: "app" == "bundle" during the rebrand. Identifiers stay verbatim
> (`bundle_id`, `bundles.yaml`, `@bundle_entrypoint`).

## Layout

```text
<app>@<version>/
  entrypoint.py            # @bundle_entrypoint + @bundle_id; derives the right base class (see the
                           #   base-class table in how-to-write-bundle); configuration_defaults().
  __init__.py
  README.md                # frontmatter (id/title/summary/status/tags/module/singleton/primary_surfaces/links)
                           #   + product shape + layout. The human entry point.
  AGENTS.md                # the per-app BUILDER MEMORY: frontmatter + see_also + "Read First" + product shape
                           #   + implementation rules + decisions-not-to-relitigate + journal pointer.
  release.yaml             # repo + ref + description (Highlights + Known follow-ups).
  requirements.txt         # ONLY when app-local Python dependencies are required.
  config/
    bundles.template.yaml          # non-secret deployment props (mirrors configuration_defaults()).
    bundles.secrets.template.yaml  # secret KEYS only — never values.
  interface/               # THE CONTRACT (so consumers + future builders don't read code to learn the surfaces):
    README.md              #   operations, widgets, named services, storages, dataflows, auth, payloads.
    <app>.openapi.yaml     #   HTTP paths plus x-kdcube-surfaces; paths may be empty.
    as_provider/           #   if it provides a named service (optional).
  docs/
    README.md              # architecture/module-owner index.
    design/                # optional deeper architecture / flows / scenarios.
    runtime/               # optional deeper runtime wiring.
    storage/               # required ownership, scope, retention, backup, cleanup map.
    journal/               # DATED decision log + README. The why behind in-flight work. NOT a single file.
    integrations/          # Telegram / email / OAuth / webhooks — only if the app integrates externally.
  tests/                   # bundle-local tests. Also run the contract suite (below).
  ui/                      # ONLY if the app ships UI: main/ and/or widgets/<alias>/. Shared SDK widgets
                           #   (memories, usage_card) are referenced by sdk:// — do NOT copy them in.

  agents/                  # only when the app owns agent orchestration.
  services/                # domain behavior; preferred product-logic owner.
  surfaces/                # thin API/MCP/widget/Data Bus adapters.
  events/                  # event declarations, policy, and rehosters.
  tools/                   # app-owned tools.
  skills/                  # app-owned skills.
  resources/               # prompts/templates/static service resources.
  scripts/                 # developer/operator scripts, never request-path code.
```

Sections marked optional are dropped only when genuinely absent; when in doubt,
keep the file with a one-line "(none yet)" rather than omitting it — the absence
is a signal.

## Sparse root and modular implementation

The app root contains declarations and composition only: `__init__.py`,
`entrypoint.py`, `README.md`, `AGENTS.md`, `release.yaml`, optional
`requirements.txt`, and declaration folders. Do not put domain logic, service
implementations, handlers, storage adapters, tools, or generic helper modules
beside `entrypoint.py`.

Put implementation under responsibility-named folders and modules. Prefer
`services/conversations/export.py` or `surfaces/mcp/conversations.py` over
`logic.py`, `helpers.py`, `misc.py`, or `utils.py`. Document every top-level
implementation folder and its owner in `README.md` and `docs/README.md`; give
important subsystems a local README and non-obvious modules a concise docstring.

## Async runtime invariant

KDCube apps execute inside a concurrent asyncio proc. Every lifecycle hook,
decorated handler, service operation, and I/O call chain must be async end to
end. Use async SDK, storage, database, Redis, HTTP, and subprocess APIs and
await them. An `async def` wrapper around blocking code still blocks the event
loop.

If a bounded blocking library has no async replacement, isolate only that call
with `await asyncio.to_thread(...)`; move long CPU-bound or operational work to
a worker/job. Small pure in-memory helpers may remain synchronous.

## What each load-bearing piece must carry

- **entrypoint.py** — `@bundle_entrypoint` + `@bundle_id`, the right base class
  (plain / economics / memory / economics+memory — see the base-class table),
  `configuration_defaults()`, and the surfaces (`@api`, `@ui_widget`, `@ui_main`,
  `@mcp`, `@cron`, `@on_job`, data-bus handlers). Even a non-chat app sets
  `self.graph` + `execute_core` (no-op pattern). It composes modules; it does
  not contain domain implementations.
- **README.md** — frontmatter + what the app is, its surfaces, and its layout.
  Human-first.
- **AGENTS.md** — the *why* a fresh clone can't infer: identity, surfaces, SDK
  blocks reused (so nobody reimplements the SDK), config consumed, decisions not
  to relitigate, bundle-specific guardrails, and a pointer to the journal. Keep
  it current — it is the next builder's memory.
- **interface/** — the externally-visible contract. Every operation/widget/named
  service/storage/dataflow the app exposes, with auth and payloads. This is what
  another app or scene reads to integrate without your source.
- **docs/design/** — architecture, dataflows, scenarios, UI surfaces.
- **docs/runtime/** — how it actually runs: routing, event sources, storage &
  search, lifecycle.
- **docs/storage/** — the data model: stores, scope (user/bundle/global), schema,
  retention, debug paths.
- **docs/journal/** — one dated file per decision/round:
  `YYYY-MM-DD-<topic>.md` with `## Summary / ## Decisions / ## Files /
  ## Follow-Up`. Read the latest before touching in-flight work. (workspace's
  journal is thin — do NOT model on it; task-tracker is the model.)
- **config/** — the descriptor templates. Props in the plain template, secret
  KEYS (no values) in the secrets template.
- **release.yaml** — repo, ref, and a description with Highlights + Known
  follow-ups.
- **tests/** — bundle-local tests AND the contract suite:
  `python -m kdcube_ai_app.apps.chat.sdk.tests.bundle.run_bundle_suite --bundle-path <app>`.

## Definition of done for a new app

entrypoint compiles • root is sparse • implementation is modular, named, and
documented • runtime/I/O paths are async end to end • README + AGENTS written •
interface/README and OpenAPI document every surface • docs/storage and docs/journal
are initialized • config templates contain no real secrets • release.yaml is
present • focused tests and the contract suite pass.

---
description: "Scaffold a modular, async KDCube app in the canonical sparse-root form (entrypoint, README, AGENTS, optional requirements, config, interface, docs, release, tests). Refuses to scaffold without explicit operator inputs; never writes real secrets and never commits."
---

# /kdcube:bundle-new

Scaffold a new KDCube app in the **canonical app form**. **Do not assume
defaults.** Required inputs before any file is written:

- `app_id` (bundle_id) — e.g. `task-and-memo-app@1-0`. Follows `name@version`.
- `app_path` — relative to the repo root, e.g. `src/task-and-memo-app@1-0`.
- base class need — plain / economics / memory / economics+memory (see the
  base-class table in `tier1/04-write.md`).
- source/runtime mode for first local run (`local`, `git`, or `built-in`).
- planned provider/consumer surface map; for MCP, state whether the app consumes
  servers, provides endpoints, or does both.
- planned SDK building blocks reused (Tasks, Email, Telegram, Delivery, memory…).
- first-run config keys + secret NAMES (values are never written to source).

Steps:

1. **Read the form.** Read `${CLAUDE_PLUGIN_ROOT}/templates/canonical-app-form.md`
   (the layout + definition of done) and
   `tier1/04-write.md#1b1-canonical-app-package` (package contract + base-class
   guidance). Examples may demonstrate surfaces but do not override this form.

2. **Map surfaces, then reuse before building.** Read
   `tier1/03-assemble.md#surface-first-rule`; for each planned surface check
   whether an SDK block already covers it. If the operator means to
   reimplement an existing block, **stop and ask**. For Telegram/email/OAuth, use
   the **kdcube-docs** skill to read the integration docs/source
   (`rg -i telegram` under `app/ai-app/docs` and the SDK integrations) first.

3. **Scaffold the canonical form** at `<app_path>/`:
   - `__init__.py`; `entrypoint.py` — `@bundle_entrypoint` + `@bundle_id`, the
     chosen base class, `configuration_defaults()`, and the planned surfaces. A
     non-chat app still sets `self.graph` + `execute_core` (no-op pattern).
     Keep it as composition only.
   - `README.md` (frontmatter + product shape + layout); `AGENTS.md` from
     `${CLAUDE_PLUGIN_ROOT}/templates/bundle-AGENTS.md`, pre-filled from the
     inputs; `release.yaml`; root `requirements.txt` only if app-local Python
     dependencies are actually required.
   - Put all implementation under documented, responsibility-named folders such
     as `services/`, `surfaces/`, `agents/`, `events/`, `tools/`, and `skills/`.
     Do not create root-level product modules or vague `logic/helpers/misc/utils`
     buckets.
   - `config/bundles.template.yaml` + `config/bundles.secrets.template.yaml`
     (safe example values; secret KEYS only — never values).
   - `interface/README.md` — the surfaces contract (operations, widgets, named
     services, storages, dataflows, auth, payloads); add `<app>.openapi.yaml`
     with empty `paths` when no HTTP surface exists and `x-kdcube-surfaces` for
     non-HTTP surfaces.
   - `docs/README.md` (architecture/module map) and
     `docs/storage/README.md`; add `docs/design/`, `docs/runtime/`, and
     `docs/integrations/` only when those deeper contracts exist.
   - `docs/journal/README.md`, `docs/journal/journal.md`, and the FIRST dated
     entry `docs/journal/<YYYY-MM-DD>-bootstrap.md` from
     `${CLAUDE_PLUGIN_ROOT}/templates/journal-entry.md`, recording the bootstrap
     decisions (base class chosen, surfaces, SDK blocks reused).
   - `tests/` with one smoke test that imports the entrypoint.
   - `ui/` ONLY if UI is planned (`main/` and/or `widgets/<alias>/`); shared SDK
     widgets (memories, usage_card) are referenced by `sdk://…` — never copied in.
   - Make every lifecycle hook, decorated handler, service operation, and I/O
     call chain async end to end. Use async clients; isolate unavoidable bounded
     blocking calls with `await asyncio.to_thread(...)`.

4. **Validate.** Compile `entrypoint.py` and all app Python modules, run focused
   tests for async surface/storage behavior, then the
   contract suite:
   `python -m kdcube_ai_app.apps.chat.sdk.tests.bundle.run_bundle_suite --bundle-path <app_path>`.
   It must pass before the app is considered scaffolded.

5. **Next.** Point at `/kdcube:bundle-configure` for runtime
   registration. Do not write runtime-local paths or real secrets into source.

6. **Summary.** Print the created tree + a plan-and-changes summary. **Do not**
   stage, commit, or push — the files stay dirty until the operator decides.

Refuse if the app path already exists and is non-empty, or the operator hasn't
named the app id explicitly.

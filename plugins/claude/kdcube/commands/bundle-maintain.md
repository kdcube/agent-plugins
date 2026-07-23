---
description: "Maintain an existing KDCube bundle repo: understand the business intent, update interfaces/code/config/docs/tests/journal, and prepare release metadata without committing unless approved."
---

# /kdcube:bundle-maintain

Work on an existing KDCube bundle as a maintainer, not just as a code
editor.

Inputs:

- bundle root path;
- user goal;
- whether runtime testing is available now;
- whether release preparation is in scope. Commit/tag/push still
  requires explicit approval through `/kdcube:bundle-release`.

Steps:

1. Read, in order (the canonical app set — see
   `${CLAUDE_PLUGIN_ROOT}/templates/canonical-app-form.md`):
   - app `AGENTS.md` if present;
   - app `README.md`;
   - `interface/README.md` — the surfaces contract;
   - the machine-readable interface declaration;
   - `docs/README.md` + `docs/storage/README.md` and any relevant deeper page;
   - the **latest dated entry** in `docs/journal/`;
   - `release.yaml`;
   - `config/bundles.template.yaml` + `config/bundles.secrets.template.yaml`;
   - `entrypoint.py` and workflow/orchestrator files.

2. Read Tier 1 docs based on the task:
   - implementation: `tier1/03-assemble.md` and `tier1/04-write.md`;
   - config/secrets: `tier1/05-runtime-config.md`;
   - run/deploy: `tier1/06-configure-and-run.md`;
   - React/MCP/Claude Code integration: `tier1/08-agent-integration.md`;
   - release: `tier1/07-release-content.md`.

3. Maintain all affected surfaces together:
   - code and decorators;
   - API/MCP/widget visibility and configurability;
   - bundle props and bundle secrets;
   - user props and user secrets;
   - UI source and build notes;
   - tests and smoke scenarios;
   - README, interface docs, config templates, journal, release notes.
   - keep the root sparse; preserve responsibility-named implementation folders
     and update the documented module-owner map;
   - keep lifecycle hooks, handlers, services, and I/O call chains async end to
     end; do not call blocking libraries from the proc event loop.

4. Use existing SDK blocks before writing custom mechanics:
   Tasks, Email, Telegram, Delivery, ReAct runtime/tools, MCP,
   storage, widgets, jobs, and Claude Code integration.
   For Telegram changes, use the **kdcube-docs** skill to read the
   Telegram SDK wiring checklist and external prerequisites from the local
   repo (e.g. `rg -i telegram` under `app/ai-app/docs` and
   `app/ai-app/src/.../integrations/telegram`) before changing webhook,
   Mini App, registry, or delivery code.

5. Add a dated journal entry for meaningful changes — a new
   `docs/journal/<YYYY-MM-DD>-<topic>.md` (per
   `${CLAUDE_PLUGIN_ROOT}/templates/journal-entry.md`) with Summary, Decisions,
   Files, and Follow-Up. Keep `interface/README.md` and the relevant `docs/` page
   in sync with what changed.

6. Stop before release actions unless the operator explicitly approves
   `/kdcube:bundle-release`.

Common bundle-maintenance guardrails:

- API/MCP/widget `enabled`, roles, and user types should be configured
  through the current decorator configuration fields documented in
  Tier 1. Do not resurrect deprecated `enabled_config` arguments.
- Bundles may expose UI assets and widgets; KDCube can serve and embed
  them. Do not call this a "bundle iframe" as if such a bundle type
  exists.
- Do not store user credentials in descriptors, Redis, logs, README,
  journal, or tests. Use user secrets/bundle secrets through the
  configured runtime APIs.
- Do not claim a bundle is release-ready until tests and descriptor
  alignment have been checked.
- Do not move product logic into `entrypoint.py` or root-level helper modules.
- Do not confuse `async def` with non-blocking behavior: use async clients and
  isolate unavoidable bounded synchronous calls with `asyncio.to_thread`.

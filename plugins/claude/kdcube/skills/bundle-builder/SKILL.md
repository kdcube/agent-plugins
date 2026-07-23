---
name: bundle-builder
description: "Primary KDCube bundle-author skill: ONE planning agent that combines creator, integrator, configurator, deployer, local-QA, integration-QA, and document-reader facets. Auto-loads on every session in a working area that includes a KDCube bundle, an applications-style repo, or this plugin's own area."
---

# KDCube Bundle Builder

You are the planning agent for building, configuring, testing, and (when
the operator approves) releasing KDCube bundles.

The KDCube platform docs handoff contract requires **one** planning
agent that routes between task facets, not separate personas. The
facets are:

- creator
- integrator
- configurator
- deployer
- local QA
- integration QA
- document reader

These are routing hints inside *this* skill, not separate sub-agents.

## What you have

- **Tier 1 pack** at `${CLAUDE_PLUGIN_ROOT}/tier1/` — the canonical
  build baseline. Always read `00-pack-contract.md` first if
  you have not seen it this session: it lists the agent guardrails
  and the preferred reading order. Then `01-navigate.md` is the
  router into deeper kdcube docs.
- **Canonical kdcube mind map** at
  `repo:kdcube-ai-app/app/ai-app/docs/recipes/what-i-should-know-about-app-README.md`
  — use it before designing an unfamiliar app boundary; Tier 1 owns the
  detailed implementation and verification contracts.
- **kdcube-docs skill** — read the local `kdcube-ai-app` repo (docs +
  source) for any KDCube ground truth. It carries a topic→path index
  into the repo: resolve each `repo:kdcube-ai-app/<path>` ref, Read it,
  and `rg`/`find` the repo for anything not indexed. There is no
  knowledge service. See `kdcube-docs/SKILL.md`.
- **Symbolic-ref resolver** — turn `repo:kdcube-ai-app/path/...` into
  an absolute local path so you can Read/grep/edit the local checkout.
  See `ref-resolver/SKILL.md`.
- **kdcube-operator skill** — for runtime ops: descriptors and props/secrets
  at the platform/bundle/user levels, and the configure → reload/refresh →
  verify → logs loop (incl. docker logs). See `kdcube-operator/SKILL.md`.
- **Canonical app form** at `${CLAUDE_PLUGIN_ROOT}/templates/canonical-app-form.md`
  — the layout every app converges on (entrypoint, README, AGENTS, config,
  interface, `docs/{storage,journal}`, optional deeper docs, release, tests),
  its sparse-root/modularity rule, and its async runtime invariant. `bundle-new`
  scaffolds it; `bundle-maintain` keeps it true.
- **Bundle's own AGENTS.md** — when working inside a specific app
  directory, that app's `AGENTS.md` is the builder memory (per
  `${CLAUDE_PLUGIN_ROOT}/templates/bundle-AGENTS.md`); decision history lives in
  dated `docs/journal/` entries (`${CLAUDE_PLUGIN_ROOT}/templates/journal-entry.md`).
- **Doc-reader sub-agent** at `agents/doc-reader.md` — delegate
  large doc digests to it so this skill's context stays light.

## Reading order at session start

Per the handoff contract, the right order is:

1. **navigation** — `tier1/01-navigate.md`. Do not bypass this. It
   tells you which deeper KDCube doc to read next based on the user's
   ask.
2. **test expectations** — `tier1/02-test.md`, especially the
   "1A Working Environment for Agents" section. This is the preflight
   before any code or test command. **Do not run bare `python3` or
   `pytest` until you have proved the project venv.**
3. **app surface map, then reusable SDK building blocks** —
   `tier1/03-assemble.md`. Apply its Surface-First Rule before implementing,
   including the independent MCP `as_consumer` and `as_provider` decisions;
   then select from the SDK catalog instead of reimplementing a platform block.
4. **implementation design** — `tier1/04-write.md`. The canonical package,
   sparse-root/modularity, and async runtime contracts are here.
5. **configuration ownership** — `tier1/05-runtime-config.md`. Bundle
   props vs bundle secrets vs user props vs user secrets vs platform.
6. **runtime and deployment wiring** — `tier1/06-configure-and-run.md`.
   Descriptor staging, kdcube CLI.

Optional, only when relevant:

- `tier1/07-release-content.md` — only after the user explicitly
  agrees to commit/tag/push/release.
- `tier1/08-agent-integration.md` — when the bundle uses React tools/
  skills, file-producing tools, MCP, or Claude Code subprocesses.
- `tier1/09-local-public-ngrok.md` — when local KDCube must be reachable
  from external providers through public HTTPS, such as Telegram webhooks,
  OAuth/Cognito callbacks, or remote callback/control flows.
- `tier1/10-widget-integration.md` — when writing or reviewing widgets,
  generated-static HTML apps, Mini Apps, or any browser-facing bundle API
  client.
- For Telegram bundle work, use the **kdcube-docs** skill to read the
  Telegram integration docs/source in the local repo (e.g. `rg -i telegram`
  under `app/ai-app/docs` and `app/ai-app/src/.../integrations/telegram`).
  They contain the SDK-first bundle wiring checklist and the external
  BotFather/webhook/Mini App prerequisites.

Critical browser/widget rule:

- widget and generated-static HTML API clients must call KDCube through the
  KDCube frame/runtime origin
- use `baseUrl` from the runtime config bridge first, then the widget frame's
  own `window.location.origin` as fallback
- never use `window.top.location`, `document.referrer`, or an embedding host
  page URL as the API base
- before writing widget networking code, read
  `tier1/10-widget-integration.md#frame-origin-and-api-base-url`

## Regular CLI workflow

The normal operator path is CLI-first:

1. Validate this plugin with `/kdcube:init`.
2. Initialize the KDCube runtime with `/kdcube:runtime-init`.
   This command owns the `kdcube init --set-secret ...` flow. The
   common first-run secret names are:
   - `services.openai.api_key`
   - `services.anthropic.api_key`
   - `services.brave.api_key`
   - `services.git.http_token`
   - `git.http_token`
3. Register or update the bundle with
   `/kdcube:bundle-configure`. This command owns
   `kdcube bundle`: source mode (`local`, `git`, or `built-in`),
   plain config, secrets, reload, and `kdcube info` verification.
4. Maintain bundle source with `/kdcube:bundle-maintain`.
   This command owns code, decorators, interfaces, config templates,
   docs, journal, tests, and release metadata.
5. Run `/kdcube:bundle-test`.
6. Run `/kdcube:bundle-release` only after the operator names
   the release version and explicitly approves commit/tag/push.

Do not replace these with ad-hoc descriptor edits unless the operator
explicitly asks to edit source descriptor files.

## Bundle maintenance artifacts

For an existing bundle, keep these in sync with code changes:

- `AGENTS.md` — business intent and guardrails for future agents.
- `README.md` — user/operator-facing contract.
- `release.yaml` — current release metadata.
- `config/bundles.template.yaml` — non-secret bundle/user props
  shape with safe examples.
- `config/bundles.secrets.template.yaml` — secret key names and safe
  example placeholders only.
- `interface/README.md` and OpenAPI — all HTTP and non-HTTP surfaces.
- `docs/README.md` and `docs/storage/README.md` — module owners and storage map.
- `docs/design/` — design decisions and interface shape.
- `docs/journal/` — short maintenance entries for meaningful changes.
- `tests/` — unit/smoke/integration tests matching the touched surface.
- UI source and build notes when the bundle exposes widgets or main UI.

## Planning loop

For any non-trivial bundle task:

1. Write the app surface map from `03-assemble.md#surface-first-rule`: what the
   app provides, what it consumes, and which MCP direction applies.
2. Identify the task facet (creator / integrator / configurator /
   deployer / local QA / integration QA / doc reader).
3. Pick the minimum tier-1 doc set required (see the routing in
   `01-navigate.md`).
4. Use the **kdcube-docs** skill to read the local `kdcube-ai-app` repo
   for product context (entities, flows, scenarios): follow its index →
   `repo:` refs → ref-resolver → Read, and `rg`/`find` the repo for the
   rest.
5. Resolve `repo:` refs to local paths via the ref-resolver, then
   inspect, grep, or edit the local checkout.
6. Use the `doc-reader` sub-agent for any doc longer than ~500 lines
   you only need a digest of.
7. Write a short plan and surface it. **Do not** proceed to commit,
   tag, push, or descriptor-update steps without explicit operator
   approval.

## Preflight facts

Before changing bundle code or runtime configuration, identify and keep current:

- bundle id and bundle root;
- KDCube source path, when a local platform checkout or staged `<workdir>/repo`
  is available;
- applications/content repo path, when the bundle lives outside the platform
  repo;
- active tenant, project, and workdir;
- whether KDCube source comes from local source, staged runtime source, or a
  selected release/ref;
- whether seed descriptors or staged runtime descriptors are the current
  authority;
- whether the bundle is configured in the active runtime;
- whether KDCube is running;
- exact commands the operator can run for `info`, `start`, `stop`, `refresh`,
  and `bundle reload`;
- validation surfaces for this task: chat, APIs, widgets, public routes,
  Telegram, email, cron, background jobs, MCP, generated files, or release.

Do not claim live validation unless the bundle is configured in a running
KDCube runtime and the relevant route, widget, API, or chat probe actually ran.

## Recurring mistakes to avoid (from the contract)

- begin every app design with the provider/consumer surface map; for MCP,
  record consumption (`as_consumer`, per-agent allow-list), provision
  (`as_provider`, `@mcp` + auth owner), or both. See
  `03-assemble.md#surface-first-rule`;
- do not recommend bare `python3` or bare `pytest` before proving the
  project venv;
- do not interpret async test failures until `pytest-asyncio` is in
  the active venv;
- do not start a new app without the package declarations from
  `04-write.md#1b1-canonical-app-package`;
- do not place product implementation beside `entrypoint.py`; keep the root
  sparse and use documented, responsibility-named modules under folders;
- do not use synchronous I/O in lifecycle hooks, handlers, services, or their
  call chains; the proc is concurrent asyncio, and `async def` around blocking
  code still blocks the event loop. The existing `get_user_prop`,
  `get_user_props`, `set_user_prop`, and `delete_user_prop` names are async and
  must always be awaited; see `05-runtime-config.md`;
- do not reimplement provider/runtime mechanics before checking the
  SDK building-block map in `03-assemble.md`;
- do not write `/bundles/...` into a seed/source descriptor that is
  also used by host-side runs without first determining whether
  you're editing a seed or a staged-runtime descriptor;
- do not add a bundle `@venv` / `requirements.txt` for a library already in the  
  chat-processor base image — and do not decide base membership by importing in  
  your `.venv` (a test venv is not the proc container; a successful import there  
  can be a local or transitive install). Grep the declared proc requirements by  
  name; see the base-deps note in `03-assemble.md` for the exact check;
- do not manually build `ui-src` into runtime bundle storage as the
  fix for stale bundle UI;
- do not describe UI integration as a "bundle iframe" type. Bundles
  can expose UI assets and widgets; KDCube can serve and embed those
  assets, but iframe embedding is a host behavior, not a bundle kind;
- do not use source folder names or compiled example ids for a served
  widget's bundle id; resolve it route-first (the URL it is served from —
  `bundle_id`/`bundleId` param), and use host `defaultAppBundleId` only as a
  fallback when the route yields none — a cross-bundle host handshake must not
  override the route;
- do not resurrect deprecated resource-level `enabled_config`
  arguments. Use the current decorator/configuration fields documented
  in Tier 1 for enabled flags, roles, and user types;
- do not treat `bundles.yaml` example config as enabling built-in
  examples; `bundles_include_examples` owns that;
- do not treat `singleton` as cross-process exclusivity or
  shared-storage initialization;
- do not treat bundle `user_id` as always being a KDCube account id;
- do not expose model-facing tool parameters for runtime ids the
  model cannot know;
- do not hand-roll OAuth, a service account, or provider auth libraries to act  
  on a user's external account (Google/Sheets, Slack, iCloud, …); Connection Hub  
  **delegated-to-KDCube** brokers consent/token/refresh — check the connected-accounts row in `03-assemble.md`;
- do not expose proc as a separate public URL for local webhook/callback
  testing; use the one-origin ngrok reverse-proxy flow in
  `tier1/09-local-public-ngrok.md` when localhost needs public HTTPS;
- do not hand-roll Telegram user registry, webhook duplicate handling, Mini
  App `initData` verification, or Telegram delivery when the SDK Telegram
  subsystem fits the bundle;
- do not put real secrets or user credentials in descriptors, Redis,
  logs, README files, journals, or tests. Use bundle secrets/user
  secrets and the configured runtime APIs;
- never use `os.environ` in bundle code. App and user properties/secrets are
  defined in `bundles.yaml`/`bundles.secrets.yaml` and the user-scoped store,
  and read/set through the helper contract (`bundle_prop`,
  `await get_secret("b:...")`/`("u:...")`, `await set_bundle_prop(...)`,
  `await set_user_prop(...)`, `await set_user_secret(...)`); every
  operator-facing runtime knob must exist as a descriptor property — an
  env-only knob has no deployment
  surface. A vendored
  standalone solution's env config stays its standalone idiom, overlaid by the
  descriptor property in the wrap. See `04-write.md` "The `os.environ` rule";
- do not carry dynamic per-request state in `os.environ` or module globals:
  execution crosses fences (async task, thread, subprocess, Docker/Fargate)
  and only the portable cross-runtime context (`PORTABLE_SPEC_JSON` snapshot →
  child bootstrap) survives the hop — anything else is silently absent in the
  child runtime. See `11-common-failures.md` "Dynamic Context Crosses Fences
  Only Via The Portable Context" and the platform runtime docs
  (`docs/runtime/cross-runtime-context-README.md`,
  `docs/runtime/fenced-runtime-bootstrap-and-reduce-README.md`);
- do not write local host paths into cloud/shared descriptors. Local
  paths are acceptable only for local debug descriptors or staged
  runtime state where that path is visible to the runtime;
- file-producing tools use the strict `ret.artifact_type == "files"`
  protocol with `ret.files[]`, or trusted tool-side `host_files(...)`;
- do not commit, tag, push, or update descriptor refs unless the user
  has explicitly agreed to the content release values.

## When the agent is unsure

- If a `repo:` ref does not resolve, stop and ask the operator to
  populate `config/repos.yaml`. Don't guess paths.
- If the local `kdcube-ai-app` repo is not resolvable, run
  `/kdcube:init` to locate or clone it rather than
  fabricating coverage from memory.
- If the bundle has no AGENTS.md, suggest dropping in the template
  from `${CLAUDE_PLUGIN_ROOT}/templates/bundle-AGENTS.md` so future
  sessions pick up the bundle's business-logic memory.

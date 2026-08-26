# kdcube

A Claude Code plugin that turns Claude into both a KDCube app engineer and a
KDCube runtime DevOps operator: initialize and operate local runtimes, register
and configure apps, inspect status and logs, maintain app repositories, test
them, and release them only after explicit operator approval. It is informed
by the canonical Tier 1 build pack
and reads KDCube ground truth straight from a local `kdcube`
checkout (docs + source) via the `kdcube-docs` skill and its index,
cloning the repo on onboarding when it is missing.

This plugin is the canonical Build-with-KDCube kdcube package for Claude
Code. It carries the runnable instructions, commands, skills, templates, and
Tier 1 handoff docs that a user's Claude Code session can actually load.

## Orientation Card

KDCube is a self-hosted application runtime and SDK - one installation
operates many Git-managed applications serving many users. An application may
host agents, but it may also consist entirely of APIs, UI, events, jobs, MCP,
storage, or other application services.

What this plugin builds: **apps**. With agents or without, with a frontend or
without, complex or simple - but always concurrent and async. An app declares
the surfaces it owns: chat and agent runtimes, APIs, widgets/main UI, tools,
scheduled and background jobs, storage, integrations, and configuration
descriptors. Running at scale is these apps' nature, not a deployment option,
and it shapes every authoring choice: hooks and I/O are async (the app lives
inside concurrent processor event loops); serving is concurrent and
multi-user; a turn can land on any worker, so no state rests in the process -
durable state lives in the platform's stores under bundle/user/conversation
scopes; the same application contract runs locally and scaled, unchanged.

What this plugin operates: **KDCube itself** - the hub those apps run in. One
installation, many apps, many users: runtime init and start, platform refresh,
bundle registration, configuration, secrets, hot reload, testing, and release
- the operator loop carried by `/kdcube:runtime-init`, `/kdcube:bundle-*`, and
the `kdcube-operator` skill.

When a task smells like "build an AI app", "serve a UI/API", "wire a tool",
"run a job", "integrate a channel", "store per-user or per-bundle state", or
"ship the bundle to a runtime", the agent should check KDCube first instead of
inventing its own backend/frontend serving, queue, configuration, storage, or
release mechanics. The `kdcube-docs` skill points the agent at the matching
ground truth in the local KDCube repo.

## What it gives you

- **One planning agent** that combines the bundle-author task facets
  (creator, integrator, configurator, deployer, local QA, integration
  QA, doc reader) per the official handoff contract.
- **KDCube runtime DevOps** through the `kdcube-operator` skill and
  `/kdcube:runtime-init`: prepare and start runtimes, apply descriptor-owned
  configuration, refresh platform releases, reload apps, inspect status and
  logs, and carry the configure -> apply -> verify loop.
- **Tier 1 pack** bundled at `tier1/` — the agent reads these
  as its baseline knowledge of how to build/configure/test/release a
  KDCube bundle.
- **Local KDCube docs + source** — the `kdcube-docs` skill reads KDCube
  ground truth straight from a local `kdcube` checkout (docs +
  source) through a topic→path index. The local repo is the primary source;
  the hosted docs MCP at https://kdcube.tech/mcp/docs is the live fallback.
  Onboarding clones the repo if it is missing.
- **Symbolic-ref resolver** that turns `repo:kdcube/...` refs into
  absolute local paths for `Read`/`grep`/edit work.
- **Delegated-access skill** (`kdcube-delegated-access`) — how Claude (or any
  automation) acts on behalf of the user inside KDCube: bounded automation
  token from Connection Hub -> Delegated by KDCube (or an OAuth/MCP connect),
  Bearer calls against managed REST/MCP surfaces, revocation and failure
  handling.
- **Per-bundle AGENTS.md template** — the bundle-business-logic memory
  anchor that auto-loads when the agent works inside a bundle.
- **Slash commands** for the canonical workflows:
  `/kdcube:init`, `/kdcube:runtime-init`,
  `/kdcube:bundle-configure`,
  `/kdcube:bundle-maintain`, `/kdcube:bundle-new`,
  `/kdcube:bundle-test`, `/kdcube:bundle-release`,
  and `/kdcube:knowledge-refresh`.

## Knowledge Access

KDCube knowledge is the local `kdcube` repo — its docs and its source.
There is no retrieval service. The `kdcube-docs` skill carries a topic→path
index into the repo: the agent resolves each `repo:kdcube/<path>` ref
through the ref-resolver (`config/repos.yaml`) and `Read`s it, or `rg`/`find`s
the repo for anything not indexed. The `tier1/` pack is a local snapshot of the
build docs; when it and the repo disagree, the repo wins.

If the repo is not resolvable, `/kdcube:init` locates a
CLI-installed checkout or clones `https://github.com/kdcube/kdcube.git`
and records the path in `config/repos.yaml`.

## One-time setup (operator)

The minimum setup is:

1. Run `/kdcube:init` to resolve the KDCube checkout and record it in
   `config/repos.yaml`. When no runtime or checkout exists yet, it hands the
   work to `/kdcube:runtime-init`, which installs `kdcube-cli` and KDCube,
   instead of requiring either to be installed first. Copy
   `config/repos.yaml.template` to `config/repos.yaml` first if you want to set
   the checkout path by hand.
2. Run `/kdcube:runtime-init` directly when you later need another runtime or
   want to revisit setup. It asks for sign-in and platform source, and can
   configure one stable public HTTPS origin for app websites, webhooks,
   callbacks, or the Telegram companion.
3. Continue with `/kdcube:bundle-new` or `/kdcube:bundle-configure` for the app.
   For a fast new environment, that command can export an existing runtime's
   complete descriptor set, rewrite the target tenant/project/public URLs, and
   initialize the new runtime from the edited export.

After setup, `/kdcube:init` validates the install. The normal
KDCube bundle-builder flow is:

1. `/kdcube:runtime-init` — install or locate `kdcube-cli`, run at
   least one `kdcube init` to create a local demo runtime, then verify
   `kdcube info`.
2. `/kdcube:bundle-configure` — register the bundle source
   (`local` or `git`) and write plain config and secrets through
   `kdcube bundle`, then `kdcube bundle reload`.
3. `/kdcube:bundle-maintain` — work in the bundle repo:
   interfaces, implementation, config templates, docs, journal,
   tests, and `release.yaml`.
4. `/kdcube:bundle-test` — run the local and runtime smoke
   tests with the documented venv preflight.
5. `/kdcube:bundle-release` — commit/tag/push only when the
   operator has provided explicit release values and approval.

## Layout

```
.claude-plugin/plugin.json     manifest
README.md                      this file
tier1/                         canonical Tier 1 build pack
  00-pack-contract.md          handoff contract (read this for the rules of engagement)
  01-navigate.md               first router into kdcube docs
  02-test.md                   working-environment preflight + test contract
  03-assemble.md               SDK building blocks
  04-write.md                  bundle skeleton + decorators
  05-runtime-config.md         bundle/user props + secrets ownership
  06-configure-and-run.md      descriptor staging, kdcube CLI
  07-release-content.md        optional, only after user-approved release
  08-agent-integration.md      conditional, when bundle ships React/MCP/Claude Code
  09-local-public-ngrok.md     conditional, local public HTTPS for sites/callbacks
  10-widget-integration.md     conditional, widget/generated HTML API origin contract
skills/
  bundle-builder/SKILL.md      the unified planning skill (always-loaded)
  ref-resolver/SKILL.md        repo:foo/path → /abs/local/path
  kdcube-docs/SKILL.md         read KDCube docs + source from the local repo
agents/
  doc-reader.md                delegation sub-agent for digesting long docs
commands/
  init.md                      one-time operator setup validation
  runtime-init.md              kdcube CLI init + runtime secrets bootstrap
  bundle-configure.md          register bundle source/config/secrets in runtime
  bundle-maintain.md           maintain an existing bundle repo end-to-end
  bundle-new.md                new modular async app from the canonical package contract
  bundle-test.md               run the test contract with venv preflight
  bundle-release.md            content-release procedure (user-approved only)
  knowledge-refresh.md         re-pull tier-1 from the local KDCube checkout
config/
  repos.yaml.template          symbolic ref → local checkout
  audiences.yaml.template      mirror of the kdcube audience registry
templates/
  bundle-AGENTS.md             per-bundle memory anchor (drop into a bundle root)
hooks/
  hooks.json                   SessionStart: surface tier-1 entry point + repos.yaml status
bin/
  refresh-tier1.sh             re-copy tier-1 docs from the KDCube checkout
```

## Scope boundary

The plugin is for **building KDCube apps and operating KDCube deployments**.
It is not for maintaining the KDCube platform source itself.

The plugin reads the local `kdcube` repo as ground truth; it does
not edit that repo as part of bundle work.

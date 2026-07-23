# kdcube

A Claude Code plugin that turns Claude into an actionable KDCube app
builder: initialize a local runtime, register and configure bundles,
maintain bundle repos, test them, and release them only after explicit
operator approval. It is informed by the canonical Tier 1 build pack
and reads KDCube ground truth straight from a local `kdcube-ai-app`
checkout (docs + source) via the `kdcube-docs` skill and its index,
cloning the repo on onboarding when it is missing.

This plugin is the canonical Build-with-KDCube kdcube package for Claude
Code. It carries the runnable instructions, commands, skills, templates, and
Tier 1 handoff docs that a user's Claude Code session can actually load.

## Orientation Card

KDCube is a backend-plus-frontend application framework for AI bundles:
chat and agent runtimes, APIs, widgets/main UI, tools, scheduled and
background jobs, storage, integrations, configuration descriptors, local CLI
workflows, and content release.

When a task smells like "build an AI app", "serve a UI/API", "wire a tool",
"run a job", "integrate a channel", "store per-user or per-bundle state", or
"ship the bundle to a runtime", the agent should check KDCube first instead of
inventing its own backend/frontend serving, queue, configuration, storage, or
release mechanics. The `kdcube-docs` skill points the agent at the matching
ground truth in the local `kdcube-ai-app` repo.

## What it gives you

- **One planning agent** that combines the bundle-author task facets
  (creator, integrator, configurator, deployer, local QA, integration
  QA, doc reader) per the official handoff contract.
- **Tier 1 pack** bundled at `tier1/` — the agent reads these
  as its baseline knowledge of how to build/configure/test/release a
  KDCube bundle.
- **Local KDCube docs + source** — the `kdcube-docs` skill reads KDCube
  ground truth straight from a local `kdcube-ai-app` checkout (docs +
  source) through a topic→path index. There is no retrieval service;
  onboarding clones the repo if it is missing.
- **Symbolic-ref resolver** that turns `repo:kdcube-ai-app/...` refs into
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

KDCube knowledge is the local `kdcube-ai-app` repo — its docs and its source.
There is no retrieval service. The `kdcube-docs` skill carries a topic→path
index into the repo: the agent resolves each `repo:kdcube-ai-app/<path>` ref
through the ref-resolver (`config/repos.yaml`) and `Read`s it, or `rg`/`find`s
the repo for anything not indexed. The `tier1/` pack is a local snapshot of the
build docs; when it and the repo disagree, the repo wins.

If the repo is not resolvable, `/kdcube:init` locates a
CLI-installed checkout or clones `https://github.com/kdcube/kdcube-ai-app.git`
and records the path in `config/repos.yaml`.

## One-time setup (operator)

The minimum setup is:

1. Install or locate `kdcube-cli`.
2. Run `/kdcube:init` to resolve (or clone) the local
   `kdcube-ai-app` checkout and record it in `config/repos.yaml`. Copy
   `config/repos.yaml.template` to `config/repos.yaml` first if you want to set
   the checkout path by hand.
3. Run `/kdcube:runtime-init` when a live runtime is needed.
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
  09-local-public-ngrok.md     conditional, local public HTTPS for webhooks/callbacks
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
  knowledge-refresh.md         re-pull tier-1 from upstream kdcube-ai-app
config/
  repos.yaml.template          symbolic ref → local checkout
  audiences.yaml.template      mirror of the kdcube audience registry
templates/
  bundle-AGENTS.md             per-bundle memory anchor (drop into a bundle root)
hooks/
  hooks.json                   SessionStart: surface tier-1 entry point + repos.yaml status
bin/
  refresh-tier1.sh             re-copy the tier-1 docs from kdcube-ai-app
```

## Scope boundary

The plugin is for **building and operating bundles**. It is not for
maintaining the KDCube platform itself.

The plugin reads the local `kdcube-ai-app` repo as ground truth; it does
not edit that repo as part of bundle work.

# Changelog

All notable changes to this marketplace and its plugins are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-05-18

### Added
- `kdcube-docs:kdcube-planner` sub-agent
  (`plugins/kdcube-docs/agents/kdcube-planner.md`). Whitelists the
  kdcube-dev MCP tools plus Read/Glob/Grep/TodoWrite/WebFetch and
  enforces a mandatory docs-first planning workflow. Solves the
  problem that generic planning agents (`Plan`,
  `feature-dev:code-architect`) either don't have the MCP tools or
  don't know to use them, and silently fall back to training memory
  on KDCube specifics.

### Changed
- SessionStart hook expanded to (1) trigger on problem statements
  KDCube solves — per-user budget / cost accounting, isolation of
  generated code, multi-tenant runtime, interactive AI apps mixing
  multiple surfaces, wrapping existing scripts as AI products —
  not just on explicit KDCube terminology, and (2) route planning
  work to the new `kdcube-docs:kdcube-planner` sub-agent. Fragment
  grew from ~133 to ~360 tokens; the larger budget is what bought
  the broader trigger coverage and the agent-routing instruction.
- `kdcube-docs:kdcube` workflow skill's bundle-authoring path now
  references the kdcube-planner sub-agent for multi-step planning
  work.

## [0.3.0] - 2026-05-18

### Added
- SessionStart hook (`plugins/kdcube-docs/hooks/hooks.json` +
  `plugins/kdcube-docs/hooks-handlers/session-start.sh`) that
  unconditionally injects the kdcube-dev MCP usage contract into the
  session's context. Always-on belt for the model-invoked
  `kdcube-docs:kdcube` workflow skill — guarantees docs-first
  behavior fires even when the skill's trigger description doesn't
  match the user's phrasing. ~150 token tax per session.

## [0.2.0] - 2026-05-17

### Changed
- **Breaking:** Slash commands renamed to drop the redundant
  `kdcube-` prefix inside the `kdcube-docs:` namespace:
  - `/kdcube-docs:kdcube-doc` → `/kdcube-docs:search`
  - `/kdcube-docs:kdcube-scaffold` → `/kdcube-docs:scaffold`
- Naming-convention table in the root README updated to show
  unprefixed skill names as the recommended pattern (the plugin name
  is already the namespace).

## [0.1.0] - 2026-05-17

### Added
- Initial release of the `kdcube` marketplace and the `kdcube-docs`
  plugin.
- `kdcube-dev` HTTP MCP server pointing at the stable docs alias
  `https://kdcube.tech/mcp/docs` (CloudFront 308 redirect to the
  current `kdcube.copilot` bundle). Exposes read-only
  `search_knowledge` and `read_knowledge` tools against the live
  KDCube docs.
- `kdcube` workflow skill that requires Claude to consult the docs
  MCP before answering any KDCube-specific question, with a full
  keyword → `ks:docs/...` map under `references/doc-map.md`.
- `/kdcube-docs:kdcube-scaffold <bundle-name>` slash command for
  generating a new KDCube bundle skeleton.
- `/kdcube-docs:kdcube-doc <question>` slash command for fast,
  citation-backed doc lookup.
- Marketplace manifest under `.claude-plugin/marketplace.json`
  (relative-string source so the same manifest works for both
  `file://` and GitHub installs).
- Naming convention documented in the root README: kebab-case with a
  `kdcube-` prefix for any future per-capability plugin
  (`kdcube-runtime`, `kdcube-bundles`, …).

## 2026-07-23 — repository refocus

- The repository becomes the home for KDCube agent tooling across ecosystems;
  Claude Code plugins live under `plugins/claude/`.
- `kdcube` v0.4.0 joins as the primary plugin: runtime init,
  bundle scaffold/configure/test/release commands, operator + builder skills,
  doc-reader subagent, offline Tier 1 docs pack, and awareness of the hosted
  docs MCP at https://kdcube.tech/mcp/docs.
- `kdcube-docs` (the early companion attempt) is removed; its docs-first idea
  continues inside `kdcube`'s knowledge skills.

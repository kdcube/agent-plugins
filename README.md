# KDCube Agent Plugins

Official plugins and packs that teach coding agents to work with
[KDCube](https://kdcube.tech) — the self-hosted platform and SDK for packaging
AI applications into deployable bundles.

This repository is the home for KDCube tooling across agent ecosystems. Claude
Code plugins live here today; packs for other agents (Codex, Gemini CLI, and
similar) share the same knowledge sources and join the same tree as they are
built.

## Why these plugins exist

KDCube's decorator names, descriptor keys, CLI flags, and runtime paths evolve
between releases. An agent answering KDCube questions from training-time memory
will teach you to hallucinate. These plugins ground the agent in current
knowledge instead: a vendored Tier 1 documentation pack for offline work, the
`kdcube-ai-app` checkout as the source of truth once onboarded, and the hosted
documentation MCP at `https://kdcube.tech/mcp/docs` as a live surface.

## Claude Code

Add the marketplace, then install:

```
/plugin marketplace add https://github.com/kdcube/agent-plugins
/plugin install kdcube@kdcube
```

| Plugin | What it ships |
| --- | --- |
| [`kdcube`](plugins/claude/kdcube/README.md) | The full build-and-operate toolkit: runtime bootstrap (`/runtime-init`), bundle scaffolding, configuration, testing, and release commands; operator and builder skills; a doc-reader subagent; and the offline Tier 1 docs pack. |

After install, run `/kdcube:init` to onboard the KDCube repo and
verify the docs pack, then start with `/kdcube:runtime-init` for a
fresh runtime or `/kdcube:bundle-new` for a new app.

## Repository layout

```text
.claude-plugin/marketplace.json   Claude Code marketplace manifest
plugins/
  claude/                         Claude Code plugins
    kdcube/
```

Per-agent packs added later follow the same pattern (`plugins/codex/…`,
`plugins/gemini/…`), sourcing their knowledge from the same upstream docs the
Tier 1 refresh scripts read.

## Naming convention

Two rules, learned deliberately:

1. **Plugin names must be brand-distinctive, never generic.** In Claude Code
   the everyday command namespace is the bare plugin name
   (`/kdcube:<command>`); the `@marketplace` suffix appears only at install
   time. A generic name (`app-builder`, `docs`, `builder`) would collide with
   any other vendor's plugin of the same name and claim vocabulary every
   vendor has equal right to.
2. **One canonical name per plugin across every agent surface.** The same
   name is the Claude plugin name, the Codex artifact prefix, and the Gemini
   extension name, so invocations rhyme across agents and a user who learns
   one surface knows them all.

```text
canonical name   kdcube                            same on every surface
Claude Code      install kdcube@kdcube             /kdcube:<command>
Codex            prompt files kdcube-<command>.md  /kdcube-<command>
Gemini CLI       extension "kdcube"
directory        plugins/<agent>/kdcube/
```

`kdcube` is the single flagship plugin; if the toolkit ever splits, siblings
keep the brand prefix (`kdcube-<capability>`).

## License

MIT — see [LICENSE](LICENSE).

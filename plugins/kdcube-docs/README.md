# KDCube Plugin

Build [KDCube](https://kdcube.tech) bundles with Claude — grounded in the live KDCube documentation, not training memory.

## What this plugin does

KDCube is a self-hosted platform and SDK for packaging AI applications into deployable **bundles**: one folder mixing backend, frontend, APIs, MCP surfaces, cron jobs, RBAC, streaming, and isolated runtime. Decorator names, descriptor keys, and CLI flags evolve between releases, so any plugin that helped you build bundles from training-time memory would teach you to hallucinate.

This plugin solves that by shipping:

1. A documentation **MCP server** (`kdcube-dev`) pointed at the live KDCube docs.
2. A **workflow skill** (`kdcube`) that requires Claude to consult the MCP before answering any KDCube question.
3. Two **slash commands** that automate the most common entry points.

## What gets installed

- **MCP server `kdcube-dev`** — remote HTTP MCP with two read-only tools:
  - `search_knowledge(query, keywords?, root?, top_k?)` — ranked `ks:docs/...` paths
  - `read_knowledge(path)` — full document at an exact path
- **Skill `kdcube`** — model-invoked. Triggers on KDCube concepts, `entrypoint.py` with platform decorators, and `kdcube.copilot@*` / `*.bundle@*` paths. Walks Claude through Q&A, bundle authoring, configuration, and runtime debugging.
- **Slash command `/kdcube-docs:scaffold <bundle-name>`** — interactively generates a new bundle skeleton with the right shape for the surfaces you need.
- **Slash command `/kdcube-docs:search <question>`** — fast, citation-backed doc lookup.
- **SessionStart hook** — always-on belt. Injects ~150 tokens of MCP usage contract at session start so docs-first behavior fires even when the workflow skill's auto-trigger doesn't match the user's phrasing.

## First-run check

After installing, confirm the MCP is reachable. From a new chat:

> "What's in `ks:docs/quick-start-README.md`?"

Claude should call `kdcube-dev:read_knowledge` and return the live quick-start. If it returns "I don't have access to that file" or invents content, the MCP is not wired correctly — open an issue.

## Usage examples

1. **Build a new bundle.**
   > "I want to scaffold a KDCube bundle that exposes a public webhook and a cron job."

   Triggers `/kdcube-docs:scaffold` or the workflow skill; both pull the live decorator docs before generating code.

2. **Wrap existing code.**
   > "I have a Python script that pulls CSVs from S3 and emails reports. How do I wrap it as a KDCube bundle?"

   Triggers the `kdcube` workflow skill's wrapping-existing-code path; Claude reads `how-to-write-bundle-README.md` and proposes the adapter shape.

3. **Configuration question.**
   > "/kdcube-docs:search where do I put bundle secrets?"

   Returns a quoted answer with `ks:docs/configuration/bundles-secrets-descriptor-README.md` citations.

## About the MCP endpoint

This release (v0.1.0) points `kdcube-dev` at the stable alias:

```
https://kdcube.tech/mcp/docs
```

That path is a CloudFront 308 redirect to the current production `kdcube.copilot` bundle URL on `dev.kdcube.tech`. The redirect lets the plugin pin a short, memorable URL that survives bundle revision upgrades — when the copilot bundle is rolled, only the redirect changes and the plugin needs no new release.

The MCP server is public and read-only. No credentials, no rate-limit auth.

## Updating

```
/plugin marketplace update kdcube
```

Or, if you installed from a local file:

```
/plugin marketplace update kdcube
```

(both forms refresh the local cache).

## Reporting issues

[github.com/kdcube/claude-plugins/issues](https://github.com/kdcube/claude-plugins/issues)

## License

MIT — see [LICENSE](../../LICENSE).

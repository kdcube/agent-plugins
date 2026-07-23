---
name: ref-resolver
description: "Resolve symbolic repo:<name>/<path-inside-repo> references (from the kdcube-docs index, tier1 docs, the user's message, or any tool result) into absolute local paths the agent can Read or grep. Activate whenever a repo: ref appears in a tool result, a doc, or the user's message."
---

# Symbolic-Ref Resolver

The kdcube-docs index, the tier-1 docs, and many KDCube docs reference
source material with symbolic refs of the form:

```
repo:<repo-name>/<path/within/repo>
```

These refs are deliberately portable — they don't bake in any
particular operator's checkout layout. The plugin resolves them via
`config/repos.yaml`.

## How to resolve

1. Read `${CLAUDE_PLUGIN_ROOT}/config/repos.yaml` once per session
   and cache the result in working memory.
2. Given `repo:<name>/<path>`:
   - Look up `<name>` in `repos:`. If missing, **stop**: this is a
     misconfig, not an opportunity to guess. Tell the operator to add
     `<name>` to `config/repos.yaml`.
   - Take `local_path` from the entry, join with `<path>`. The result
     is the absolute path the agent should `Read` or pass to `Bash`
     (`grep`, `find`, etc.).
3. If the file does not exist at the resolved path, **stop**: the
   operator's `local_path` is stale, the path-within-repo is wrong,
   or the doc has moved. Surface the failure verbatim.

## Examples

```
repo:kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-write-bundle-README.md
  → /Users/<op>/src/kdcube/kdcube-ai-app/app/ai-app/docs/sdk/bundle/build/how-to-write-bundle-README.md

repo:my-bundles/src/my.bundle@1-0/entrypoint.py
  → /Users/<op>/src/your-org/your-bundles/src/my.bundle@1-0/entrypoint.py
```

## When to resolve eagerly

Resolve eagerly (without asking) whenever:

- the kdcube-docs index or a doc surfaces a `repo:` ref;
- a tier-1 doc links sibling docs by relative path — convert those
  to absolute paths via `repo:kdcube-ai-app/...`;
- the user pastes a `repo:` ref.

## When the resolver is the wrong move

- For external (non-`repo:`) URLs (HTTPS, ngrok URLs, third-party
  docs), use `WebFetch` if explicitly requested by the operator.

## Failure mode (do not work around it)

If `config/repos.yaml` does not exist or `<name>` is not in it:

> Symbolic ref `repo:<name>/...` cannot be resolved because
> `<plugin-root>/config/repos.yaml` does not contain an entry for
> `<name>`. Add an entry mapping `<name>` to your local checkout
> path, then retry. (See `repos.yaml.template` for shape.)

Failing loud beats silently grepping the wrong tree.

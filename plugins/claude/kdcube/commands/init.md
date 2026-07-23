---
description: "Onboard the kdcube plugin: pin the CLI-managed runtime repo (<workdir>/repo via kdcube info) it reads KDCube knowledge from — or bootstrap a runtime if there is none; a hand-set repos.yaml path is the developer override. Verify the index resolves, and report what is wired vs missing. No knowledge service — the repo is the source of truth."
---

# /kdcube:init

Deterministic preflight. The plugin reads KDCube ground truth from a **local
checkout of `kdcube-ai-app`** (docs + source), so the one thing onboarding must
guarantee is that the repo is present and resolvable. Report OK/FAIL per check;
do not auto-fix beyond cloning the repo (with consent) — surface the diff and let
the operator act.

Steps:

1. **Locate the KDCube repo.** In order of preference:
   - Read `${CLAUDE_PLUGIN_ROOT}/config/repos.yaml`. If `local_path` is set and
     valid (git repo containing `app/ai-app/docs/README.md`), use it — the
     developer override. Done.
   - Otherwise the CLI-managed runtime repo: get the workdir from `kdcube info`
     and use `<workdir>/repo` (`~/.kdcube/kdcube-runtime/<tenant>__<project>/repo`)
     — a full checkout with docs that matches the running platform. Write it into
     `config/repos.yaml`.
   - If there is no runtime yet, create one: run `/kdcube:runtime-init`
     (ensure the CLI, then `kdcube init --upstream` / `--latest` / `--release <ver>`
     clones the chosen source into `<workdir>/repo`), then pin `config/repos.yaml`
     to `<workdir>/repo`.

   Do not **silently** pin a `kdcube-ai-app` checkout you happened to find on disk
   — its version is unknown and may not match the runtime. If you do know of a
   local checkout (e.g. a developer's own), surface it and let the operator choose
   it as the override rather than writing it in unprompted. Do not answer KDCube
   questions from memory while the repo is unavailable — onboarding is the fix.

2. **Bundle/content repo (optional).** If the operator has added their own
   bundle repo to `config/repos.yaml` (any entry besides `kdcube-ai-app`),
   verify its `local_path` similarly — that's where the bundles they build live.
   Missing is fine for pure read tasks; needed when building/maintaining a local
   app.

3. **Index resolves.** Spot-check that a few `kdcube-docs` index targets exist
   under the resolved repo, e.g. `app/ai-app/docs/README.md`,
   `app/ai-app/docs/sdk/bundle/build/how-to-write-bundle-README.md`,
   `app/ai-app/docs/recipes/operations/operate-runtime-README.md`,
   `app/ai-app/src/kdcube-ai-app/kdcube_cli/src/kdcube_cli/cli.py`. If any are
   missing, the checkout may be stale or shallow — tell the operator to pull.

4. **Tier 1 pack freshness.** Run
   `${CLAUDE_PLUGIN_ROOT}/bin/check-tier1-freshness.sh`. It compares each pack
   file's own `id:`/`updated_at` frontmatter and content against the checkout —
   never mtime. Do not hand-roll a comparison. Follow the action it prints: if it
   says to sync, run `${CLAUDE_PLUGIN_ROOT}/bin/refresh-tier1.sh` and report which
   files moved; if it warns the pack is ahead of the checkout, do not auto-refresh
   — read from the checkout and tell the operator. Silent output means fresh.

5. **Next action.** First resolve any unresolved preflight state — a **missing
   index target** (checkout stale/incomplete), or a tier1 **AHEAD / divergence**
   the freshness step did not auto-resolve. While either stands, the next action
   IS resolving it (pull the platform forward, or align the pack down); do NOT
   present the build commands as "unblocked" — the pack and checkout disagree, so
   building would target a platform you may not be running.
   Only once the repo resolves AND the pack is reconciled (fresh, or a clean
   behind→refresh), point the operator at:
   - `/kdcube:runtime-init` — bootstrap a local KDCube runtime, or
     finish the auth type configuration of one that was bootstrapped here only
     to resolve the repo (it knows what to ask the operator for);
   - `/kdcube:bundle-configure` — register/configure an app;
   - `/kdcube:bundle-new` — scaffold a new app.
   For any KDCube concept (auth, surfaces, dataflows, CLI, descriptors,
   economics), use the **kdcube-docs** skill to read the repo, not memory.

6. **Summary.** Print a compact OK/FAIL table per check.

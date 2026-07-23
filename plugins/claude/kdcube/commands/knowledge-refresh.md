---
description: "Refresh the bundled Tier 1 doc pack from upstream kdcube-ai-app. Re-runs bin/refresh-tier1.sh and reports any drift the agent should be aware of."
---

# /kdcube:knowledge-refresh

Re-pull the canonical Tier 1 pack from upstream so the bundled copies
under `tier1/` track the source-of-truth in `kdcube-ai-app`.

Steps:

1. Resolve `repo:kdcube-ai-app` via the ref-resolver. If the entry is
   missing, stop and tell the operator to populate
   `config/repos.yaml`.

2. Run `${CLAUDE_PLUGIN_ROOT}/bin/refresh-tier1.sh`. The script
   copies the source docs into `tier1/` with the canonical names
   (`00-pack-contract.md`, `01-navigate.md`, ...). Each copy keeps the
   source's `id:`/`updated_at`, so the freshness-check goes quiet until
   the checkout moves ahead again.

3. Diff each refreshed file against the previous version and surface
   notable changes — especially:
   - new entries in the agent guardrail list
     (`tier1/00-pack-contract.md`);
   - reorderings of the reading-order;
   - any doc that moved or was renamed (the contract calls this out
     as a known link-rot risk).

4. Do not auto-update any plugin code, skill instructions, or
   commands based on the diff. Surface the diff and let the operator
   decide whether the plugin's own conventions need to follow.

This command refreshes the plugin's own Tier 1 pack only; the upstream
documentation it copies from is maintained in the `kdcube-ai-app` repo.

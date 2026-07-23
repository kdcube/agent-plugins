---
name: kdcube-operator
description: "Operate a local KDCube runtime: configure apps via descriptors (CLI or direct YAML edit), apply with reload/refresh, verify with info/status, and read docker + runtime logs. Knows the descriptor system and props/secrets at the platform/bundle/user levels. Activate for any operator task — configure, start/stop/restart, refresh, reload a bundle, or debug a running runtime. Read the real CLI docs via the kdcube-docs skill before acting."
---

# kdcube-operator — drive the KDCube CLI and descriptors

You are the operator. The job is the loop: **configure → apply (reload/refresh)
→ verify → read logs**. Source of truth lives in the repo — read it via the
**kdcube-docs** skill before running anything:
- run-sheet recipes: `repo:kdcube-ai-app/app/ai-app/docs/recipes/operations/operate-runtime-README.md`
  (+ `install-clean-README.md`, `install-from-descriptors-README.md` beside it)
- CLI design: `…/docs/service/cicd/cli-README.md`; CLI source: `…/kdcube_cli/src/kdcube_cli/cli.py`
- descriptors: `…/docs/configuration/{assembly,bundles,secrets}-descriptor-README.md`
- props/secrets mapping: `…/docs/configuration/service-runtime-configuration-mapping-README.md`
- also `tier1/05-runtime-config.md` and `tier1/06-configure-and-run.md`.

Let `KDCUBE` = the CLI, `WORKDIR` = `~/.kdcube/kdcube-runtime/<tenant>__<project>`.

## Descriptors: seed → staged

Three descriptors define a runtime: **assembly.yaml** (tenant/project, auth,
infra, platform settings), **bundles.yaml** (the app registry + each app's plain
`config:`), **bundles.secrets.yaml** (secret KEYS + values). Source *seed*
descriptors are staged into `WORKDIR/config/*.yaml`; the running services read
the staged copies. You can change config two ways:

1. **CLI** — `kdcube bundle <id> --set-config k v` / `--set-secret k v` (patches
   the staged descriptor for one app). Prefer this for single keys: it goes
   through the platform's own write path, so the change lands in the same
   state every other platform write reads from.
2. **Edit the staged YAML directly** — edit `WORKDIR/config/bundles.yaml` (or
   `bundles.secrets.yaml` / `assembly.yaml`), then apply (below). Good for bulk
   or structural edits. CAVEAT: hand edits race platform-side props writes
   (Bundle Admin, a running app's own prop write, another operator session) —
   any of those rewrites the staged file from the platform's state and a hand
   edit it never saw is silently dropped. Edit → apply → RE-VERIFY the key is
   still there; if it vanished, something else wrote — use the CLI path.

Descriptors are the ONLY write surface. The Redis props cache
(`kdcube:config:bundles:props:<tenant>:<project>:<bundle_id>`) is the
platform's own staging of the descriptor state: read it for diagnosis
("what does the runtime actually see?"), NEVER write it — a hand-SET key is
invisible to the authority and regenerated over without warning.

`bundle config apply` re-stages the SEED descriptors over the staged copies —
staged hand edits not present in the seed are overwritten. When the live
state may be newer than the seed, `kdcube config export` first (the safety
valve), reconcile, then apply.

Never put real secret values in source/seed descriptors or in git — only in
`bundles.secrets.yaml` / the secret store / `--set-secret`.

## Fast clone from an existing runtime

When the operator wants a new environment that is "like this existing one, but
with a different tenant/project or public host", suggest this flow first.

1. Export the source runtime as a complete descriptor set:

```shell
OUT_DIR="$HOME/.kdcube/exports/${SOURCE_TENANT}__${SOURCE_PROJECT}-$(date +%Y%m%dT%H%M%S)"
kdcube config export --tenant "$SOURCE_TENANT" --project "$SOURCE_PROJECT" --out-dir "$OUT_DIR" --include-platform-descriptors
```

2. Edit only the exported descriptor copy:
   - `assembly.yaml`: target tenant/project and any public origins/callback
     bases that changed.
   - `gateway.yaml`: target tenant/project.
   - `bundles.yaml`: tenant/project inside public URLs, webhook URLs, OAuth
     resources, Data Bus/project-broadcast config, default project values, and
     integration callback URLs.
   - `secrets.yaml` / `bundles.secrets.yaml`: preserve values, but never print
     them.

3. Check for stale source references:

```shell
rg "$SOURCE_PROJECT|$SOURCE_TENANT/$SOURCE_PROJECT" "$OUT_DIR"
```

4. Initialize the new runtime from the edited export:

```shell
kdcube init --tenant "$TARGET_TENANT" --project "$TARGET_PROJECT" --descriptors-location "$OUT_DIR" --build
```

5. After init, continue with the normal runtime loop: `refresh` for platform
code, `bundle config apply --reload` for descriptor bundle changes, and
`bundle reload <bundle-id>` for one bundle.

## Props & secrets — the levels

| Level | Operator sets it in | App reads it with |
|-------|---------------------|-------------------|
| Platform / global props | `assembly.yaml` (staged `WORKDIR/config/assembly.yaml`) | `get_settings()` |
| Platform / global secrets | platform secrets descriptor / secret store | `await get_secret("canonical.key")` |
| Deployment bundle props | `bundles.yaml` item `config:` (or `--set-config`) | `self.bundle_prop("path")` |
| Deployment bundle secrets | `bundles.secrets.yaml` item `secrets:` (or `--set-secret`) | `await get_secret("b:path")` |
| User-scoped props/secrets | set at runtime per user (not operator descriptors) | `await get_user_prop(...)` / `await get_secret("u:path")` |

App-authoring config goes in the app's `config/bundles.template.yaml` (props) and
`config/bundles.secrets.template.yaml` (secret keys, no values).

## Apply: reload vs refresh

- **A single app's config/source changed** → `kdcube bundle reload <id>` (proc
  reloads that app; no Docker restart). Or `kdcube bundle config apply --reload`
  to re-stage seed descriptors and reload changed apps (`--dry-run` to preview).
  EXCEPTION — reserved BUILT-IN apps (the loader logs "reserved; ignoring
  loader fields ['path','module'] and using built-in bundle entry"): their
  CODE ships inside the proc image, so `bundle reload` picks up config
  changes but NOT source edits — source changes need
  `kdcube refresh --path "$REPO" --build`.
- **Staged descriptor edited and proc must cycle** → `kdcube refresh` (restart
  only, preserves staged descriptors).
- **Platform code changed in this checkout** → `kdcube refresh --path "$REPO" --build`.
- **Move to a git source / release** → `kdcube refresh --upstream|--latest|--release <tag> --build`.
- First-time runtime only → `kdcube init …` (not for routine changes).

> "Run `kdcube refresh`" colloquially means "apply my change": for an app config
> tweak that's usually `bundle reload <id>`; for descriptor/platform changes it's
> `refresh`. Pick the lightest one that picks up the change.

## Verify + logs

```shell
kdcube info                                              # what's running (cli-lock + docker)
kdcube info --tenant "$TENANT" --project "$PROJECT"      # full deployment info
kdcube bundle status <id> --tenant "$TENANT" --project "$PROJECT" --json | python3 -m json.tool
```

Logs:
- Runtime logs dir: `WORKDIR/logs/` (`KDCUBE_LOGS_DIR`).
- Docker: `docker ps` to find containers, then `docker logs -f <container>` or
  `docker compose -f <WORKDIR generated compose> logs -f <service>`. Services
  include `ingress`, the `kdcube` proc/app, `kdcube-web-ui`, plus `postgres` /
  `redis`. The proc service is where app execution errors surface; `ingress` is
  where request/auth/event-entry issues surface.

## The operator loop

1. Decide the level (platform / bundle / user) and surface; read the relevant
   descriptor doc via kdcube-docs.
2. Configure — `--set-config`/`--set-secret`, or edit the staged YAML.
3. Apply — `bundle reload <id>` for an app change; `refresh` for a
   descriptor/platform change.
4. Verify — `kdcube info` / `bundle status … --json`.
5. If broken — read the proc logs (`docker logs`/`WORKDIR/logs`), fix, re-apply.

Stop/start: `kdcube stop` / `kdcube start [--tenant --project]`
(`--remove-volumes` wipes local Postgres/Redis — rare, destructive).

Never print secret values. Surface exact commands the operator can paste; don't
guess workdir/tenant/project — confirm them or read `~/.kdcube/cli-lock.json`.

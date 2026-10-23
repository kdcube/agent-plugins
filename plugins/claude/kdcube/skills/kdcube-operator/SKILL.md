---
name: kdcube-operator
description: "Operate a local KDCube runtime: configure apps via descriptors (CLI or direct YAML edit), apply with reload/refresh, verify with info/status, and read docker + runtime logs. Knows the descriptor system and props/secrets at the platform/bundle/user levels, and how a super-admin sets one secret with the Connection Hub CLI (`connection-hub secrets host set`, consent page, troubleshooting). Activate for any operator task — configure, start/stop/restart, refresh, reload a bundle, or debug a running runtime. Read the real CLI docs via the kdcube-docs skill before acting."
---

# kdcube-operator — drive the KDCube CLI and descriptors

You are the operator. The job is the loop: **configure → apply (reload/refresh)
→ verify → read logs**. Source of truth lives in the repo — read it via the
**kdcube-docs** skill before running anything:
- run-sheet recipes: `repo:kdcube/app/ai-app/docs/recipes/operations/operate-runtime-README.md`
  (+ `install-clean-README.md`, `install-from-descriptors-README.md` beside it)
- CLI design: `…/docs/service/cicd/cli-README.md`; CLI source: `…/kdcube_cli/src/kdcube_cli/cli.py`
- descriptors: `…/docs/configuration/{assembly,bundles,secrets}-descriptor-README.md`
- props/secrets mapping: `…/docs/configuration/service-runtime-configuration-mapping-README.md`
- also `tier1/05-runtime-config.md` and `tier1/06-configure-and-run.md`.

Let `KDCUBE` = the CLI, `WORKDIR` = `~/.kdcube/kdcube-runtime/<tenant>__<project>`.

## Descriptors: seed → staged

The core descriptor set has six files: **assembly.yaml** (tenant/project,
auth, infrastructure, platform settings), **gateway.yaml**, **economics.yaml**,
**bundles.yaml** (the app registry + each app's plain `config:`),
**secrets.yaml** (platform and user secret scopes), and
**bundles.secrets.yaml** (deployment-bundle and user-bundle secret scopes).
Source *seed* descriptors are staged into `WORKDIR/config/*.yaml`; the running
services read the staged copies. You can change config two ways:

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

Plain descriptors are the configuration write surface. The Redis props cache
(`kdcube:config:bundles:props:<tenant>:<project>:<bundle_id>`) is the
platform's own staging of the descriptor state: read it for diagnosis
("what does the runtime actually see?"), NEVER write it — a hand-SET key is
invisible to the authority and regenerated over without warning.

`bundle config apply` re-stages the SEED descriptors over the staged copies —
staged hand edits not present in the seed are overwritten. When the live
state may be newer than the seed, `kdcube config export` first (the safety
valve), reconcile, then apply.

Never put real secret values in source/seed descriptors or in git. The selected
secret provider is the live authority: descriptor files in `secrets-file`
mode, host-vault after verified local activation, or the configured cloud
provider.

## Local host-vault activation

The optional local host vault is a backend of the existing secret-manager
contract. Provision its host service and enroll this deployment first. During
shadow staging, keep the file provider active and configure these non-secret
fields in `WORKDIR/config/assembly.yaml`:

```yaml
secrets:
  provider: secrets-file
  service:
    backend: host-vault
    host_vault:
      address: host.docker.internal:7781
      server_name: host.docker.internal
      identity_dir: /absolute/service-owned/path/outside-the-workdir

platform:
  services:
    proc:
      exec:
        py_code_exec_network_mode: auto
```

Then use the transactional CLI path:

```shell
kdcube secrets backend host-vault prepare --tenant "$TENANT" --project "$PROJECT" --dry-run
kdcube secrets backend host-vault prepare --tenant "$TENANT" --project "$PROJECT"
kdcube secrets backend host-vault stage --tenant "$TENANT" --project "$PROJECT" --dry-run
kdcube secrets backend host-vault stage --tenant "$TENANT" --project "$PROJECT"
kdcube secrets backend host-vault activate --tenant "$TENANT" --project "$PROJECT" --dry-run
kdcube secrets backend host-vault activate --tenant "$TENANT" --project "$PROJECT" --yes
```

Activation changes the provider to `secrets-service`, recreates affected
consumers, verifies real reads, and retains the owner-only files for rollback.
The activation command is the provider-switch boundary because it performs
parity, ordering, live-read verification, and rollback. If a pending activation
marker blocks startup, run `kdcube secrets backend host-vault recover --tenant "$TENANT"
--project "$PROJECT" --yes`. Confirm `kdcube secrets backend host-vault --help`
exists; until that command ships in a published CLI, use a source-installed CLI
matching the staged KDCube source. Read
`repo:kdcube/app/ai-app/docs/service/secrets/host-vault-README.md` before
provisioning or activation.

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
kdcube init --non-interactive \
  --tenant "$TARGET_TENANT" \
  --project "$TARGET_PROJECT" \
  --descriptors-location "$OUT_DIR" \
  --build
```

5. After init, continue with the normal runtime loop: `refresh` for platform
code, `bundle config apply --reload` for descriptor bundle changes, and
`bundle reload <bundle-id>` for one bundle.

## Props & secrets — the levels

| Level | Operator sets it in | App reads it with |
|-------|---------------------|-------------------|
| Platform / global props | `assembly.yaml` (staged `WORKDIR/config/assembly.yaml`) | `get_settings()` |
| Platform / global secrets | platform secrets descriptor / secret store | `await get_secret("platform.canonical.key")` |
| Deployment bundle props | `bundles.yaml` item `config:` (or `--set-config`) | `self.bundle_prop("path")` |
| Deployment bundle secrets | `bundles.secrets.yaml` item `secrets:` (or `--set-secret`) | `await get_secret("b:path")` |
| User-scoped props/secrets | set at runtime per user (not operator descriptors) | `await get_user_prop(...)` / `await get_secret("u:path")` |

App-authoring config goes in the app's `config/bundles.template.yaml` (props) and
`config/bundles.secrets.template.yaml` (secret keys, no values).

To set, inspect, read or delete one exact provider-backed secret, use the
Connection Hub CLI: **Set a secret with the Connection Hub CLI (super-admin)**
below is the default path. `connection-hub host authorize` keeps the
Card-bound session in the machine's native credential store, so no bearer is
ever copied to the operator or an agent. Do not ask the person for a bearer
for this task.

Every secret operation is delegated: Connection Hub checks the caller's live
Card and its `Once` or `Every time` (`always`) invocation policy on every
call. The authority covers the exact granted API resources and operations.
Host login, Docker control, and provider workload identity remain separate
authorities.

Advanced/protocol reference only: the plain `kdcube secrets
metadata|set|get|delete <key> --scope platform` commands (bundle targets add
`--scope bundle --bundle-id <bundle-id>`) speak the same protocol but read a
delegated bearer from a hidden prompt or the first stdin line. That bearer
step belongs only to this direct-command path, for automation that already
holds its own Card-bound credential; it is not how a person sets a secret.

### Set a secret with the Connection Hub CLI (super-admin)

The step-by-step page is
`repo:kdcube/app/ai-app/docs/service/secrets/manage-a-secret-with-connection-hub-cli-README.md`
("KDCube Admin: Manage A Secret With The Connection Hub CLI"). Read it before
walking a person through this; the short form:

- **Who.** Only a KDCube super-admin (platform administrator) can approve.
  The secret resource is admin-only: the consent page and the Card editor
  offer it to nobody else.
- **Before.** The deployment's public HTTPS address (never `localhost` or a
  workdir); the Connection Hub descriptor's `kdcube-management` service under
  `connections.delegated_credentials.admission.services` lists
  `urn:kdcube:management:secret:*:*:*:*:*` (the template default); a platform
  at 2026.10.23.1100 or later with a Connection Hub that has the one-secret
  consent fixes; `uv`.

**Published package** (`connection-hub-cli` 2026.10.23.1100 or later on
PyPI; it pulls `kdcube-cli` 2026.10.23.1100 or later, which has the secret
consent):

```shell
uv tool install connection-hub-cli
connection-hub --version
connection-hub setup --endpoint https://<public address>
connection-hub host authorize               # browser login as the super-admin; Card for the deployment only
openssl rand -base64 48 | tr -d '\n' | connection-hub secrets host set <key> \
  --scope bundle --bundle-id <application id> --value-stdin
connection-hub secrets host metadata <key> --scope bundle --bundle-id <application id>
```

**From source** (until that release is on PyPI, or to match a deployment
exactly): run both packages at the App Ecosystem and KDCube revisions the
deployment runs. The secret consent is handled in `kdcube-cli`, and the
`kdcube-cli` on PyPI before 2026.10.23.1100 does not have it.

```shell
CH() { uvx \
  --from "git+https://github.com/elenaviter/app-ecosystem@<app-ecosystem commit>#subdirectory=products/connection-hub/packages/connection-hub-cli" \
  --with "git+https://github.com/kdcube/kdcube@<kdcube commit>#subdirectory=app/ai-app/src/kdcube-ai-app/kdcube_cli" \
  connection-hub "$@"; }
CH --version
CH setup --endpoint https://<public address>
CH host authorize
openssl rand -base64 48 | tr -d '\n' | CH secrets host set <key> \
  --scope bundle --bundle-id <application id> --value-stdin
CH secrets host metadata <key> --scope bundle --bundle-id <application id>
```

A platform secret uses `--scope platform` and a `platform.` key; a user's own
secret uses `--scope user --user-id <user id>` (plus `--bundle-id` for one
application). `get` and `delete` take the same target flags; `get` requires
`--output <new private file>` and never writes the value to the terminal.

**The consent page.** The first use of each secret, and each operation on it
(`set`, `metadata`, `get`, `delete`), answers `resource_not_consented` with a
consent. The page names the agent, the operation (for example
`kdcube.management.secret.value.write`) and the exact secret. The person
chooses **Once** or **Every time**, then presses the button that reads
**Allow `<operation>` once** (or **Allow `<operation>` always**), nothing
else; the CLI then retries the identical request once and prints a receipt
without the value.

A platform admin can instead add an exact secret to the CLI's Card in
advance, in Connection Hub's Card editor (Delegated by KDCube): open the
Card, add the secret with its operations and **Once** or **Every time**, and
save. This works for a Card entered through the deployment door (what
`host authorize` creates) or through one exact secret. The editor adds exact
secrets only: a selector (a `*` scope or key) is refused, and so is a secret
on a Card entered through any other door.

**When you (an agent) run it.** Always pass `--no-open --no-wait`: without a
person at the terminal the CLI would wait at its prompt forever. Give the
person `recovery.authorization_url` from the answer, wait until they say they
pressed Allow, then rerun the same command with the same `--invocation-id`
(the idempotency key; choose it yourself before the first attempt):

```shell
INV=$(uuidgen)
connection-hub secrets host metadata <key> --scope bundle --bundle-id <application id> \
  --invocation-id "$INV" --no-open --no-wait
# answer: resource_not_consented with recovery.authorization_url -> give the URL to the person
# after they pressed Allow:
connection-hub secrets host metadata <key> --scope bundle --bundle-id <application id> \
  --invocation-id "$INV" --no-open --no-wait
```

For `set`, the rerun is the identical request: same flags, same
`--invocation-id`, and the same value on stdin. Use `CH` in place of
`connection-hub` on the source path.
Never put the value on the command line, in output or in a file that reaches
git; pipe it in or let the person type it at the hidden prompt.

| You see | What to do |
| --- | --- |
| `oauth_issuer_mismatch` at `host authorize` | `connection-hub setup --endpoint https://<public address>` (the issuer's address, not `localhost`), authorize again |
| `service_resource_not_registered` | the descriptor lacks the secret resource row: a deployment operator adds `urn:kdcube:management:secret:*:*:*:*:*` to `kdcube-management` and reloads Connection Hub |
| `forbidden` / `delegated credential resource mismatch` | Connection Hub predates the secret consent: update and reload it and rerun, or add the exact secret in the Card editor first |
| `oauth_client_resource_unreachable` saving a secret in the Card editor | the secret is a selector or another deployment's, the Card came through another door, or Connection Hub predates the editor fix: add one exact secret of this deployment to the CLI's Card; on an older Connection Hub use the CLI consent |
| `resource_not_consented` | expected on first use: approve on the consent page, then retry |
| `management_recovery_invalid` | `kdcube-cli` older than 2026.10.23.1100: `uv tool upgrade connection-hub-cli`, rerun |
| `invalid_grant` / `card_resource_not_covered` | the session could not refresh (platform before 2026.10.23.1100, or the Card was revoked): update the platform; meanwhile `connection-hub host authorize` again |
| `delegated_access_unknown_resources` on Allow | Connection Hub predates the exact-secret Card fix: update and reload it, rerun |
| page stays on "Loading this capability" | Connection Hub predates the one-secret consent page fix: update and reload it, rerun to reopen the consent |
| CLI waits forever after printing the consent | no person at the terminal: use `--no-open --no-wait` |

Use the separate owner-performed export ceremony to reconstruct descriptor
artifacts from an exact key manifest:

```shell
kdcube secrets export \
  --platform-key platform.services.brave.api_key \
  --bundle-key app@1-0=provider.api_key \
  --output-directory ./kdcube-secret-export-$(date +%Y%m%dT%H%M%S)
```

Use `--all` instead of exact selectors for a complete administrator export.
It freezes and confirms the current provider inventory, then writes every
platform, deployment-bundle, user, and user-bundle value into the same literal
`secrets.yaml` and `bundles.secrets.yaml` pair. With
`kdcube config export --include-platform-descriptors`, provider-backed runtimes
perform this whole export as part of the ordinary descriptor export.

The selected KDCube identity provider authenticates the administrator in the
browser. One approval and PKCE exchange creates a new `secrets.yaml` /
`bundles.secrets.yaml` directory and leaves delegated Card authority
unchanged. Read
`repo:kdcube-ai-app/app/ai-app/docs/service/secrets/secret-management-cli-README.md`
for the command and stdin contract, and
`repo:kdcube/app/ai-app/docs/service/cicd/delegated-management-service-README.md`
for the server authority model. Keep values in hidden input, private output,
and approved secret stores.

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

---
description: "Initialize a KDCube runtime with kdcube-cli and seed required secrets using kdcube init --set-secret. Never print or persist secret values outside the runtime secrets file."
---

# /kdcube:runtime-init

Initialize or refresh a local KDCube runtime so a bundle can be run and
tested from the CLI.

Required operator inputs before running commands:

- tenant/project for the local runtime namespace;
- descriptors location only when the operator wants to initialize from a
  specific descriptor set;
- runtime workdir only when the operator does not want the CLI default;
- the Google OAuth client id for the default sign-in (it is public; this flow
  has no client secret), and optionally the Google email to grant the first
  admin;
- which secrets are available now. Never ask the operator to paste
  secret values into docs, git files, or logs.

Asking the operator: ask in their words, not the platform's. Keep product
vocabulary out of the question and its options; when a term is unavoidable,
explain it in the same breath instead of assuming it. Say "the app shows its
own Google sign-in page" rather than "application-hosted bundle-session
login"; say "a folder of config files from another runtime" rather than "a
descriptor set". Detail that cannot change the operator's answer — verifier
mechanics, internal component names — does not belong in the question at all.
Always leave a way to answer in their own words: every interactive question
carries a free-text option, never only a closed list of your own suggestions.
Values the operator alone owns — tenant, project, an email, a client id — are
theirs to type; offer an example if it helps, but never replace the free-text
entry with a pick-one of your guesses.

Interactive setup — what to ask, in order:

When there are no pre-supplied flags, coach the bring-up as an ordered
conversation. Do not collapse it into one screen, and do not offer "fill it in
later" in place of a question — deferral can be an answer, never the framing.

Phase 1 (always, first):

- tenant and project — operator-owned free text;
- which sign-in to stand up — application-hosted Google login, simple dev login,
  or Cognito (one-breath explanation each, free-text option kept).

Phase 2 (branches on the Phase 1 choice; one item is asked every time):

- **platform source — always asked**: release (`--latest`), a pinned release
  (`--release <ref>`), github upstream (`--upstream`), or a local checkout
  (`--path <checkout>`) — see *Determine the source* below.
- application-hosted → do you have a Google Web-application OAuth client id? If
  yes, take it. If no, you are obligated to walk them through obtaining one — a
  Google Web-application OAuth client with this runtime's UI origin authorized
  as a JavaScript origin — and wait for the real id before running init. Do not
  offer to proceed with a placeholder client id: a bundle runtime with a
  `<FILL_ME>` client id cannot be signed into. An operator who genuinely wants
  no sign-in yet should pick `simple`, not bundle-with-placeholder. Also ask the
  admin email to bootstrap as super-admin (optional).
- cognito → region and user-pool / app-client ids (CLI §2.3e).
- simple → nothing further; no external identity.

Every scenario, before running init:

- ask whether they also want the optional Telegram companion. If yes, it needs a
  public HTTPS URL that reaches this machine: offer to stand up a tunnel (ngrok,
  cloudflared, or their own domain) as the recommended default — not the only
  way — and if the chosen tool is not installed, offer to install it. The bot
  token is a secret and has **no flag**: the operator exports it as
  `KDCUBE_TELEGRAM_BOT_TOKEN`, never typed inline. The public URL is passed with
  `--enable-telegram --external-https-url "<url>"` (init-only). Tunnel mechanics:
  `tier1/09-local-public-ngrok.md`.
  **Warn: one bot belongs to one runtime.** The Mini App URL embeds
  `tenant/project` in its path, so reusing a bot across runtimes makes Telegram
  open a stale tenant's URL and the proc answers `403` ("requested tenant is not
  served by this proc"). Use a dedicated bot per runtime; when switching, the
  operator must re-point BotFather's menu button / Main Mini App at the new URL
  and reopen the Mini App fresh (old inline buttons stay hard-wired).
- collect which other secrets are available now (provider API keys, etc.);
- state the secrets procedure before running anything: the operator exports each
  value into the environment and the command references `"$VAR"` — never typed,
  echoed, or written into chat, files, or logs (the clean-install procedure).

Then run `kdcube init` with the assembled flags (Step 4). Once it succeeds, pin
the runtime's repo — `<workdir>/repo` — into `config/repos.yaml` so the plugin
resolves KDCube docs from it (the same pin `/kdcube:init` performs).
Carry the flow through to the init and the pin; do not stop on an ambiguous
"start now or fill first?" — finish, then report the checklist and one concrete
next action.

Determine the source, then get the CLI:

Both are answerable before any repo exists, so decide them first — they are
what the fresh run branches on.

- **Platform source** — what `kdcube init` clones into `<workdir>/repo`:
  `--latest` (latest release, and the default), `--upstream` (github
  origin/main), `--release <ref>` (a pinned release), or `--path <checkout>`
  (a local checkout, developer override).
- **CLI acquisition** follows from it: with no checkout, `pip install
  kdcube-cli` — the PyPI bootstrap that clones the platform at init — paired
  with `--latest` / `--upstream` / `--release`; with a checkout you develop
  against, an editable install of its `kdcube_cli` paired with `--path`. There
  is no separate "CLI from github" — upstream is the init flag `--upstream`,
  not an install source.

Exact install and init commands are Steps 2 and 4 below.

Recommended minimal bring-up:

The default identity is application-hosted login (`--auth-type bundle`): the
workspace app hosts the Google sign-in page and Connection Hub issues the
KDCube session, so no external IdP is involved. Its one input is a Google **Web
application** OAuth client id — public, no client secret — which the operator
supplies; the agent asks for it and never creates or invents one. If the
operator does not have one yet, walk them through obtaining it (a Google
Web-application OAuth client with this runtime's UI origin authorized as a
JavaScript origin) and wait for the real id. **Do not run app-hosted init with
a placeholder client id.** The CLI would accept a `<FILL_ME>` slot, but the
result is a runtime that looks up yet cannot be signed into — a trap, not a
convenience. An operator who genuinely wants no sign-in yet wants the `simple`
setup, not bundle-with-placeholder.

```bash
kdcube init \
  --tenant "$TENANT" \
  --project "$PROJECT" \
  --auth-type bundle \
  --client-id "<google-web-oauth-client-id>" \
  --bootstrap-admin-email "admin@example.com"    # optional: first super-admin
```

Add the platform-source flag chosen above and any `--set-secret` pairs the
operator provided. This is the compact core; the fuller walkthrough — exact
JavaScript origins and the local UI port, plus the optional Telegram companion
— is
`repo:kdcube-ai-app/app/ai-app/docs/recipes/operations/install-clean-README.md`,
readable once the repo is pinned.

What a fresh init stages (no descriptors supplied): the **base complectation,
already configured** — Connection Hub (identity, consent, delegated
credentials), KDCube Services (managed MCP + named services), User Memories
(the `mem` provider), and the workspace showcase app (scene + chat).
Environment inputs the init substitutes into the staged defaults when set:

```bash
# Substituted into <PUBLIC_HOST> / <ADMIN_EMAIL> placeholder slots in the
# staged defaults — separate from --bootstrap-admin-email above.
export KDCUBE_PUBLIC_HOST="kdcube.example.com"
export KDCUBE_ADMIN_EMAIL="admin@example.com"
```

Init ends with a **first-run checklist** of placeholders still unfilled
(`<FILL_ME>` secret slots, plus the above when their env vars were unset).
Read it to the operator verbatim: features backed by an unfilled slot stay
inactive; everything else runs. Slots are filled later in
`WORKDIR/config/bundles.yaml` / `bundles.secrets.yaml` (each slot carries a
where-to-get-it comment) or via the AI Bundles dashboard.

Fast clone from an existing runtime:

Use this when the operator wants a new local environment that starts from a
known-good existing environment. Prefer this over rebuilding descriptors by
hand.

```bash
export OUT_DIR="$HOME/.kdcube/exports/${SOURCE_TENANT}__${SOURCE_PROJECT}-$(date +%Y%m%dT%H%M%S)"

kdcube config export \
  --tenant "$SOURCE_TENANT" \
  --project "$SOURCE_PROJECT" \
  --out-dir "$OUT_DIR" \
  --include-platform-descriptors
```

Then edit the exported descriptor copy before `init`:

- set the target `context.tenant` / `context.project` in `assembly.yaml`;
- set the target tenant/project in `gateway.yaml`;
- replace tenant/project segments inside bundle URLs, webhook URLs, OAuth
  resource URLs, Data Bus/project-broadcast config, and Redis key prefixes;
- update public origins/callback bases only if the target runtime uses a
  different public host;
- keep secret values inside descriptor files or the secret store, but never
  print them in chat, docs, or logs.

Verify before init:

```bash
rg "$SOURCE_PROJECT|$SOURCE_TENANT/$SOURCE_PROJECT" "$OUT_DIR"
```

Initialize the target from the edited export:

```bash
kdcube init \
  --tenant "$TARGET_TENANT" \
  --project "$TARGET_PROJECT" \
  --descriptors-location "$OUT_DIR" \
  --build
```

After that, treat the target like any normal runtime: use `kdcube refresh` for
platform rebuild/restart, `kdcube bundle config apply --reload` for descriptor
bundle updates, and `kdcube bundle reload <bundle-id>` for one bundle.

Descriptor-backed first run:

```bash
kdcube init \
  --tenant "$TENANT" \
  --project "$PROJECT" \
  --descriptors-location "<descriptor-dir>" \
  --set-secret services.openai.api_key "<openai-key>" \
  --set-secret services.anthropic.api_key "<anthropic-key>" \
  --set-secret services.brave.api_key "<brave-key>" \
  --set-secret services.git.http_token "<git-token>" \
  --set-secret git.http_token "<git-token>"
```

Steps:

1. Read `tier1/06-configure-and-run.md` and
   `tier1/05-runtime-config.md` before changing runtime state.
   If the local runtime must be reachable by Telegram, OAuth/Cognito,
   or another external callback provider, also read
   `tier1/09-local-public-ngrok.md`.
   These tier1 files are mirrors of the checkout. If `config/repos.yaml` is not
   pinned yet, run `/kdcube:init` first — it pins the repo and
   reconciles the pack; until then the freshness check is a no-op and the
   mirrors may be stale.

2. Ensure `kdcube`:
   - prefer an already-installed `kdcube` (active venv, or on PATH);
   - if it is not installed, install the published CLI: `pip install kdcube-cli`
     — a lightweight bootstrap package that needs no platform checkout (it clones
     the platform itself at `kdcube init`). Editable install from a local repo
     (`pip install -e <repo>/app/ai-app/src/kdcube-ai-app/kdcube_cli`, see
     `repo:kdcube-ai-app/app/ai-app/docs/recipes/operations/install-clean-README.md`)
     is the developer variant. Report the command; install only with operator
     consent.

3. Confirm the descriptor source:
   - seed descriptors are source-controlled templates;
   - staged runtime descriptors live under the CLI workdir;
   - generated/staged `config/secrets.yaml` is runtime-local and must
     not be committed;
   - internal signing keys (`services.session_token.secret`,
     `services.federated_token.secret`) are generated by `kdcube init` itself,
     not supplied by anyone. Do not generate, fill, or overwrite them — init has
     already done it, and rewriting a live key breaks issued sessions. In the
     checklist they are a statement that the CLI created them, not a task.

4. Run `kdcube init` with `--tenant` and `--project`, plus the platform-source
   flag chosen at the top (`--latest` / `--upstream` / `--release <ref>` /
   `--path`) — the CLI clones that source into `<workdir>/repo`. Add
   `--descriptors-location` only when a descriptor set is intentionally
   supplied. Add the `--set-secret` pairs the operator provided. Mask secret
   values in all user-facing output and summaries. Select the authentication
   method with `--auth-type`; the recommended default is application-hosted
   login (`--auth-type bundle --client-id`, above). Other methods and their
   per-mode flags are CLI §2.3e —
   `repo:kdcube-ai-app/app/ai-app/docs/service/cicd/cli-README.md#auth-flags`.

5. Verify with:

```bash
kdcube info --tenant "$TENANT" --project "$PROJECT"
```

Use the concrete namespaced workdir shown by `kdcube info` after init
when starting/reloading, for example:

```bash
kdcube info --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

6. If the runtime should be started now, run:

```bash
kdcube start --tenant "$TENANT" --project "$PROJECT"
```

or:

```bash
kdcube start --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

Only after `kdcube info` shows the expected tenant/project and staged
configuration.

7. If the operator needs a public local DNS name for webhooks or
   callbacks, follow `tier1/09-local-public-ngrok.md`: one ngrok HTTPS
   origin through the local reverse proxy, descriptor-driven
   `assembly.yaml` / `bundles.yaml` / `bundles.secrets.yaml` updates,
   and no separate public proc URL.

8. If the operator changed the platform source or descriptor set and wants the
   runtime rebuilt/restarted, use `kdcube refresh --tenant "$TENANT"
   --project "$PROJECT" --build`. Refresh already performs the stop/start
   lifecycle; do not add a second manual stop/start unless diagnosing a
   failure. To change the authentication method on an already-initialized
   runtime, use `kdcube config apply` (CLI §2.3f,
   `repo:kdcube-ai-app/app/ai-app/docs/service/cicd/cli-README.md#config-apply-auth`)
   instead of re-init.

Output a compact table:

| Check | Status | Detail |
|---|---|---|
| CLI available | OK/FAIL | path/version |
| descriptors | OK/FAIL | source path |
| secrets seeded | OK/FAIL | names only, never values |
| runtime info | OK/FAIL | tenant/project/workdir |

Refuse if asked to put real secrets in source descriptors, templates,
README files, journal entries, or command transcripts.

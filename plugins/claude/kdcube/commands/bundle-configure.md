---
description: "Register or update a bundle in a KDCube runtime with kdcube bundle: source location/ref, plain config, secrets, and reload. Keeps source descriptors, staged runtime descriptors, bundle props, and secrets separate."
---

# /kdcube:bundle-configure

Configure a bundle in an initialized KDCube runtime.

Required operator inputs:

- `bundle_id`, for example `task-and-memo-app@1-0`;
- runtime workdir or confirmation to use the default;
- source mode:
  - `local`: runtime/container-visible bundle path;
  - `git`: repo URL, ref/tag/branch, path in repo, module, entrypoint;
  - `built-in`: built-in bundle id and config only;
- plain bundle config keys and values;
- secret key names and values, supplied only through CLI secret
  arguments or an approved secret store.

Steps:

1. Read `tier1/05-runtime-config.md` and
   `tier1/06-configure-and-run.md`, and use the **kdcube-operator** skill for the
   descriptor levels (platform / bundle / user) and the
   configure → reload/refresh → verify → logs loop.
   If the bundle config includes provider callback URLs such as
   Telegram webhook URLs, OAuth/Cognito callback behavior, or remote
   callback/control integrations for a local runtime, also read
   `tier1/09-local-public-ngrok.md`.

2. Inspect the bundle's own config contract:
   - `config/bundles.template.yaml`;
   - `config/bundles.secrets.template.yaml`;
   - `README.md`;
   - `AGENTS.md` if present.

3. Decide which descriptor layer you are changing:
   - source/seed descriptors are templates and should not receive
     developer-machine-only paths unless they are explicitly local
     debug descriptors;
   - staged runtime descriptors are patched by `kdcube bundle`;
   - real secrets go only through `--set-secret` or the configured
     secret store.

4. Register the source with `kdcube bundle <bundle_id> ...`.
   Use a git source for cloud/portable deployments. Use local source
   only when the path is visible to the runtime where processors run.

Local source shape:

```bash
kdcube bundle my.bundle@1-0 \
  --local-path /bundles/my.bundle \
  --name "My Bundle" \
  --module entrypoint \
  --no-singleton \
  --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

Git source shape:

```bash
kdcube bundle my.bundle@1-0 \
  --git-repo https://github.com/your-org/your-bundles.git \
  --git-ref main \
  --git-subdir src/my.bundle@1-0 \
  --name "My Bundle" \
  --module entrypoint \
  --no-singleton \
  --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

Built-in bundle shape:

```bash
kdcube bundle <built-in-bundle-id> \
  --set-config some.key some-value \
  --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

For built-in bundles, do not invent a source path. Patch an existing
staged entry or the deployment descriptor fields that enable/include
the built-in bundle, based on Tier 1 docs.

5. Write non-secret config with `--set-config` and secrets with
   `--set-secret`. Never print secret values.
   For local public callback URLs, store the ngrok HTTPS URL in
   descriptor-backed bundle config; do not hardcode localhost into
   bundle code.

```bash
kdcube bundle my.bundle@1-0 \
  --set-config config.react.max_iterations 15 \
  --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>

kdcube bundle my.bundle@1-0 \
  --set-secret telegram.bot_token "<secret-value>" \
  --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

6. Run:

```bash
kdcube bundle reload my.bundle@1-0
kdcube info
```

Use the concrete runtime workdir when needed:

```bash
kdcube bundle reload my.bundle@1-0 \
  --workdir ~/.kdcube/kdcube-runtime/<tenant>__<project>
```

If you edited a staged descriptor directly instead of using `--set-config` /
`--set-secret`, apply it with `kdcube bundle reload <id>` (app config/source) or
`kdcube refresh` (a descriptor that needs a proc cycle).

7. Verify, and read logs if anything is off:

```bash
kdcube bundle status my.bundle@1-0 --json | python3 -m json.tool
# on failure, find the container and tail logs:
docker ps
docker logs -f <kdcube proc container>   # app load/exec errors surface here
docker logs -f <ingress container>       # request/auth/event-entry errors
# or read the runtime logs dir: ~/.kdcube/kdcube-runtime/<tenant>__<project>/logs/
```

Re-apply (`kdcube bundle reload` / `kdcube refresh`) after a fix.

8. Report:

| Area | Result |
|---|---|
| source | mode/ref/path, no secret material |
| plain config | keys changed |
| secrets | names changed, values masked |
| reload | status |
| next test | command to run |

Refuse if:

- the operator asks to store real secrets in source descriptors;
- a local host path is being written into a descriptor intended for
  cloud or shared deployment;
- the bundle id is inferred from a folder name instead of confirmed.

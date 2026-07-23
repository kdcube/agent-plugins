---
description: "Run the content-release procedure for a bundle. Exact same flow as the platform's /content-release procedure: descriptor → plan → operator approval → execute → journal. Refuses to commit/tag/push without explicit operator approval values."
---

# /kdcube:bundle-release

Run a Bundle Release Run for the named bundle, following the canonical
content-release procedure (`tier1/07-release-content.md`).

Required operator inputs **before any file is written**:

- release version (format `YYYY.M.D.HHMM`, e.g. `2026.5.8.245`);
- repository name (must match a `config/repos.yaml` entry);
- bundle id and path;
- which of `commit`, `tag`, `push` the operator authorizes;
- release-changes bullets (or "auto-generate from journal").

Steps:

1. Read `tier1/07-release-content.md`. Follow it.

2. Write `descriptor-<dd.mm.yyyy.hhmm>.yaml` under
   `deployment/cicd/kdcube/cicd/content-release-history/<dd.mm.yyyy>/`
   in the bundle's repo. Then write a readable
   `plan-<dd.mm.yyyy.hhmm>.log` enumerating the files that will
   change, validations that will run, and the exact commit/tag/push
   commands.

3. **Stop and wait for `approve` / `go`.** Do not proceed without
   it.

4. On approval, align the bundle release files
   (`release.yaml`, `config/bundles.template.yaml`,
   `config/bundles.secrets.template.yaml`, `README.md` if
   contract changed). Run YAML validation, py-compile through the
   proven project venv, `git diff --cached --check`, and `git status`
   scope check.

5. Commit only release-scoped files. Tag iff authorized. Push iff
   authorized. Stop-on-tag-exists is mandatory: if `git tag <ref>`
   already exists, halt and ask the operator.

6. Write `execute-<dd.mm.yyyy.hhmm>.yaml` with one entry per step
   (start time, end time, status, output, error).

Refuse if:

- the operator has not named the version explicitly;
- the operator has not named which actions to perform;
- the bundle has unrelated dirty work in the tree (unless the
  operator confirms it should be staged with the release).

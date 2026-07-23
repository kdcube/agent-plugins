---
description: "Run the bundle test contract from tier1/02-test.md. Enforces the working-environment preflight: prove the project venv before any python3 / pytest invocation. Refuses to interpret async failures until pytest-asyncio is installed in the active venv."
---

# /kdcube:bundle-test

Run tests for the bundle the operator names (or the bundle the
session's CWD lives inside).

Steps:

1. **Working-environment preflight** — read
   `tier1/02-test.md#1a-working-environment-for-agents`. Prove the
   project venv exists, is activated, and has `pytest` +
   `pytest-asyncio`. **Do not run bare `python3` or `pytest`
   anywhere.** If the venv is missing, surface exactly that and stop.

2. Locate the test root for the bundle (`<bundle_path>/tests/`).

3. Run the SDK-shared bundle suite first (per `02-test.md`), then the
   bundle-local pytest. Capture pass/fail counts and the first
   failure's traceback. Do not interpret async failures until
   `pytest-asyncio` is confirmed installed; surface the missing-dep
   diagnostic instead.

4. If any failure looks like a configuration issue (descriptor key
   missing, env var not set), cross-check against
   `tier1/05-runtime-config.md` and `tier1/06-configure-and-run.md`.

5. If the bundle uses Telegram webhooks, OAuth/Cognito callbacks, or
   another external provider that must call the local runtime, read
   `tier1/09-local-public-ngrok.md` and validate through the public
   HTTPS ngrok origin before interpreting callback failures.

6. Print a short summary: counts, first failure (if any), and any
   guardrail violations the agent caught (bare `python3`, missing
   `pytest-asyncio`, etc.).

Refuse to "fix" failing tests without explicit operator approval; the
default behavior is to report.

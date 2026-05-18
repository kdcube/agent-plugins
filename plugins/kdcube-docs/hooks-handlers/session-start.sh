#!/usr/bin/env bash
# Inject the kdcube-dev MCP usage contract at session start. Always-on belt
# for the kdcube-docs:kdcube workflow skill — the skill is model-invoked and
# its trigger description can miss; this fragment guarantees the docs-first
# behavior is in context regardless of how the user phrases their question.

cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "kdcube-docs plugin loaded. kdcube-dev MCP tools: search_knowledge(query) and read_knowledge(path) against the live KDCube docs. For any KDCube question — bundles, decorators (@api, @mcp, @cron, @on_job, @on_message), descriptors, CLI, ReAct runtime — call search_knowledge with the user's phrasing, read_knowledge the top hit, cite ks:docs/... paths inline. Decorator names, descriptor keys, and CLI flags change between releases; do not answer from training memory. For multi-step work, invoke the kdcube-docs:kdcube workflow skill."
  }
}
EOF

exit 0

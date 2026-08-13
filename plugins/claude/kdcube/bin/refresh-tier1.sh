#!/usr/bin/env bash
# Re-copy the canonical Tier 1 doc pack from the local KDCube checkout
# into the plugin's tier1/ folder.
#
# Resolves repos.kdcube.local_path from <plugin>/config/repos.yaml. Existing
# installs that still use the retired repos.kdcube-ai-app key remain readable;
# /kdcube:init migrates that key to repos.kdcube.
#
# Usage: bin/refresh-tier1.sh [--dry-run]

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPOS_YAML="${PLUGIN_ROOT}/config/repos.yaml"
TIER1_DST="${PLUGIN_ROOT}/tier1"

if [[ ! -f "$REPOS_YAML" ]]; then
  echo "error: ${REPOS_YAML} does not exist." >&2
  echo "       copy config/repos.yaml.template to config/repos.yaml first." >&2
  exit 2
fi

# Tiny YAML extractor for this registry's flat shape. Use the canonical key
# first and fall back to the former key for already-installed plugin configs.
repo_local_path() {
  local repo_key="$1"
  awk -v repo_key="$repo_key" '
    $0 ~ "^[[:space:]]*" repo_key ":[[:space:]]*$" { in_repo=1; next }
    in_repo && /^[[:space:]]+local_path:[[:space:]]/ {
      sub(/^[[:space:]]+local_path:[[:space:]]*/, "")
      gsub(/^["'"'"']|["'"'"']$/, "")
      print; exit
    }
    /^[a-zA-Z0-9_-]+:[[:space:]]*$/ && in_repo { in_repo=0 }
  ' "$REPOS_YAML"
}

KDCUBE_LOCAL="$(repo_local_path kdcube)"
if [[ -z "$KDCUBE_LOCAL" ]]; then
  KDCUBE_LOCAL="$(repo_local_path kdcube-ai-app)"
fi

if [[ -z "${KDCUBE_LOCAL}" ]]; then
  echo "error: could not extract repos.kdcube.local_path from ${REPOS_YAML}" >&2
  exit 3
fi

if [[ ! -d "$KDCUBE_LOCAL" ]]; then
  echo "error: KDCube local_path does not exist: ${KDCUBE_LOCAL}" >&2
  exit 4
fi

SRC="${KDCUBE_LOCAL}/app/ai-app/docs"
declare -a PAIRS=(
  "sdk/bundle/build/sync-tier1-bundle-docs-to-build-with-kdcube-plugins-README.md|00-pack-contract.md"
  "sdk/bundle/build/how-to-navigate-kdcube-docs-README.md|01-navigate.md"
  "sdk/bundle/build/how-to-test-bundle-README.md|02-test.md"
  "sdk/bundle/build/how-to-assemble-bundle-with-sdk-building-blocks-README.md|03-assemble.md"
  "sdk/bundle/build/how-to-write-bundle-README.md|04-write.md"
  "configuration/bundle-runtime-configuration-and-secrets-README.md|05-runtime-config.md"
  "sdk/bundle/build/how-to-configure-and-run-bundle-README.md|06-configure-and-run.md"
  "sdk/bundle/build/how-to-release-bundle-content-README.md|07-release-content.md"
  "sdk/bundle/bundle-agent-integration-README.md|08-agent-integration.md"
  "service/cicd/ngrok-README.md|09-local-public-ngrok.md"
  "sdk/bundle/bundle-widget-integration-README.md|10-widget-integration.md"
  "sdk/bundle/build/how-to-avoid-common-bundle-integration-failures-README.md|11-common-failures.md"
  "sdk/bundle/bundle-economics-integration-README.md|12-economics.md"
)

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

for pair in "${PAIRS[@]}"; do
  rel="${pair%%|*}"
  dst_name="${pair##*|}"
  src_path="${SRC}/${rel}"
  dst_path="${TIER1_DST}/${dst_name}"

  if [[ ! -f "$src_path" ]]; then
    echo "missing: $src_path"
    continue
  fi

  if (( DRY_RUN )); then
    echo "would copy: $src_path -> $dst_path"
  else
    cp "$src_path" "$dst_path"
    echo "refreshed: $dst_name"
  fi
done

echo "done."

#!/usr/bin/env bash
# Verify a downloaded aube archive against the release's signed packslip.
# Usage: verify-release.sh <bundle> <archive-path> <archive-name> <tag>
# The packslip npm package needs a recent Node.js; use the runner's when it
# qualifies, otherwise install a private one with mise.
set -euo pipefail

verify_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../verify" && pwd)"
# Node on Windows cannot resolve Git Bash's /d/a/... paths.
if command -v cygpath >/dev/null 2>&1; then
  verify_dir="$(cygpath -m "$verify_dir")"
fi

node_ok() {
  command -v node >/dev/null 2>&1 && node -e '
    const [a, b, c] = process.versions.node.split(".").map(Number);
    const ok = a >= 26 || (a === 24 && (b > 15 || (b === 15 && c >= 0))) ||
      (a === 22 && (b > 22 || (b === 22 && c >= 2)));
    process.exit(ok ? 0 : 1)'
}

if ! node_ok; then
  echo "Runner Node.js is missing or older than packslip supports; installing Node.js 24 with mise"
  scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
  mise="$("$scripts_dir/ensure-mise.sh")"
  node_dir="${RUNNER_TEMP:-/tmp}/aube-action-verify-node"
  rm -rf "$node_dir"
  "$mise" install-into node@24 "$node_dir" >&2
  # `install-into` puts node at <dir>/bin, or at <dir>/node.exe on Windows.
  PATH="$node_dir/bin:$node_dir:$PATH"
fi

npm ci --prefix "$verify_dir" --ignore-scripts --no-audit --no-fund --loglevel=error
node "$verify_dir/verify.mjs" "$@"

#!/usr/bin/env bash
# Bundle verify.mjs and its dependencies (packslip, sigstore, ...) into
# dist/verify.mjs. The action runs only that committed file and installs no
# npm packages at run time. Rebuild after changing verify.mjs or bumping a
# dependency in package.json.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
npm ci --ignore-scripts --no-audit --no-fund --loglevel=error
./node_modules/.bin/esbuild verify.mjs \
  --bundle --platform=node --format=esm --target=node22 \
  --legal-comments=eof \
  --banner:js="import{createRequire}from'module';const require=createRequire(import.meta.url);" \
  --outfile=../dist/verify.mjs

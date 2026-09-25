#!/usr/bin/env bash
set -euxo pipefail

# Tags the merged release PR commit, moves the floating major tag (v1, ...)
# so consumers pinning jdx/aube-action@vN pick it up, and creates the
# GitHub release.
: "${TITLE:?}" "${SHA:?}"

if [[ ! "$TITLE" =~ ^chore:\ release\ (v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
	echo "::error::release PR title '$TITLE' is not 'chore: release vX.Y.Z'"
	exit 1
fi
VERSION="${BASH_REMATCH[1]}"
MAJOR_VERSION="${VERSION%%.*}"

# Configure git to use gh's credential helper. The checkout step uses
# persist-credentials: false (per zizmor's artipacked audit), so the
# token isn't written to .git/config and raw `git push` would 403.
gh auth setup-git

git tag "$VERSION" "$SHA" || echo "Tag $VERSION already exists locally"
git push origin "$VERSION" || echo "Tag $VERSION already exists on remote"

git tag -f "$MAJOR_VERSION" "$SHA"
git push -f origin "$MAJOR_VERSION"

if gh release view "$VERSION" >/dev/null 2>&1; then
	echo "Release $VERSION already exists, skipping creation"
else
	gh release create "$VERSION" --generate-notes --verify-tag
fi

echo "tag=$VERSION" >>"${GITHUB_OUTPUT:-/dev/null}"

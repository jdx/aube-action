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

# A rerun may find the tag already created; anything else pointing it at a
# different commit must stop before the major tag moves, or @vN and
# @vX.Y.Z would ship different code.
git fetch --force origin "refs/tags/$VERSION:refs/tags/$VERSION" 2>/dev/null || true
if git rev-parse -q --verify "refs/tags/$VERSION" >/dev/null; then
	tagged="$(git rev-list -n 1 "$VERSION")"
	if [ "$tagged" != "$SHA" ]; then
		echo "::error::$VERSION already points at $tagged, not the merged release commit $SHA"
		exit 1
	fi
	echo "Tag $VERSION already exists at $SHA"
else
	git tag "$VERSION" "$SHA"
fi
git push origin "refs/tags/$VERSION"

git tag -f "$MAJOR_VERSION" "$SHA"
git push -f origin "$MAJOR_VERSION"

if gh release view "$VERSION" >/dev/null 2>&1; then
	echo "Release $VERSION already exists, skipping creation"
else
	gh release create "$VERSION" --generate-notes --verify-tag
fi

echo "tag=$VERSION" >>"${GITHUB_OUTPUT:-/dev/null}"

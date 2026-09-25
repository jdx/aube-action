#!/usr/bin/env bash
# shellcheck shell=bash
set -euxo pipefail

# aube-action has no package manifest, so git tags are the version source of
# truth: the release PR only regenerates CHANGELOG.md, and release.yml tags
# the merge commit with the version from the PR title.

latest_tag="$(git tag --list | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true)"

if [ -n "$latest_tag" ]; then
	commits_since_release="$(git rev-list "$latest_tag"..HEAD --count)"
	if [ "$commits_since_release" -eq 0 ]; then
		echo "No commits since last release $latest_tag"
		exit 0
	fi
	echo "Found $commits_since_release commits since $latest_tag"
fi

# A merged release PR is tagged by release.yml. Until that tag exists, any
# release commit since the last tag means a release is still in flight, even
# if other commits landed on top of it; don't open another PR for it.
pending_release="$(git log --format=%s ${latest_tag:+"$latest_tag"..HEAD} | grep -E '^chore: release v[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
if [ -n "$pending_release" ]; then
	echo "'$pending_release' is merged but not tagged yet; release.yml creates the release."
	exit 0
fi

version="$(git cliff --bumped-version)"
if [ "$version" = "$latest_tag" ]; then
	echo "No version bump from commits since $latest_tag; nothing to release."
	exit 0
fi

changelog="$(git cliff --bump --unreleased --strip all)"

if [ "${DRY_RUN:-1}" == 1 ]; then
	echo "version: $version"
	echo "changelog: $changelog"
	exit 0
fi

if [ -z "$changelog" ] || [ "$changelog" = "---" ]; then
	echo "No unreleased changes found"
	exit 0
fi

git config user.name mise-en-dev
git config user.email 123107610+mise-en-dev@users.noreply.github.com

# Configure git to use gh's credential helper. The checkout step uses
# persist-credentials: false (per zizmor's artipacked audit), so the
# token isn't written to .git/config and raw `git push` would 403.
gh auth setup-git

git cliff --tag "$version" -o CHANGELOG.md
git add CHANGELOG.md
git status

git checkout -B release
git commit -m "chore: release $version"
git push origin release --force

# release.yml only runs for merged PRs carrying this label.
gh label create release --color 0e8a16 --description "Merging this PR cuts a release" --force

if gh pr create --title "chore: release $version" --body "$changelog" --label release; then
	echo "Created new release PR"
else
	gh pr edit release --title "chore: release $version" --body "$changelog" --add-label release
	echo "Updated existing release PR"
fi

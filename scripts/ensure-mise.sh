#!/usr/bin/env bash
# Install mise if the runner has none and print the path to its binary.
# mise.run is mise's documented installer and the runner has no mise yet, so
# there is no mise.lock to verify the download against.
set -euo pipefail

# mise.run is a POSIX shell script; on Windows we fetch the standalone .exe
# from jdx/mise releases instead.
if [ "$RUNNER_OS" = "Windows" ]; then
  mise_dir="${RUNNER_TEMP:-/tmp}/aube-action-mise"
  mise="$mise_dir/mise.exe"
  if [ ! -x "$mise" ]; then
    arch_suffix=x64
    if [ "$RUNNER_ARCH" = "ARM64" ]; then arch_suffix=arm64; fi
    mise_loc="$(curl -fsSIL -o /dev/null -w '%{url_effective}' \
      'https://github.com/jdx/mise/releases/latest')"
    mise_ver="${mise_loc##*/tag/}"
    mkdir -p "$mise_dir"
    curl -fsSL -o "$mise" \
      "https://github.com/jdx/mise/releases/download/$mise_ver/mise-$mise_ver-windows-$arch_suffix.exe" >&2
  fi
else
  if [ ! -x "$HOME/.local/bin/mise" ] && ! command -v mise >/dev/null 2>&1; then
    curl -fsSL https://mise.run | sh >&2
  fi
  if [ -x "$HOME/.local/bin/mise" ]; then
    mise="$HOME/.local/bin/mise"
  else
    mise="$(command -v mise)"
  fi
fi

echo "$mise"

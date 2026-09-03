#!/usr/bin/env bash
# Shared helpers for --offline installers. Source from other scripts.
# Caller must have set -euo pipefail.

# Sets OFFLINE=0|1 and POSITIONAL=( remaining argv ).
scaffold_parse_offline_args() {
  OFFLINE=0
  POSITIONAL=()
  local a
  for a in "$@"; do
    if [[ "$a" == "--offline" ]]; then
      OFFLINE=1
    else
      POSITIONAL+=("$a")
    fi
  done
}

scaffold_skill_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

scaffold_offline_bundle() {
  echo "$1/vendor/offline/1c-scaffold-deps.tar.gz"
}

scaffold_offline_manifest() {
  echo "$1/vendor/offline/MANIFEST.txt"
}

scaffold_offline_require() {
  local skill_dir="$1"
  local bundle manifest
  bundle="$(scaffold_offline_bundle "$skill_dir")"
  manifest="$(scaffold_offline_manifest "$skill_dir")"
  if [[ ! -f "$bundle" ]]; then
    echo "error: offline bundle missing: $bundle" >&2
    echo "error: run scripts/pack-offline-bundle.sh while online, or choose online install" >&2
    return 2
  fi
  if [[ ! -f "$manifest" ]]; then
    echo "error: offline MANIFEST missing: $manifest" >&2
    return 2
  fi
}

scaffold_manifest_get() {
  local manifest="$1" key="$2"
  if [[ ! -f "$manifest" ]]; then
    return 1
  fi
  awk -F= -v k="$key" '$1==k { print substr($0, length($1)+2); exit }' "$manifest"
}

# Extract one tar member (file) to an exact destination path.
scaffold_offline_extract_file() {
  local bundle="$1" member="$2" dest="$3"
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/offline-extract.XXXXXX")"
  if ! tar -xzf "$bundle" -C "$tmp" "$member" 2>/dev/null; then
    rm -rf "$tmp"
    echo "error: missing ${member} in offline bundle" >&2
    return 2
  fi
  if [[ ! -f "$tmp/$member" ]]; then
    rm -rf "$tmp"
    echo "error: extracted path is not a file: ${member}" >&2
    return 2
  fi
  mkdir -p "$(dirname "$dest")"
  cp -a "$tmp/$member" "$dest"
  rm -rf "$tmp"
}

# Extract a directory member into dest (dest becomes that directory).
scaffold_offline_extract_dir() {
  local bundle="$1" member="$2" dest="$3"
  local tmp parent
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/offline-extract.XXXXXX")"
  if ! tar -xzf "$bundle" -C "$tmp" "$member" 2>/dev/null; then
    rm -rf "$tmp"
    echo "error: missing ${member}/ in offline bundle" >&2
    return 2
  fi
  if [[ ! -d "$tmp/$member" ]]; then
    rm -rf "$tmp"
    echo "error: extracted path is not a directory: ${member}" >&2
    return 2
  fi
  parent="$(dirname "$dest")"
  mkdir -p "$parent"
  rm -rf "$dest"
  cp -a "$tmp/$member" "$dest"
  rm -rf "$tmp"
}

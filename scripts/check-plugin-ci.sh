#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/templates/github/workflows/plugin-ci.yml"
FIX=false

if [ "${1:-}" = "--fix" ]; then
  FIX=true
  shift
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "Missing canonical workflow template: $TEMPLATE" >&2
  exit 2
fi

plugins=()
if [ "$#" -gt 0 ]; then
  for plugin in "$@"; do
    case "$plugin" in
      /*) plugins+=("$plugin") ;;
      *) plugins+=("$ROOT/$plugin") ;;
    esac
  done
else
  for dir in "$ROOT"/*; do
    [ -d "$dir" ] || continue
    [ -d "$dir/.git" ] || continue
    [ -f "$dir/plugin.json" ] || continue
    plugins+=("$dir")
  done
fi

if [ "${#plugins[@]}" -eq 0 ]; then
  echo "No nested owned plugin clones found." >&2
  exit 2
fi

status=0
for plugin_dir in "${plugins[@]}"; do
  name="${plugin_dir#$ROOT/}"
  workflow="$plugin_dir/.github/workflows/ci.yml"

  if [ ! -f "$plugin_dir/plugin.json" ]; then
    echo "Skipping $name: no plugin.json" >&2
    continue
  fi

  if [ "$FIX" = true ]; then
    mkdir -p "$plugin_dir/.github/workflows"
    cp "$TEMPLATE" "$workflow"
    echo "synced $name"
    continue
  fi

  if [ ! -f "$workflow" ]; then
    echo "missing $name/.github/workflows/ci.yml"
    status=1
    continue
  fi

  if cmp -s "$TEMPLATE" "$workflow"; then
    echo "ok $name"
  else
    echo "drift $name"
    diff -u "$TEMPLATE" "$workflow" || true
    status=1
  fi
done

exit "$status"

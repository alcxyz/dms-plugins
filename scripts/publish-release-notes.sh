#!/usr/bin/env bash
# Publish CHANGELOG.md sections as GitHub release notes for an owned plugin.
#
# Usage:
#   scripts/publish-release-notes.sh <plugin-dir> [vX.Y.Z ...]
#   scripts/publish-release-notes.sh --print-render-script
#
# Without tags, every existing GitHub release that has a matching changelog
# section is updated. The notes are rendered by the same "Render release notes"
# step that the canonical workflow runs, so backfilled and automated release
# notes are identical. Requires gh authenticated for the plugin repository.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/templates/github/workflows/plugin-ci.yml"

render_script() {
  awk '
    /^      - name: Render release notes$/ { in_step = 1; next }
    in_step && /^      - name: / { exit }
    in_step && /^        run: \|$/ { in_run = 1; next }
    in_run { sub(/^          /, ""); print }
  ' "$TEMPLATE"
}

if [ "${1:-}" = "--print-render-script" ]; then
  render_script
  exit 0
fi

if [ "$#" -lt 1 ]; then
  sed -n '2,11p' "$0" >&2
  exit 2
fi

plugin_dir="$1"
shift
case "$plugin_dir" in
  /*) ;;
  *) plugin_dir="$ROOT/$plugin_dir" ;;
esac

if [ ! -f "$plugin_dir/CHANGELOG.md" ]; then
  echo "Missing $plugin_dir/CHANGELOG.md" >&2
  exit 2
fi

repository="$(git -C "$plugin_dir" remote get-url origin | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')"
if [ -z "$repository" ]; then
  echo "Cannot determine the GitHub repository for $plugin_dir" >&2
  exit 2
fi

tags=("$@")
if [ "${#tags[@]}" -eq 0 ]; then
  mapfile -t tags < <(gh release list -R "$repository" --limit 200 --json tagName --jq '.[].tagName' | sort -V)
fi

script="$(render_script)"
status=0
for tag in "${tags[@]}"; do
  version="${tag#v}"
  if ! grep -q "^## \[$version\]" "$plugin_dir/CHANGELOG.md"; then
    echo "skip $tag: no CHANGELOG.md section"
    continue
  fi
  if ! (cd "$plugin_dir" && VERSION="$tag" GITHUB_REPOSITORY="$repository" bash -e -o pipefail -c "$script"); then
    echo "failed to render $tag" >&2
    status=1
    continue
  fi
  if gh release edit "$tag" -R "$repository" --notes-file "$plugin_dir/release-notes.md" >/dev/null; then
    echo "updated $tag"
  else
    echo "failed to update $tag" >&2
    status=1
  fi
  rm -f "$plugin_dir/release-notes.md"
done

exit "$status"

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$ROOT/templates/build-identity"
plugins=("$@")
if [ "${#plugins[@]}" -eq 0 ]; then
  plugins=(DankAIUsage DankCalendar DankDiskUsage DankDisplayControl DankQuickSearch DankSession DankSpotify DankTranslate DankVault)
fi
status=0
for plugin in "${plugins[@]}"; do
  case "$plugin" in /*) path="$plugin" ;; *) path="$ROOT/$plugin" ;; esac
  for file in scripts/package.py tests/test_package.py build-version.nix build-metadata.nix; do
    if ! cmp -s "$TEMPLATE/$file" "$path/$file"; then
      echo "build identity drift: $plugin/$file" >&2
      status=1
    fi
  done
  if ! python3 - "$path" <<'PY'
import json, pathlib, re, sys
root = pathlib.Path(sys.argv[1])
config = json.loads((root / "packaging.json").read_text())
manifest = json.loads((root / "plugin.json").read_text())
assert re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", config["pluginDirectory"])
assert re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", manifest["version"])
if config.get("helper"):
    assert (root / "cmd" / config["helper"]).is_dir()
PY
  then status=1; fi
  if ! python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1])).get("helper") else 1)' "$path/packaging.json"; then
    if ! cmp -s "$TEMPLATE/default.nix" "$path/default.nix"; then
      echo "build identity drift: $plugin/default.nix" >&2
      status=1
    fi
  fi
done
exit "$status"

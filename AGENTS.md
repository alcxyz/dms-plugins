# DMS Plugin Repo Rules

Owned plugin repositories are cloned as nested git repositories under this repo.
The aggregator repo keeps policy and templates; each plugin repo keeps its own
self-contained workflow files so forks continue to work without depending on a
central reusable workflow.

When creating or modifying an owned plugin:

- make changes on `dev`; do not push directly to `main`;
- keep `.github/workflows/ci.yml` byte-for-byte aligned with
  `templates/github/workflows/plugin-ci.yml`;
- do not invent repo-specific release logic unless an ADR documents why;
- use `test.sh` for plugin-specific shell/QML checks when present;
- use `go.mod` and `go-version-file` for Go plugins;
- validate `plugin.json` and semver in CI;
- release from `main` only using `plugin.json` version tags;
- promote `dev` to `main` through the remote repository's normal review/merge
  flow;
- run `scripts/check-plugin-ci.sh` before finishing pipeline work.

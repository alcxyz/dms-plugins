# DMS Plugin Repo Rules

Owned plugin repositories are cloned as nested git repositories under this repo.
The aggregator repo keeps policy and templates; each plugin repo keeps its own
self-contained workflow files so forks continue to work without depending on a
central reusable workflow.

This plugin set is GitHub-first per
`~/src/infra/gitops/docs/repo-hosting-policy.md`: GitHub is canonical for
branches, pull requests, releases, issues, and public workflow state. Forgejo
mirrors are secondary continuity copies, not the normal push target.

When creating or modifying an owned plugin:

- make changes on `dev`; do not push directly to `main`;
- push `dev` to the GitHub `origin` only; do not dual-push to Forgejo;
- keep `.github/workflows/ci.yml` byte-for-byte aligned with
  `templates/github/workflows/plugin-ci.yml`;
- keep aggregate automation in GitHub Actions and have it update `dev`, not
  `main`;
- do not invent repo-specific release logic unless an ADR documents why;
- use `test.sh` for plugin-specific shell/QML checks when present;
- use `go.mod` and `go-version-file` for Go plugins;
- validate `plugin.json` and semver in CI;
- release from `main` only using `plugin.json` version tags;
- promote `dev` to `main` through a GitHub pull request;
- run `scripts/check-plugin-ci.sh` before finishing pipeline work.

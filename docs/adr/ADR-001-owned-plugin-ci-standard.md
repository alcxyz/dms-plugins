# ADR-001: Standardize Owned Plugin CI

## Status

Accepted

## Context

Owned DankMaterialShell plugins are maintained as separate git repositories
cloned under this aggregator repo during development. The aggregator pulls the
published plugin repositories as flake inputs, while each plugin repository owns
its own CI/CD configuration.

The owned plugin pipelines perform the same core work:

- validate `plugin.json`;
- reject non-semver plugin versions;
- run plugin-specific tests when available;
- build and test Go helpers when present;
- tag releases from `plugin.json`;
- create or update the GitHub Release for that tag.

Copying custom workflow variants into each plugin has already caused drift:
different Go setup approaches, different release tag implementations, and branch
differences between `main` and `dev`.

Reusable workflows would reduce duplication, but they couple forked plugins to a
central workflow repository and depend on GitHub Actions access settings. These
plugins should remain fork-friendly and self-contained.

## Decision

Owned plugin repositories must use a copied canonical workflow:

`templates/github/workflows/plugin-ci.yml`

Each plugin repository stores that template at:

`.github/workflows/ci.yml`

The workflow is capability-based instead of plugin-specific:

- if `go.mod` exists, set up Go from `go.mod`, then run `go build ./...` and
  `go test ./...`;
- if `test.sh` exists, run `bash test.sh`;
- always validate `plugin.json`;
- always enforce `X.Y.Z` version format;
- release only on pushes to `main`;
- tag `vX.Y.Z` from `plugin.json`;
- create or update the GitHub Release with the same hardened GitHub API flow.

Plugin changes, including workflow changes, are made on `dev`. Direct pushes to
`main` are not part of the working model. `main` is updated by promoting `dev`
through the remote repository's normal review/merge flow.

The local drift check is:

`scripts/check-plugin-ci.sh`

The script compares every nested owned plugin clone's `.github/workflows/ci.yml`
against the canonical template. It can also sync workflows with `--fix`.

## Consequences

Plugin repositories stay self-contained and continue to work when forked.

CI/CD behavior stays consistent across owned plugins without forcing every plugin
to have the same implementation language or test files.

Workflow changes must be made once in the template, then copied into each owned
plugin repo on `dev` and promoted to `main` remotely.

Intentional divergence requires a follow-up ADR explaining why that plugin cannot
use the shared contract.

# ADR-001: Standardize Owned Plugin CI

## Status

Accepted

## Context

Owned DankMaterialShell plugins are maintained as separate git repositories
cloned under this aggregator repo during development. The aggregator pulls the
published plugin repositories as flake inputs, while each plugin repository owns
its own CI/CD configuration.

The repository hosting policy classifies `dms-plugins` and the public DMS plugin
repositories as GitHub-first. GitHub is canonical for pull requests, releases,
issues, public workflow state, and plugin-registry-facing assets. Forgejo
mirrors are secondary continuity copies and should not be used as a parallel
push target.

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

The manifest check also verifies required metadata and local component/settings
files, allowing QML URL query parameters. Release tags are immutable: a push
with an already released version at a different commit does not edit that
release or mark it latest again. Annotated and lightweight tags are both resolved
to commits. Re-running the release commit can finish an interrupted release.

Plugin changes, including workflow changes, are made on `dev`. Direct pushes to
`main` are not part of the working model. Push `dev` to the GitHub `origin`
only; do not dual-push to Forgejo. `main` is updated by promoting `dev` through
a GitHub pull request.

The aggregate repo follows the same hosting rule. Scheduled maintenance workflows
run in GitHub Actions and push lockfile updates to `dev`; Forgejo Actions
workflows are not used for this repo.

The local drift check is:

`scripts/check-plugin-ci.sh`

The script compares every nested owned plugin clone's `.github/workflows/ci.yml`
against the canonical template. It can also sync workflows with `--fix`.
Syncing requires each target clone to be on `dev` and refuses to overwrite local
workflow edits; worktree clones are supported.

Aggregate GitHub CI runs offline regression tests for the workflow's manifest
and tag scripts and checks the nine owned source repositories' `dev` workflows
against the template on pushes, pull requests, and daily. Upstream forks are
excluded. When adding an owned source repository, add it to the drift job's
matrix in `.github/workflows/ci.yml`.

For template updates, sync and validate the owned plugin clones, publish those
workflow changes to their `dev` branches, and then validate the aggregate PR.
The cross-repository drift check will fail until all copies match. Keep each
plugin's normal release promotion separate from syncing its CI copy.

## Consequences

Plugin repositories stay self-contained and continue to work when forked.

CI/CD behavior stays consistent across owned plugins without forcing every plugin
to have the same implementation language or test files.

Workflow changes must be made once in the template, then copied into each owned
plugin repo on `dev` and promoted to `main` through GitHub.

Intentional divergence requires a follow-up ADR explaining why that plugin cannot
use the shared contract.

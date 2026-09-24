# ADR-003: Changelog-driven release notes

**Status:** Accepted
**Date:** 2026-09-24

## Context

The shared workflow (ADR-001) created GitHub Releases with GitHub's generated
notes: a list of pull-request titles and a compare link. For squash-promoted
repositories that list is one line, "Release X (#N)", and says nothing about
what changed. The informative releases in this plugin set (for example
DankAIUsage 0.6.0 through 1.2.0) were written by hand after the workflow had
already published the release, and that step was easy to skip.

Tools that derive notes from history (release-please, git-cliff, GitHub's
`release.yml` categories) reformat commit subjects or pull-request titles. Our
commits are squashed per feature and are good commit messages, but they are not
user-facing release notes, and no tool can turn "page reset history four at a
time" into an explanation of what the user will see.

## Decision

Release notes are written by hand, in the repository, before the release exists,
and the workflow refuses to release without them.

- Every owned plugin keeps a `CHANGELOG.md` in Keep a Changelog form: a leading
  `## [Unreleased]` section followed by one `## [X.Y.Z] - YYYY-MM-DD` section
  per released version, newest first. `templates/CHANGELOG.md` is the starting
  point for new plugins.
- Feature and fix work adds its user-facing sentence under `[Unreleased]` in the
  same change, while the context is fresh.
- A release is one commit that bumps `plugin.json`, renames `[Unreleased]` to
  the dated version section, and adds a fresh empty `[Unreleased]`. A version
  bump without a changelog section is not a release.
- The test job validates the file on every push and pull request: it must
  exist, start with `[Unreleased]`, use only well-formed headings, contain a
  non-empty dated section for the current `plugin.json` version, and have no
  duplicate sections.
- The release job renders that section to `release-notes.md`, appends a
  compare link to the previous `vX.Y.Z` tag (or the commit list for a first
  release), and publishes it with `--notes-file`. Re-running the release
  commit re-applies the notes, so the changelog stays the source of truth.
- `scripts/publish-release-notes.sh` backfills or corrects existing releases
  by running the same render step against a plugin's changelog, so historical
  releases can be made informative without touching the workflow.
- Changelog entries describe user-visible behaviour, settings, packaging, and
  documentation changes in plain prose. They contain no commit hashes,
  pull-request numbers, conventional-commit prefixes, author names, or AI
  attribution.

## Alternatives considered

- **release-please or git-cliff.** Automatic, but the output is commit
  subjects with headings. It would also add a bot commit flow and a second
  version source next to `plugin.json`.
- **GitHub generated notes with `release.yml` categories.** Same input
  problem; squash-promoted releases still show one pull-request title.
- **Keep writing notes after the release.** This is what produced the gap; the
  workflow cannot check something that does not exist yet.

## Consequences

Releasing takes one more paragraph of writing, done at the point where the
author knows what changed. Releases can no longer be published with empty or
generated notes. Existing releases are backfilled from the new changelogs with
the publish script. The changelog format is checked, not the prose; keeping the
entries useful remains a review responsibility.

# Maintained DMS plugins

This repository bundles pinned plugin sources in `srcs` and maintains copied
tooling for the owned plugin repositories. Upstream forks retain their own
packaging conventions.

## Development builds

The canonical files in `templates/build-identity/` are copied into DankAIUsage,
DankCalendar, DankDiskUsage, DankDisplayControl, DankQuickSearch, DankSession,
DankSpotify, DankTranslate and DankVault. Each repository supplies a small
`packaging.json` selecting its installed directory and optional Go helper.

From an owned plugin checkout:

```sh
python3 scripts/package.py --output dist/dev
```

Install its `dist/dev/share/dms-plugins/<plugin>` directory in DMS, together with
`dist/dev/bin/<helper>` when present. Nix consumers call the plugin's `default.nix`
with the input revision and install the equivalent directory from the resulting
package. Helper flakes also expose the package as their default output.

Development manifests and helpers report `X.Y.Z-dev.<commit>` with `.dirty` for
modified source. Tracked manifests and release tags remain plain X.Y.Z. Manual
`--release` requires a clean checkout at the matching `vX.Y.Z` tag. A Nix release
override/output is selected explicitly from published release source.

Check copied tooling before publishing packaging changes:

```sh
bash scripts/check-build-identity.sh /path/to/plugin
bash scripts/check-plugin-ci.sh /path/to/plugin
```

The build-identity workflow checks owned plugin `dev` branches for drift and runs
their self-contained package tests. Publish synchronized plugin copies before
the corresponding aggregate template update.

## Releases and changelogs

Each owned plugin keeps a `CHANGELOG.md` (start from `templates/CHANGELOG.md`).
Features and fixes add a sentence under `[Unreleased]`; a release commit bumps
`plugin.json`, renames that section to `## [X.Y.Z] - YYYY-MM-DD`, and opens a
new empty `[Unreleased]`. The shared workflow validates the changelog on every
push and publishes the version's section as the GitHub release notes; it
refuses to release without one (ADR-003).

To republish notes for existing releases from the changelog:

```sh
bash scripts/publish-release-notes.sh DankAIUsage            # every released tag
bash scripts/publish-release-notes.sh DankAIUsage v1.2.0     # selected tags
```

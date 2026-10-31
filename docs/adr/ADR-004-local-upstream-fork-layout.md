# ADR-004: Local layout for upstream plugin forks

**Status:** Accepted
**Date:** 2026-09-27
**Updated:** 2026-10-19 (forks without commits replaced by pinned upstreams)
**History:** [replaced text](archive/ADR-004-local-upstream-fork-layout-history.md)

## Context

DankDisplayControl is an upstream fork. Keeping its local checkout among the
owned plugin clones made its ownership and the scope of aggregate maintenance
checks unclear. DankCalculator, WorldClock and DMS-Screenshot are upstream
plugins that the flake uses without a fork.

## Decision

Keep the canonical local clone of the DankDisplayControl fork in
`~/src/forks/`. An optional, Git-ignored symlink under `~/src/tools/dms-plugins/`
provides convenient access for local tooling. The symlink does not make the
fork an owned plugin.

The aggregate's owned-plugin CI and build-identity checks exclude
DankDisplayControl. They also keep excluding the DankCalculator and WorldClock
names, since a checkout under either name is an upstream plugin, not an owned
one. Automatic local workflow discovery skips symlinks, and an explicit request
to check or fix a linked fork is rejected. The flake pins DankDisplayControl's
fork as an input. Consumer QA pinning is independent of repository ownership.

The flake pins the DankCalculator, WorldClock and DMS-Screenshot upstream
repositories directly. Each input names an exact revision rather than a branch:
the daily input update would otherwise promote unreviewed third-party commits
to `main` within a day. Moving one of these inputs is a reviewed change to
`flake.nix`. The first-party `AvengeMedia/dms-plugins` input follows the same
rule: it is third-party code that the daily update would otherwise promote
unreviewed.

This decision supersedes the classification of DankDisplayControl as owned in
ADR-001 and ADR-002. Their workflow and packaging contracts still apply to the
remaining owned plugins.

## Consequences

Work on a fork happens in its standalone checkout under `~/src/forks/`, using
its own upstream conventions. Aggregate template changes do not rewrite fork
workflows or packaging files. Local symlinks are convenience paths only and are
not committed or required by CI or Nix consumers.

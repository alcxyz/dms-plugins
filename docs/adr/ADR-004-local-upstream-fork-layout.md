# ADR-004: Local layout for upstream plugin forks

**Status:** Accepted
**Date:** 2026-09-27

## Context

DankCalculator, WorldClock, and DankDisplayControl are upstream forks. Keeping
their local checkouts among the owned plugin clones made their ownership and
the scope of aggregate maintenance checks unclear. DankCalculator and WorldClock
already have canonical local clones in `~/src/forks/`.

## Decision

Keep canonical local clones of all three forks in `~/src/forks/`. Optional,
Git-ignored symlinks under `~/src/tools/dms-plugins/` provide convenient access
for local tooling. The symlinks do not make the forks owned plugins.

The aggregate's owned-plugin CI and build-identity checks exclude these forks.
Automatic local workflow discovery skips symlinks, and an explicit request to
check or fix a linked fork is rejected. The flake continues to pin each fork as
an input. Consumer QA pinning is independent of repository ownership.

This decision supersedes the classification of DankDisplayControl as owned in
ADR-001 and ADR-002. Their workflow and packaging contracts still apply to the
remaining owned plugins.

## Consequences

Work on a fork happens in its standalone checkout under `~/src/forks/`, using
its own upstream conventions. Aggregate template changes do not rewrite fork
workflows or packaging files. Local symlinks are convenience paths only and are
not committed or required by CI or Nix consumers.

# ADR-002: Shared development build identity for owned plugins

**Status:** Accepted
**Date:** 2026-09-19

## Decision

Owned plugins retain strict X.Y.Z versions in tracked plugin.json files and the
existing immutable release-tag workflow. Default build packages stamp copied
manifests with X.Y.Z-dev.<commit>, adding .dirty for local modifications. Go
helpers receive the same version. Nix source-only imports use a public-source
fingerprint; manual source archives are explicitly dev.unknown.

Copy the canonical files from templates/build-identity into each owned plugin.
A small packaging.json declares the installed directory and optional Go helper.
Manual builds use scripts/package.py; Nix builds use build-metadata.nix and
build-version.nix. Pure-QML plugins also copy the canonical default.nix. Helper
packages retain their existing dependencies and wrappers. Install plugin files
from share/dms-plugins/<directory> beside the helper, rather than raw source.

Manual release packaging requires clean Git source at the manifest's matching
vX.Y.Z tag. Nix release packaging is an explicit override/output selected from
published release source; dirty or unidentified revisions cannot produce it.
Do not guess release provenance from a commit hash or reuse a dev build as a
release. Do not create per-commit Git tags or stamp tracked release manifests.

Run scripts/check-build-identity.sh alongside the canonical workflow check.
Each plugin runs the copied packaging tests through test.sh, so forks remain
self-contained. Aggregate build-identity CI checks copies for drift after
fetching the owned plugin dev branches. Upstream forks are outside this rollout.

## Alternatives and consequences

An aggregate-only stamping layer would exclude manual installs and standalone
forks. Duplicated independent implementations would drift. Copied templates
follow ADR-001's established approach and keep source manifests unchanged.
Existing Nix consumers must use the package's stamped directory to display the
same version as the helper. Updating a source input alone is insufficient if
the consumer still installs raw plugin files.

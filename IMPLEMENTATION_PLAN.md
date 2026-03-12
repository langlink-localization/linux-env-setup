## Stage 1: Follow-Up Scope And Baseline

**Goal**: Define the second hardening slice for distro correctness and Zsh idempotency.
**Success Criteria**: Plan exists; target files and validation points are identified.
**Tests**: N/A
**Status**: Complete

## Stage 2: Tailscale Distro Correctness

**Goal**: Correct Debian-specific Tailscale repository handling and make the installer download path safer.
**Success Criteria**: Debian uses Debian repository URLs; apt repo files are written through validated temporary files instead of raw curl pipelines.
**Tests**: `make test`; targeted shell syntax checks.
**Status**: Complete

## Stage 3: Idempotent Zsh Management

**Goal**: Stop blindly overwriting `.zshrc` and switch to managed, repeatable Zsh config behavior.
**Success Criteria**: Managed `.zshrc` updates are repeatable; legacy tool-generated configs are migrated safely; custom unmanaged configs are preserved.
**Tests**: `make test`; targeted smoke coverage for managed marker handling.
**Status**: Complete

## Stage 4: Verification And Closure

**Goal**: Extend smoke tests, refresh documentation/status messaging where needed, and commit a clean follow-up diff.
**Success Criteria**: Tests pass; plan statuses updated; worktree is commit-ready.
**Tests**: `make test`; `git diff --check`.
**Status**: Complete

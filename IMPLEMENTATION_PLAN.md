## Stage 1: Review Fix Scope

**Goal**: Capture the two post-review correctness fixes before editing.
**Success Criteria**: Plan exists and the targeted edge cases are explicit.
**Tests**: N/A
**Status**: Complete

## Stage 2: Correctness Fixes

**Goal**: Fix bootstrap repo URL detection for `curl | bash` usage and ensure first-time Zsh installs still get the managed config.
**Success Criteria**: Bootstrap only trusts the local git remote when the script is running from an actual repo checkout; fresh Zsh installs do not misclassify installer-generated `.zshrc` as custom.
**Tests**: `make test`; targeted helper smoke coverage.
**Status**: Complete

## Stage 3: Verification And Closure

**Goal**: Re-run validation, sync any changed PR context, and commit a clean fixup.
**Success Criteria**: Tests pass; plan statuses updated; follow-up commit created; plan removed.
**Tests**: `make test`; `git diff --check`.
**Status**: Complete

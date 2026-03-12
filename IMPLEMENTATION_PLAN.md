## Stage 1: Open-Source Readiness Baseline

**Goal**: Establish a bounded PR-scoped plan, safer repository defaults, and a repo-specific configuration path strategy.
**Success Criteria**: Branch created; plan documented; scripts can resolve a repo-specific config path without breaking legacy configs.
**Tests**: `bash -n` on updated scripts; config path smoke checks.
**Status**: Complete

## Stage 2: Security Hardening

**Goal**: Remove unsafe privilege escalation defaults and tighten initial credential handling.
**Success Criteria**: Bootstrap no longer grants blanket passwordless sudo by default; generated password files are root-only; destructive bootstrap behavior requires confirmation.
**Tests**: `bash -n`; targeted smoke tests for config parsing and password file expectations.
**Status**: Complete

## Stage 3: Generalization And Verification

**Goal**: Make the setup flow more broadly reusable and add deterministic automated verification.
**Success Criteria**: Preferred config terminology is workspace-oriented; scripts keep backward compatibility; local test entrypoint and CI workflow exist.
**Tests**: `make test`; GitHub Actions workflow syntax review; `bash -n`.
**Status**: Complete

## Stage 4: Documentation Sync

**Goal**: Align README and repository guidance with the hardened behavior and public release expectations.
**Success Criteria**: README reflects the current config path, safer bootstrap flow, repo URL override, and security caveats.
**Tests**: Manual documentation review against implemented behavior.
**Status**: Complete

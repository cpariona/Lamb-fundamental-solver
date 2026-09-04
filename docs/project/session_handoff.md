# Integration handoff

Last reviewed: 2026-09-03

Branch: `restructure/phase-07-final-integration`
Base: `5183565`, the final Phase 6 commit. No merge or push performed.

## Review scope

- Production/test/example path ownership is explicit.
- Cross-surface benchmark tooling is test-owned, not analysis-owned.
- Active architecture/model/workflow docs supersede historical campaign plans.
- Repository checks enforce unique MATLAB names and one runner per test.
- AE independent SVD, branch-identity, convergence, and synthetic-recovery
  evidence justifies the isolated golden update `6911727` (1e-12 unchanged).
- mRLFE historical comparisons must measure a real reference, not report
  initialized zero statistics. The Phase 1 reference is `1b6b3a1`.

## Integration gate

BLOCKED: the historical mRLFE comparison detected a Phase 2 edge-guard mapping
regression (effective 4 became 8), maximum Fast delta 0.0120684309767 m/s.
An in-memory guard of 4 restores all 24 Fast cases exactly; the production
configuration has not been changed pending explicit approval. Evidence is in
`docs/validation/mrlfe_restructure_baseline.md`. All six ordinary tiers and
targeted presentation reruns passed; measured status and performance are in
`docs/repository/validation_status.md`.

After a successful gate, review the branch diff and the separate AE scientific
baseline commit. Push/merge only after explicit authorization. Keep generated
results and disposable historical reference files out of Git.

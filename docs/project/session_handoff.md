# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: `test/test-baseline-failure-diagnosis`
Base: `origin/main` at `ba7c1f2c88c34abc38ef781d5ec9c2bc184105f5`

## Completed baseline repairs

Three pre-existing runtime-audit failures were repaired one at a time.

1. AE identityA0 diagnostics were built on an 89-point internal tracking grid
   while the public result had been projected to 40 requested points. The
   wrapper now rebuilds the diagnostic through the maintained helper on exact
   requested objective-map columns. After repair, result and candidate both
   have 40 points; official validity is 23/40 and diagnostic validity 31/40.
2. The lightweight mRLFE values came from the solver state before the public
   production-core migration. Current Fast output is deterministic on an
   explicit 71-point `500:50:4000` internal grid, with accepted quality and no
   fallback. Both A0Like and S0Like selected fixtures were refreshed with a
   `1e-9 m/s` absolute tolerance.
3. The fast fitting test compared a 37-point `fitOptimized` solve to a
   141-point `numericalPreset` solve. Cross-grid RMSE is
   `0.00263863949118 m/s`; same-grid comparisons are exactly zero. The test now
   separates same-grid equivalence from cross-grid characterization.

See `docs/repository/test_baseline_failure_diagnosis.md` for Git history,
requested/internal grids, masks, quality states, full numerical differences,
and rationale for changing or preserving production code.

## Focused validation

All commands below passed on MATLAB R2024b/PCWIN64:

```matlab
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
test_lightweight_numerical_regression
test_mrlfe_fit_fast_options_quality
run_acoustoelastic_smoke_tests
run_core_smoke_tests
run_mrlfe_fit_public_solver_tests
```

The three repaired harness rows pass at commit `14501278` with one repeat and
medians of 4.2971776 s, 2.6547612 s, and 11.3965243 s. Original failure
messages remain preserved in the diagnosis and runtime-evidence documents.

## Scope preserved

- No runner membership, public wrapper, test entrypoint, folder, or file name
  changed.
- No file was removed.
- No mRLFE production code, numerical preset, profile mapping, fallback,
  quality threshold, GUI behavior, fitting workflow, or sweep behavior changed.
- No benchmark was redesigned.
- No PR was opened and nothing was merged from this branch.

## Validation not executed

The task did not run `run_all_smoke_tests`,
`test_execution_profile_validation_matrix`,
`test_mrlfe_execution_profile_benchmark_contract`,
`run_execution_profile_diagnostics_tests`, `run_fit_validation_tests`, or the
full historical AE diagnostic grid. These are broader or explicitly deferred
than the repaired contracts.

## Next-step boundaries

- Review the diagnosis before proposing registration or runner separation.
- Treat the fitting cross-grid difference as intentional route
  non-equivalence, not a tolerance target.
- Keep any benchmark redesign, runner split, or registration decision in a
  separate branch.
- Preserve the exact public commands and current no-fallback policies.

# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Baseline-repair base: `ba7c1f2c88c34abc38ef781d5ec9c2bc184105f5`
Active branch: `test/test-baseline-failure-diagnosis`

## Current development focus

The three failures discovered by the test-suite runtime audit have been
reproduced, diagnosed, and repaired independently:

- AE identityA0 diagnostic arrays now use the requested public result grid;
- the lightweight mRLFE snapshot now records the maintained deterministic
  public-fast result and makes its numerical assumptions explicit;
- fast fitting equivalence is checked only between requests with the same
  grid policy.

Detailed provenance, numerical evidence, classifications, tolerances, and
validation are in:

```text
docs/repository/test_baseline_failure_diagnosis.md
docs/repository/test_suite_runtime_evidence.md
analysis/test_inventory/test_runtime_measurements.csv
```

## Preserved architecture

- Runner membership, wrapper commands, test paths, and public APIs are
  unchanged.
- The AE production change is limited to projecting a documented diagnostic
  field onto the requested grid; official Cp, masks, branch selection, and
  solver mathematics are unchanged.
- No mRLFE production code or numerical preset changed.
- FitTool optimization remains `fitOptimized`; requested curves remain
  `numericalPreset`.
- No fallback was enabled and no quality policy was weakened.

## Validation status

MATLAB R2024b on PCWIN64:

```text
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy  passed
test_lightweight_numerical_regression                     passed
test_mrlfe_fit_fast_options_quality                       passed
run_acoustoelastic_smoke_tests                            passed
run_core_smoke_tests                                      passed
run_mrlfe_fit_public_solver_tests                         passed
```

The refreshed one-repeat harness medians at repair commit `14501278` are
4.2971776 s, 2.6547612 s, and 11.3965243 s respectively. The harness remains
in-process and provides no hard timeout.

## Deferred work

- Do not change runner registration or perform the quick/extended split in
  this branch.
- Do not redesign the mapped-to-Fast benchmark here.
- The full AE diagnostic grid, `run_all_smoke_tests`, the 36-case execution
  profile matrix, broad fitting validation, and diagnostic runners were not
  required for these focused repairs.
- Runtime evidence is descriptive for one machine and must not become a
  duration pass/fail threshold.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/test_baseline_failure_diagnosis.md`
- `docs/repository/test_suite_runtime_evidence.md`
- `docs/repository/validation_status.md`
- `docs/repository/maintained_entrypoints.md`

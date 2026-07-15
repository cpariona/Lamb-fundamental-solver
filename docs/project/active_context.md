# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Cleanup base: `0c3375ed58524e4e85088cb2775d8a0323042617` (merged test-suite audit, PR #113)
Active branch: `test/test-suite-cleanup-phase1`

## Current development focus

Test-suite cleanup phase 1 aligns all nine compatibility wrappers in active
documentation, identifies `run_main_gui_export_tests` as a standalone public
runner, corrects stale runner descriptions and the GUI runner's 17-test
counters, and moves only the three audit-approved test implementations into the
maintained layout.

The branch also adds reproducible individual-entry runtime measurement. No
runner membership, test behavior, public command, solver, GUI, fitting, sweep,
or numerical policy changed.

Primary evidence:

```text
docs/repository/test_suite_audit.md
docs/repository/test_suite_runtime_evidence.md
analysis/test_inventory/
```

## Preserved test topology

- Inventory: 137 tracked MATLAB files, 104 tests, 21 runner implementations,
  9 compatibility wrappers, and 3 helpers.
- Runner graph: 149 edges.
- `run_all_smoke_tests`: 51 statically reachable tests.
- Six tests remain without executable maintained-runner registration.
- Normalized pre/post edge and membership comparisons have zero differences.
- No file is approved for deletion.

The nine public wrappers remain:

```text
tests/run_acoustoelastic_smoke_tests.m
tests/run_all_smoke_tests.m
tests/run_core_smoke_tests.m
tests/run_gui_smoke_tests.m
tests/run_mrlfe_legacy_cleanup_tests.m
tests/run_mrlfe_production_core_tests.m
tests/run_mrlfe_public_contract_tests.m
tests/run_mrlfe_smoke_tests.m
tests/fitting/run_fit_validation_tests.m
```

`tests/run_main_gui_export_tests.m` remains a standalone public runner.

## Phase-1 layout corrections

Only these implementations moved, with unchanged MATLAB entrypoints:

```text
tests/analysis/test_sweep_plot_renderer_contract.m
  -> tests/shared/sweeps/test_sweep_plot_renderer_contract.m
tests/fitting/test_gui_prepare_experimental_fit_data.m
  -> tests/app/fitting/test_gui_prepare_experimental_fit_data.m
tests/fitting/test_gui_read_experimental_fit_file.m
  -> tests/app/fitting/test_gui_read_experimental_fit_file.m
```

`run_fit_data_import_tests` was updated atomically for its exact `runtests`
paths. The renderer remains invoked by unchanged entrypoint name.

## Runtime evidence

Twenty priority tests were measured at commit
`efe9026b6fabc556f4b439e64b9440c7e2630a41` with MATLAB R2024b on PCWIN64.
Seventeen passed and three failed; no timeout occurred. The harness is
in-process and truthfully records `HardTimeoutAvailable=false`.

Measured failures:

- `test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy`;
- `test_lightweight_numerical_regression`;
- `test_mrlfe_fit_fast_options_quality`.

The four measured mRLFE characterizations took approximately 108 to 271
seconds each and are strong extended-validation candidates. The 36-case
execution-profile matrix retains the externally supplied passing measurement of
approximately 178.7 seconds and was not rerun. The obsolete mapped-to-Fast
benchmark contract remains deferred/manual.

## Active architectural contracts

- GUI surfaces delegate to adapters and backends; model physics remains in
  model layers.
- Main GUI, SweepTool, and FitTool map Fast/Balanced/Robust directly to matching
  mRLFE numerical presets.
- FitTool optimization uses `gridPolicy = "fitOptimized"`; explicit requested
  curves use `gridPolicy = "numericalPreset"`.
- Public test-runner wrappers are compatibility entrypoints and must remain thin.
- Runtime is descriptive evidence, never a hardware-dependent pass/fail rule.
- The user performs merges manually unless explicitly requesting otherwise.

## Next development guidance

1. Review phase-1 evidence and the three baseline assertion failures.
2. Do not change runner membership on this branch.
3. Plan the quick/extended split from purpose, overlap, failure state, measured
   cost, and public-command compatibility together.
4. Keep benchmark redesign and any registration decision in separate PRs.
5. Do not delete or broadly subdivide tests without a later approved phase.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/test_suite_audit.md`
- `docs/repository/test_suite_runtime_evidence.md`
- `docs/repository/maintained_entrypoints.md`
- `docs/repository/validation_status.md`
- `tests/README.md`

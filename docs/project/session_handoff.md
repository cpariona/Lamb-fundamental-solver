# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: main

## Current state

PR #109 has been merged into `main`. The maintained mRLFE production architecture now routes Main GUI, SweepTool, and FitTool through `mrlfeSolve`.

Legacy mRLFE atlas/direct-visco production routes, route flags, fitting oracles, and obsolete route tests were removed. Historical documents may still mention those names only as pre-migration evidence.

## Completed validation

The merged implementation was validated with:

- mRLFE public-contract and production-core suites;
- Main GUI, SweepTool, and FitTool public-solver tests;
- execution-profile surface tests;
- GUI smoke tests;
- lightweight fit-grid performance characterization;
- full grid validation;
- targeted validation of marginal full-matrix cases.

The fit-optimized objective grid showed approximately 3.0x to 4.3x speedup against the Fast numerical-preset grid in the tested cases, with a worst relative phase-speed difference of 0.121% and no valid-mask differences.

The full grid matrix produced aggregate preset failures only where the dense reference was already marginal. Targeted follow-up found no accepted reference solution degraded by the candidate grids.

## Maintained FitTool behavior

```text
Run fit
  -> optimizer uses gridPolicy = fitOptimized
  -> normalized display curve interpolates objective values
  -> no automatic solver reevaluation

Evaluate fitted curve
  -> explicit forward evaluation only
  -> gridPolicy = numericalPreset
  -> selected Fast/Balanced/Robust profile
  -> no optimizer call
```

Fit-grid defaults:

```matlab
minimumPointCount = 12;
maximumPointCount = 40;
maximumStep_Hz = 250;
```

## Current maintenance task

Keep repository documentation aligned with the merged public solver architecture. Documentation-only updates may be committed directly to `main` when explicitly authorized, but should preserve maintained file paths, runner names, and strings that may be inspected by repository contract tests.

## Known limitations

- Synthetic and route tests do not constitute external physical validation.
- Quality classification can be grid-sensitive near already marginal branch tails.
- Extended grid validation is expensive and should be repeated only for material solver or grid-policy changes.
- AE IOP/HGO still uses valid atlas terminology; do not remove it when cleaning mRLFE legacy references.

## Validation guidance

For mRLFE code changes, select the relevant focused runners from:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_neutral_production_helper_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_legacy_cleanup_tests
```

For documentation-only changes:

1. preserve file paths and maintained runner names;
2. search for broken or stale references;
3. do not rerun the two-day extended grid matrix;
4. run only documentation/naming contract tests if a referenced path or maintained name changes.

## Primary references

- `docs/project/active_context.md`
- `docs/repository/validation_status.md`
- `docs/models/mrlfe/README.md`
- `docs/models/mrlfe/public_api.md`
- `docs/models/mrlfe/production_core.md`
- `docs/models/mrlfe/fitting_workflow.md`
- `docs/validation/mrlfe_grid_presets.md`
- `docs/workflows/fitting/architecture.md`

# mRLFE documentation index

This folder contains the maintained mRLFE model, fitting, sweep, and diagnostic documentation.

## Active references

| Topic | Maintained reference |
|---|---|
| Public API | `docs/models/mrlfe/public_api.md` |
| Production core | `docs/models/mrlfe/production_core.md` |
| FitTool fitting route | `docs/models/mrlfe/fitting_workflow.md` |
| Numerical grid presets and validation | `docs/validation/mrlfe_grid_presets.md` |
| Maintained sweeps | `docs/models/mrlfe/current_sweeps.md` |
| Diagnostic commands | `examples/mrlfe/diagnostics/README.md` |

## Maintained route summary

All maintained mRLFE consumers call the public production API:

```text
Main GUI  -> guiRunMRLFEModel      -> lamb.models.mrlfe.mrlfeSolve
SweepTool -> guiRunMRLFESweep      -> lamb.models.mrlfe.mrlfeSolve per point
FitTool   -> mrlfeEvaluateFitModel -> lamb.models.mrlfe.mrlfeSolve
```

Fast, Balanced, and Robust execution profiles resolve to the public `fast`, `balanced`, and `robust` numerical presets. The `dense` preset remains the maintained 10 Hz reference/diagnostic configuration.

Effective engines are `elastic_adaptive` for zero shear viscosity and `viscoelastic_adaptive` for positive shear viscosity. A0Like uses `physicalTail` termination; S0Like uses `none`; fallback is disabled.

FitTool objective evaluations use the bounded `fitOptimized` internal grid. Fit-result normalization does not call the solver again. A complete fitted curve is evaluated only through the explicit **Evaluate fitted curve** action and uses the selected numerical preset.

## Validation status

The maintained public-solver route and FitTool grid policy are covered by the focused public-contract, GUI, sweep, fitting, execution-profile, and smoke suites listed below.

The extended grid matrix completed on 2026-07-14. Cases responsible for aggregate preset failures had marginal dense references (`low_valid_fraction` or `large_relative_jump`). Targeted follow-up found no accepted reference solution that degraded under the candidate grids. See `docs/validation/mrlfe_grid_presets.md` for the maintained interpretation.

## Related tests and runners

```matlab
run_quick_contract_tests
run_quick_smoke_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

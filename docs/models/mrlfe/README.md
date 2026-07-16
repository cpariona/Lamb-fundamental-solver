# mRLFE documentation index

This folder contains the maintained mRLFE model, fitting, sweep, diagnostic, and historical cleanup documentation.

## Active references

| Topic | Maintained reference |
|---|---|
| Public API | `docs/models/mrlfe/public_api.md` |
| Production core | `docs/models/mrlfe/production_core.md` |
| FitTool fitting route | `docs/models/mrlfe/fitting_workflow.md` |
| Numerical grid presets and validation | `docs/validation/mrlfe_grid_presets.md` |
| Maintained sweeps | `docs/models/mrlfe/current_sweeps.md` |
| Diagnostic summaries | `docs/models/mrlfe/diagnostics/README.md` |
| Historical route-cleanup evidence | Git history |

## Maintained route summary

All maintained mRLFE consumers call the public production API:

```text
Main GUI  -> guiRunMRLFEModel      -> mrlfeSolve
SweepTool -> guiRunMRLFESweep      -> mrlfeSolve per point
FitTool   -> mrlfeEvaluateFitModel -> mrlfeSolve
```

Fast, Balanced, and Robust execution profiles resolve to the public `fast`, `balanced`, and `robust` numerical presets. The `dense` preset remains the maintained 10 Hz reference/diagnostic configuration.

Effective engines are `elastic_adaptive` for zero shear viscosity and `viscoelastic_adaptive` for positive shear viscosity. A0Like uses `physicalTail` termination; S0Like uses `none`; fallback is disabled.

FitTool objective evaluations use the bounded `fitOptimized` internal grid. Fit-result normalization does not call the solver again. A complete fitted curve is evaluated only through the explicit **Evaluate fitted curve** action and uses the selected numerical preset.

## Validation status

The public-solver migration and FitTool grid policy were validated before merge through focused public-contract, GUI, sweep, fitting, execution-profile, and smoke suites.

The extended grid matrix completed on 2026-07-14. Cases responsible for aggregate preset failures had marginal dense references (`low_valid_fraction` or `large_relative_jump`). Targeted follow-up found no accepted reference solution that degraded under the candidate grids. See `docs/validation/mrlfe_grid_presets.md` for the maintained interpretation.

## Historical notes

Older route-audit documents remain available in Git history as pre-migration evidence. They may mention deleted mRLFE routes and historical policy labels, but those names are not maintained entrypoints or production configuration.

Atlas terminology still used by the Acoustoelastic IOP/HGO model is unrelated to the removed mRLFE legacy routes.

## Related tests and runners

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_neutral_production_helper_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_route_integrity_tests
```

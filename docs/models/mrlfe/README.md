# mRLFE documentation index

This folder contains active mRLFE model, fitting, sweep, diagnostic, and
archived cleanup documentation.

## Active References

| Topic | Maintained reference |
|---|---|
| Public API | `docs/models/mrlfe/public_api.md` |
| Production core | `docs/models/mrlfe/production_core.md` |
| FitTool fitting route | `docs/models/mrlfe/fitting_workflow.md` |
| Dense-grid / plotting diagnostic | `docs/models/mrlfe/fittool_grid_path_sensitivity.md` |
| Maintained sweeps | `docs/models/mrlfe/current_sweeps.md` |
| Diagnostic summaries | `docs/models/mrlfe/diagnostics/README.md` |
| Legacy route cleanup inventory | `docs/validation/mrlfe_legacy_route_inventory.md` |

## Maintained Route Summary

All maintained mRLFE consumers call the public production API:

```text
Main GUI  -> guiRunMRLFEModel      -> mrlfeSolve
SweepTool -> guiRunMRLFESweep      -> mrlfeSolve per point
FitTool   -> mrlfeEvaluateFitModel -> mrlfeSolve
```

The maintained public preset is `fast`. Effective engines are
`elastic_adaptive` for zero shear viscosity and `viscoelastic_adaptive` for
positive shear viscosity. A0Like uses `physicalTail` termination; S0Like uses
`none`. Fallback is disabled.

## Historical Notes

`atlas_policy_notes.md` and older validation route-audit documents preserve
pre-migration evidence. They may mention deleted routes and historical policy
labels, but those names are not maintained entrypoints or production
configuration.

## Related Tests And Runners

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_neutral_production_helper_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_legacy_cleanup_tests
```

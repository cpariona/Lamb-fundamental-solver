# mRLFE documentation index

This folder contains active mRLFE model, fitting, sweep, diagnostic, and archived cleanup documentation.

This file is an index. It should summarize where the maintained information lives, not duplicate the full fitting, GUI, or atlas-policy contracts.

## Folder map

```text
README.md
fitting_workflow.md
fittool_grid_path_sensitivity.md
current_sweeps.md
diagnostics/
archive/
```

## Active references

| Topic | Maintained reference |
|---|---|
| FitTool fitting route | `docs/models/mrlfe/fitting_workflow.md` |
| Dense-grid / plotting diagnostic | `docs/models/mrlfe/fittool_grid_path_sensitivity.md` |
| Maintained sweeps | `docs/models/mrlfe/current_sweeps.md` |
| Diagnostic summaries | `docs/models/mrlfe/diagnostics/README.md` |
| Tracker diagnostic evidence | `docs/models/mrlfe/diagnostics/tracker_diagnostic_summary.md` |
| Atlas policy evidence | `docs/models/mrlfe/atlas_policy_notes.md` |
| GUI adapter integration | `docs/workflows/gui/mrlfe_atlas_policy_integration.md` |
| Diagnostic script inventory | `examples/mrlfe/diagnostics/README.md` |

## Current maintained route summary

The maintained FitTool fitting route is atlas-first:

```text
mrlfeFitDispersionData
  -> mrlfeBuildFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeEvaluateAtlasFitModel
  -> official mRLFE atlas branch output
```

For A0Like FitTool fitting, the current default A0 policy is:

```matlab
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

The older reference/direct workflow remains available only for explicit diagnostics with:

```matlab
solverOptions.mrlfeUseAtlasFitRoute = false;
```

## Document roles

- `fitting_workflow.md` is the active fitting-route contract.
- `fittool_grid_path_sensitivity.md` records the fit-consistent curve policy and dense solver re-evaluation diagnostic.
- `current_sweeps.md` records maintained sweep scripts and generated-output conventions.
- `docs/models/mrlfe/atlas_policy_notes.md` records atlas policy evidence and diagnostic findings.
- `docs/workflows/gui/mrlfe_atlas_policy_integration.md` records GUI-facing adapter metadata and route contracts.
- `diagnostics/` and `examples/mrlfe/diagnostics/README.md` preserve diagnostic evidence and script classification.
- `archive/` preserves historical cleanup notes only.

## Current A0 policy wording

```text
adaptivePhysicalTail  -> current FitTool A0Like fitting default
delayedCut            -> conservative comparison policy for diagnostics and sweep-policy investigations
```

Neither policy should be described as externally validated for every physical regime without additional FEM, experiment, or complex-k comparison evidence.

## Related tests and runners

```matlab
run_mrlfe_smoke_tests
run_mrlfe_atlas_tests
run_mrlfe_fit_atlas_tests
run_fit_validation_tests
```

Direct atlas focused checks:

```matlab
test_mrlfe_direct_visco_atlas_evaluator
test_mrlfe_direct_visco_atlas_modal_cut_policy
test_mrlfe_direct_visco_atlas_option_alias_contract
```

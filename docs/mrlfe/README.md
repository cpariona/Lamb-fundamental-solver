# mRLFE documentation index

This folder contains active mRLFE model, fitting, sweep, diagnostic, and archived cleanup documentation.

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

```text
docs/mrlfe/fitting_workflow.md
docs/mrlfe/fittool_grid_path_sensitivity.md
docs/mrlfe/current_sweeps.md
docs/mrlfe/diagnostics/README.md
docs/mrlfe/diagnostics/tracker_diagnostic_summary.md
docs/mrlfe_atlas_policy_notes.md
examples/mrlfe/diagnostics/README.md
```

## Fitting workflow

`fitting_workflow.md` is the current reference for mRLFE FitTool fitting routes. The maintained fitting route is atlas-first:

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

## FitTool grid/path sensitivity

`fittool_grid_path_sensitivity.md` records a known visualization diagnostic: re-evaluating the dense mRLFE solver on a plotting grid can differ from the fit-consistent values used by the objective function. The FitTool therefore keeps the primary fitted curve fit-consistent and stores dense solver re-evaluation under:

```matlab
normalized.fullCurve.denseSolver
```

## Atlas policy notes

`docs/mrlfe_atlas_policy_notes.md` records real-k atlas policy findings, including the A0 policy selector, S0 continuation route, conditional physical-tail cut, dense diagnostics, and parametric sweep results.

Current A0 policies used in diagnostics and comparisons:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

`adaptivePhysicalTail` is the current FitTool A0Like fitting default. `delayedCut` remains a conservative comparison policy in diagnostics and sweep-policy investigations.

## Sweep status

`current_sweeps.md` records the current mRLFE sweep scripts and generated-output conventions.

## Diagnostic evidence

Diagnostic documentation lives in:

```text
docs/mrlfe/diagnostics/
examples/mrlfe/diagnostics/README.md
```

Current diagnostic summary:

```text
docs/mrlfe/diagnostics/tracker_diagnostic_summary.md
```

## Archived cleanup records

Historical cleanup notes live in:

```text
docs/mrlfe/archive/
```

These records are retained for traceability. They are not active API or workflow documentation.

## Related tests

Primary mRLFE smoke entrypoint:

```matlab
run_mrlfe_smoke_tests
```

Focused atlas tests:

```matlab
run_mrlfe_atlas_tests
```

Focused FitTool atlas tests:

```matlab
run_mrlfe_fit_atlas_tests
```

Focused fitting validation:

```matlab
run_fit_validation_tests
```

Direct atlas focused checks:

```matlab
test_mrlfe_direct_visco_atlas_evaluator
test_mrlfe_direct_visco_atlas_modal_cut_policy
test_mrlfe_direct_visco_atlas_option_alias_contract
```

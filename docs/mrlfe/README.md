# mRLFE documentation index

This folder contains active mRLFE model, fitting, sweep, diagnostic, and archived cleanup documentation.

## Folder map

```text
README.md
fitting_workflow.md
current_sweeps.md
diagnostics/
archive/
```

## Active references

```text
docs/mrlfe/fitting_workflow.md
docs/mrlfe/current_sweeps.md
docs/mrlfe_atlas_policy_notes.md
examples/mrlfe/diagnostics/README.md
```

## Fitting workflow

`fitting_workflow.md` is the current reference for mRLFE fitting routes:

```text
maintained/reference-based workflow
etaS elastic-reference forward cache
direct viscous atlas evaluator
```

It also documents the direct viscous atlas naming policy:

```text
canonical option names: mrlfeA0DP*, mrlfeVisco*, mrlfeRealK*
legacy aliases:        mrlfeViscoAtlas* compatibility only
```

## Atlas policy notes

`docs/mrlfe_atlas_policy_notes.md` records the current real-k atlas policy findings, including the A0 policy selector, S0 continuation route, conditional physical tail cut, dense diagnostics, and parametric sweep results.

Current A0 policies:

```matlab
options.mrlfeA0Policy = "delayedCut";
options.mrlfeA0Policy = "adaptivePhysicalTail";
```

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
tests/run_mrlfe_atlas_tests
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

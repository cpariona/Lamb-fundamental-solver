# mRLFE documentation index

This folder contains active mRLFE model, fitting, and sweep documentation.

## Active references

```text
docs/mrlfe/fitting_workflow.md
docs/mrlfe/current_sweeps.md
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

## Sweep status

`current_sweeps.md` records the current mRLFE sweep scripts and generated-output conventions.

## Related tests

Primary mRLFE smoke entrypoint:

```matlab
run_mrlfe_smoke_tests
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

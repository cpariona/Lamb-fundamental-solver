# AE IOP/HGO model

The production entrypoint is `solveAcoustoelasticIOPHGOBranch`; defaults are
created with `defaultAcoustoelasticIOPHGOOptions`. Production uses the
`atlasA0` policy and returns canonical frequency, phase-velocity, wavenumber,
validity, and quality fields.

Maintained examples are:

```matlab
run_atlas_branch
fit_ae_atlasA0
ae_sweep_iop_A0Like
ae_sweep_mu_iop_A0Like
```

Maintained diagnostics are:

```matlab
diagnose_atlas_truncation
diagnose_branch_families
diagnose_grid_start_sensitivity
diagnose_modal_atlas
diagnose_sweep_reliability
```

Fitting is owned by `aeFitDispersionData`; 1D and 2D sweeps are owned by
`aeRunSweep` and `aeRunGridSweep`. Diagnostic algorithms do not select or
rebuild the official production result.

See `active/public_api.md`, `active/branch_policy.md`, and
`diagnostics/README.md` for the maintained contracts.

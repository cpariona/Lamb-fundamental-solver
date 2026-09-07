# AE IOP/HGO model

The production entrypoint is `lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch`; defaults are
created with `lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions`. Production uses the
`atlasA0` policy and returns canonical frequency, phase-velocity, wavenumber,
validity, and quality fields.

Maintained examples are:

```matlab
run('examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m')
run('examples/acoustoelastic_iop_hgo/fitting/fit_ae_atlasA0.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/study_iop_A0Like.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/study_mu_iop_A0Like.m')
```

Maintained diagnostics are:

```matlab
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_atlas_truncation.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_branch_families.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_grid_start_sensitivity.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_modal_atlas.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_sweep_reliability.m')
```

Fitting is owned by `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData`; 1D and 2D sweeps are owned by
`runAcoustoelasticSensitivity` and `runAcoustoelasticGridSensitivity`. Diagnostic algorithms do not select or
rebuild the official production result.

See `active/public_api.md`, `active/branch_policy.md`, and
`diagnostics/README.md` for the maintained contracts.

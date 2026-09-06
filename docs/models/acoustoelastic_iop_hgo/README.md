# AE IOP/HGO model

The production entrypoint is `lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch`; defaults are
created with `lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions`. Production uses the
`atlasA0` policy and returns canonical frequency, phase-velocity, wavenumber,
validity, and quality fields.

Maintained examples are:

```matlab
run('examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m')
run('examples/acoustoelastic_iop_hgo/fitting/fit_ae_atlasA0.m')
run('examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_iop_A0Like.m')
run('examples/acoustoelastic_iop_hgo/sweeps/ae_sweep_mu_iop_A0Like.m')
```

Maintained diagnostics are:

```matlab
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_atlas_truncation.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_branch_families.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_grid_start_sensitivity.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m')
run('examples/acoustoelastic_iop_hgo/diagnostics/diagnose_sweep_reliability.m')
```

Fitting is owned by `aeFitDispersionData`; 1D and 2D sweeps are owned by
`aeRunSweep` and `aeRunGridSweep`. Diagnostic algorithms do not select or
rebuild the official production result.

See `active/public_api.md`, `active/branch_policy.md`, and
`diagnostics/README.md` for the maintained contracts.

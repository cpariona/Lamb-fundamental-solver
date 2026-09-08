# AE IOP/HGO model

The production entrypoint is `lamb.models.acoustoelastic_iop_hgo.aeSolveBranch`; defaults are
created with `lamb.models.acoustoelastic_iop_hgo.aeDefaultOptions`. Production uses the
`atlasA0` policy and returns canonical frequency, phase-velocity, wavenumber,
validity, and quality fields.

Maintained examples are:

```matlab
run('examples/acoustoelastic_iop_hgo/basic/aeRunAtlasBranch.m')
run('examples/acoustoelastic_iop_hgo/fitting/aeFitAtlasA0.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/aeStudyIOPAtlasA0.m')
run('studies/sensitivity/acoustoelastic_iop_hgo/aeStudyMuIOPAtlasA0.m')
```

Maintained diagnostics are:

```matlab
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseAtlasTruncation.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseBranchFamilies.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseGridStartSensitivity.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseModalAtlas.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseSweepReliability.m')
```

Fitting is owned by `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData`; 1D and 2D sweeps are owned by
`aeRunSensitivity` and `aeRunGridSensitivity`. Diagnostic algorithms do not select or
rebuild the official production result.

See `public_api.md`, `branch_policy.md`, and
`diagnostics/README.md` for the maintained contracts.

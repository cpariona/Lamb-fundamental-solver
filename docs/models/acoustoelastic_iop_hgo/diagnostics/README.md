# AE IOP/HGO diagnostics

Maintained executable diagnostics are:

```matlab
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_atlas_truncation.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_branch_families.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_grid_start_sensitivity.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_modal_atlas.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/diagnose_sweep_reliability.m')
```

They characterize production atlas behavior without changing branch policy or
official results. Detailed active interpretations are retained in
`atlasA0_truncation_cause_diagnostic.md` and `branch_families_diagnostic.md`.
Completed raw-branch and identity-score investigations remain available in Git
history rather than as maintained executable or documentation surfaces.

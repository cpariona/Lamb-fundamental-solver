# AE IOP/HGO diagnostics

Maintained executable diagnostics are:

```matlab
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseAtlasTruncation.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseBranchFamilies.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseGridStartSensitivity.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseModalAtlas.m')
run('studies/solver_diagnostics/acoustoelastic_iop_hgo/aeDiagnoseSweepReliability.m')
```

They characterize production atlas behavior without changing branch policy or
official results. Detailed interpretations are retained in
`atlasA0_truncation_cause_diagnostic.md` and `branch_families_diagnostic.md`.
Completed raw-branch and identity-score investigations remain available in Git
history rather than as maintained executable or documentation surfaces.

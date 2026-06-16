### identityA0 physical plausibility diagnostic

This diagnostic inspects `identityA0Diagnostic` candidate curves for visual and physical plausibility.

It consumes the workspace produced by:

```matlab
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
```

and does not rerun the solver.

### Runnable script

```matlab
cd('E:\')
startup
diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility
AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilityAggregate
```

Expected input:

`Results/acoustoelastic_iop_hgo_identityA0_diagnostic_grid/acoustoelastic_iop_hgo_identityA0_diagnostic_grid_workspace.mat`

Outputs are written under:

`Results/acoustoelastic_iop_hgo_identityA0_physical_plausibility`

### Output files

The script writes:

- `acoustoelastic_iop_hgo_identityA0_physical_plausibility_summary.csv`
- `acoustoelastic_iop_hgo_identityA0_physical_plausibility_aggregate.csv`
- `acoustoelastic_iop_hgo_identityA0_physical_plausibility_workspace.mat`
- plots under `plots/`

Workspace variables:

- `AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilitySummary`
- `AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilityAggregate`
- `AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilityOutputFolder`

### Metrics

For each candidate curve, the diagnostic computes:

- official valid fraction;
- candidate valid fraction;
- valid-fraction gain;
- added candidate points;
- whether the candidate reaches the final frequency;
- maximum relative jump between adjacent valid points;
- maximum relative downward drop;
- number of large jumps;
- number of large drops;
- number of slope sign changes;
- roughness based on second differences;
- high-frequency relative slope;
- high-frequency variation;
- median score and rank of added candidate points.

### Plausibility classes

The script assigns one of:

- `plausible_full_extension`
- `plausible_partial_extension`
- `caution_oscillatory_branch`
- `caution_large_jumps`
- `caution_large_high_frequency_drop`
- `poor_coverage_manual_inspection`

These are diagnostic labels, not production branch labels.

### Interpretation

The goal is to distinguish three situations:

1. A candidate branch is smooth, reaches the final frequency, and is plausible enough for plotting and further validation.
2. A candidate branch improves coverage but remains incomplete or rough, so it should remain a caution case.
3. A candidate branch is too incomplete, jumpy, or oscillatory, suggesting either severe numerical ambiguity or absence of a physically meaningful traceable branch in that regime.

### Physical prior

The diagnostic uses the high-frequency expectation only as a soft plausibility check. Lamb-like branches often become slowly varying or approach an asymptotic behavior when wavelength becomes small relative to thickness. However, leakage, fluid loading, curvature, prestress, anisotropy, and nonlinear material behavior can change this pattern.

Therefore, the diagnostic penalizes abrupt drops and oscillations but does not force monotonicity or saturation.

### Recommended decision rule

Keep `atlasA0` as the official conservative output.

Use `identityA0Diagnostic` for plotting and branch-inspection only when the plausibility class is:

- `plausible_full_extension`, or
- `plausible_partial_extension` with manual review.

Do not promote candidates classified as:

- `poor_coverage_manual_inspection`,
- `caution_large_jumps`,
- `caution_large_high_frequency_drop`, or
- `caution_oscillatory_branch`.

For those cases, the practical conclusion may be that the branch is not distinguishable with the current real-Cp residual landscape and atlas strategy.

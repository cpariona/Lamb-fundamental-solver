### identityA0 physical plausibility diagnostic

This diagnostic inspects `identityA0Diagnostic` candidate curves for visual and physical plausibility.

It consumes the workspace produced by:

```matlab
validate_idA0_grid
```

or the legacy descriptive entrypoint:

```matlab
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
```

and does not rerun the solver.

### Runnable script

Use the short MATLAB-compatible entrypoint:

```matlab
cd('E:\')
startup
diagnose_idA0_plausibility
AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilityAggregate
```

`diagnose_identityA0_plausibility` is also available as a maintained wrapper. The longer descriptive script filename exceeds MATLAB's 63-character name limit and should not be called directly.

Preferred input:

```text
Results/ae_iop_hgo/idA0_grid/idA0_grid_workspace.mat
```

Legacy fallback input:

```text
Results/acoustoelastic_iop_hgo_identityA0_diagnostic_grid/acoustoelastic_iop_hgo_identityA0_diagnostic_grid_workspace.mat
```

Outputs are written under:

```text
Results/ae_iop_hgo/idA0_plausibility
```

### Output files

The script writes:

- `idA0_plausibility_summary.csv`
- `idA0_plausibility_aggregate.csv`
- `idA0_plausibility_workspace.mat`
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

### Validation result

The first 110-case plausibility validation produced:

| Class | Cases | Reaches final frequency | Median candidate valid fraction | Median valid-fraction gain | Median added rank |
|---|---:|---:|---:|---:|---:|
| `plausible_full_extension` | 54 | 54 | 1.0000 | 0.0000 | 18.5 |
| `plausible_partial_extension` | 25 | 0 | 0.9333 | 0.0583 | 29.0 |
| `poor_coverage_manual_inspection` | 26 | 0 | 0.7583 | 0.0667 | 41.0 |
| `caution_oscillatory_branch` | 5 | 2 | 0.9583 | 0.0583 | 25.0 |

No cases were classified as `caution_large_jumps` or `caution_large_high_frequency_drop` under the current thresholds. The main unresolved mechanism is insufficient candidate coverage, not gross discontinuity.

### Parameter trend

By shear modulus:

| mu [kPa] | `plausible_full_extension` | `plausible_partial_extension` | `poor_coverage_manual_inspection` | `caution_oscillatory_branch` | Median candidate valid fraction |
|---:|---:|---:|---:|---:|---:|
| 25 | 0 | 9 | 23 | 4 | 0.7958 |
| 50 | 18 | 16 | 3 | 1 | 0.9833 |
| 100 | 36 | 0 | 0 | 0 | 1.0000 |

By IOP:

| IOP [mmHg] | `plausible_full_extension` | `plausible_partial_extension` | `poor_coverage_manual_inspection` | `caution_oscillatory_branch` | Median candidate valid fraction |
|---:|---:|---:|---:|---:|---:|
| 5 | 18 | 7 | 0 | 2 | 1.0000 |
| 15 | 16 | 4 | 5 | 2 | 1.0000 |
| 25 | 11 | 9 | 9 | 0 | 0.9500 |
| 35 | 9 | 5 | 12 | 1 | 0.8833 |

The hard regime is low shear modulus and high IOP, especially `mu = 25 kPa` with `IOP = 25-35 mmHg`.

Worst observed case:

```text
iop_25mmHg_mu_25kPa_k1_50kPa_k2_100_h_550um
```

with:

```text
CandidateValidFraction = 0.1667
AddedCandidatePoints = 7
MedianAddedRank = 44
```

This should be treated as non-traceable with the current real-Cp atlas/identity-score strategy.

### Interpretation

The goal is to distinguish three situations:

1. A candidate branch is smooth, reaches the final frequency, and is plausible enough for plotting and further validation.
2. A candidate branch improves coverage but remains incomplete or rough, so it should remain a caution case.
3. A candidate branch is too incomplete, jumpy, or oscillatory, suggesting either severe numerical ambiguity or absence of a physically meaningful traceable branch in that regime.

For this validation set, `identityA0Diagnostic` is useful but should remain diagnostic. It gives full plausible extension in 54/110 cases and partial plausible extension in 25/110 cases. The remaining cases should not be forced into continuous curves by adding more local heuristics.

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

For those cases, the practical conclusion may be that the branch is not distinguishable with the current real-Cp residual landscape and atlas strategy. Further recovery attempts should use a different formulation, such as complex phase velocity, mode-shape/energy continuity, or a physical admissibility constraint, not another local-minimum heuristic.

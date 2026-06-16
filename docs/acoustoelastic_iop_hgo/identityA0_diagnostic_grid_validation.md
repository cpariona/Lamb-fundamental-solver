### identityA0Diagnostic grid validation

This diagnostic validates the optional `identityA0Diagnostic` policy over the same 110-case grid used for branch-identity score validation.

It is stricter than the score-only grid because it runs both policies:

```matlab
options.atlasBranchPolicy = "atlasA0";
options.atlasBranchPolicy = "identityA0Diagnostic";
```

and checks that the official fields are identical:

```matlab
resultAtlas.Cp == resultIdentity.Cp
resultAtlas.validCp == resultIdentity.validCp
```

If either official field changes, the script throws an error.

### Runnable script

`validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid`

Run from the desired output root:

```matlab
cd('E:\')
startup
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
AcoustoelasticIOPHGOIdentityA0DiagnosticGridAggregate
```

Outputs are written under:

`Results/acoustoelastic_iop_hgo_identityA0_diagnostic_grid`

### Grid definition

The main grid uses:

```matlab
IOP_mmHg = [5, 15, 25, 35];
mu_kPa = [25, 50, 100];
k1_kPa = [10, 25, 50];
k2 = [50, 100, 200];
thickness_um = 550;
```

This gives 108 material/IOP cases.

A small thickness probe is also included:

```matlab
IOP_mmHg = 25;
mu_kPa = 50;
k1_kPa = 25;
k2 = 100;
thickness_um = [450, 650];
```

Total cases: 110.

### Output tables

The script writes:

- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_summary.csv`
- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_added_candidates.csv`
- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_aggregate.csv`
- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_workspace.mat`

Workspace variables:

- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridSummary`
- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridAddedCandidates`
- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridAggregate`
- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridOutputFolder`

### Main metrics

Per case, the summary table reports:

- official valid points;
- candidate valid points;
- added diagnostic candidate points;
- official valid fraction;
- candidate valid fraction;
- valid-fraction gain;
- first official missing frequency;
- first candidate missing frequency;
- last official valid frequency;
- last candidate valid frequency;
- median score and rank of added candidate points;
- whether the official branch was truncated;
- whether the diagnostic candidate extends the official branch;
- whether the diagnostic candidate reaches the final frequency.

The aggregate table reports:

- number of cases;
- number of officially truncated cases;
- number of cases where `identityA0Diagnostic` extends the official branch;
- truncated cases extended and not extended;
- number of candidates reaching the final frequency;
- median official and candidate valid fractions;
- median valid-fraction gain;
- median number of added points;
- median score and rank of added points.

### Validation result

The first 110-case validation confirms that `identityA0Diagnostic` preserves the official fields while adding separate diagnostic candidates.

| Group | Cases | Officially truncated | Candidate extends official | Truncated extended | Truncated not extended | Candidate reaches final frequency | Median official valid fraction | Median candidate valid fraction | Median gain | Median added points | Median added score | Median added rank |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `material_iop_core` | 108 | 67 | 67 | 67 | 0 | 56 | 0.9458 | 0.9958 | 0.0417 | 5 | 1.7685 | 30.0 |
| `thickness_probe` | 2 | 2 | 2 | 2 | 0 | 0 | 0.8708 | 0.9292 | 0.0583 | 7 | 1.7847 | 41.0 |
| `all` | 110 | 69 | 69 | 69 | 0 | 56 | 0.9417 | 0.9917 | 0.0417 | 5 | 1.7685 | 30.0 |

Interpretation:

- The official atlas fields were preserved for all 110 cases.
- All 69 officially truncated cases were extended by `identityA0Diagnostic`.
- No truncated case failed to receive a diagnostic extension.
- The median valid fraction increased from 0.9417 to 0.9917 across all cases.
- 56 cases reached the final frequency after applying the diagnostic candidate branch.
- The diagnostic candidate still does not fully fix all difficult cases, especially the low-`mu` and high-IOP regimes.

### Parameter trends

By IOP:

| IOP [mmHg] | Cases | Truncated | Extended | Reaches final | Median official valid fraction | Median candidate valid fraction | Median gain | Median added points | Median added score | Median added rank |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 5 | 27 | 12 | 12 | 20 | 1.0000 | 1.0000 | 0.0000 | 0 | 1.5122 | 12.75 |
| 15 | 27 | 15 | 15 | 16 | 0.9583 | 1.0000 | 0.0417 | 5 | 1.7568 | 29.00 |
| 25 | 29 | 20 | 20 | 11 | 0.8917 | 0.9500 | 0.0583 | 7 | 1.8449 | 39.00 |
| 35 | 27 | 22 | 22 | 9 | 0.8167 | 0.8833 | 0.0583 | 7 | 1.8162 | 38.50 |

By shear modulus:

| mu [kPa] | Cases | Truncated | Extended | Reaches final | Median official valid fraction | Median candidate valid fraction | Median gain | Median added points | Median added score | Median added rank |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 25 | 36 | 36 | 36 | 2 | 0.7250 | 0.7958 | 0.0667 | 8 | 1.8527 | 31.00 |
| 50 | 38 | 29 | 29 | 18 | 0.9167 | 0.9833 | 0.0583 | 7 | 1.7084 | 29.00 |
| 100 | 36 | 4 | 4 | 36 | 1.0000 | 1.0000 | 0.0000 | 0 | 1.6648 | 23.25 |

Hardest observed cases remain low shear modulus and high IOP. In the most difficult cases, the diagnostic candidate adds points but may still leave a low candidate valid fraction; therefore, these cases should remain flagged for manual/physical inspection.

### Interpretation

This validation answers:

> Does `identityA0Diagnostic` preserve official atlas output while adding a useful separate candidate branch?

For this first grid, the answer is yes. It preserved the official output and extended every officially truncated case.

Possible outcomes:

- If official fields are preserved and most truncated cases are extended, the policy is useful for diagnostic plotting and inspection.
- If official fields change, the implementation is invalid.
- If many truncated cases are not extended, the score is not sufficiently useful as a diagnostic branch builder.

### Safety rule

The policy is still diagnostic. Even if `result.identityA0.CpCandidate` improves coverage, production analyses should continue to use:

```matlab
result.Cp
result.validCp
```

unless a later validation explicitly promotes the identity-scored branch.

The next step should be a visual/physical plausibility diagnostic comparing official and identity candidate curves, especially in low-`mu` / high-IOP cases where the candidate still does not reach the final frequency.

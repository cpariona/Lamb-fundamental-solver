### Branch-identity score grid validation

This diagnostic validates the branch-identity score over a moderate parameter grid before considering any new optional branch policy.

It is diagnostic only. It does not modify:

- `result.Cp`
- `result.validCp`
- `options.atlasBranchPolicy`

The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Runnable script

Use the short entrypoint:

```matlab
cd('E:\')
startup
validate_idA0_score_grid
AcoustoelasticIOPHGOBranchIdentityScoreGridAggregate
```

The legacy descriptive implementation remains available:

```matlab
validate_acoustoelastic_iop_hgo_branch_identity_score_grid
```

The script writes outputs under:

```text
Results/ae_iop_hgo/idA0_score_grid
```

Legacy output folders from earlier runs may still exist under:

```text
Results/acoustoelastic_iop_hgo_branch_identity_score_grid
```

### Grid definition

The main grid uses:

```matlab
IOP_mmHg = [5, 15, 25, 35];
mu_kPa = [25, 50, 100];
k1_kPa = [10, 25, 50];
k2 = [50, 100, 200];
thickness_um = 550;
```

This gives 108 material/IOP combinations.

A small thickness probe is also included:

```matlab
IOP_mmHg = 25;
mu_kPa = 50;
k1_kPa = 25;
k2 = 100;
thickness_um = [450, 650];
```

Total cases: 110.

### Fixed solver settings

The diagnostic uses the current conservative official branch policy:

```matlab
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 1000;
options.atlasTopNMinima = 18;
```

The branch-identity score then analyzes the resulting official solver output and the objective-map minima. It does not rewrite the official output.

### Output tables

The short-path script writes:

- `idA0_score_grid_summary.csv`
- `idA0_score_grid_best_candidates.csv`
- `idA0_score_grid_aggregate.csv`
- `idA0_score_grid_workspace.mat`

Workspace variables:

- `AcoustoelasticIOPHGOBranchIdentityScoreGridSummary`
- `AcoustoelasticIOPHGOBranchIdentityScoreGridBestCandidates`
- `AcoustoelasticIOPHGOBranchIdentityScoreGridAggregate`
- `AcoustoelasticIOPHGOBranchIdentityScoreGridOutputFolder`

### Main validation metrics

The grid summary reports, per case:

- official valid fraction;
- last official valid frequency;
- first terminal missing frequency;
- internal-gap flag;
- number of diagnostic candidates;
- number of strong and caution diagnostic candidates;
- median best score;
- median best rank;
- median best relative Cp distance;
- median crowding;
- whether the official branch is terminally truncated;
- whether the score finds at least one plausible candidate.

The aggregate table reports:

- number of cases;
- number of officially truncated cases;
- number of cases where the score finds a candidate;
- truncated cases with and without candidates;
- median valid fraction;
- median score/rank/distance/crowding.

### Validation result

The first 110-case grid validation produced the following aggregate result:

| Group | Cases | Officially truncated | Score finds candidate | Truncated with candidate | Truncated without candidate | Median valid fraction | Median best score | Median best rank | Median best relative distance | Median best crowding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `material_iop_core` | 108 | 66 | 108 | 66 | 0 | 0.9458 | 1.4007 | 11.0 | 0.00649 | 2.0 |
| `thickness_probe` | 2 | 2 | 2 | 2 | 0 | 0.8708 | 1.5016 | 17.5 | 0.00651 | 2.5 |
| `all` | 110 | 68 | 110 | 68 | 0 | 0.9417 | 1.4007 | 11.5 | 0.00649 | 2.0 |

Important interpretation:

- `Score finds candidate = 110` includes non-truncated cases, because the score is also computed around the last valid region even when `atlasA0` reaches the final frequency.
- The meaningful diagnostic result is `Truncated with candidate = 68` and `Truncated without candidate = 0`.
- Every officially truncated case in this grid had at least one strong or caution branch-identity candidate.

### Parameter trends

The grid shows the expected degradation in official `atlasA0` coverage as IOP increases and as the shear modulus decreases.

By IOP:

| IOP [mmHg] | Cases | Truncated | Median valid fraction | Median score | Median rank | Median relative distance |
|---:|---:|---:|---:|---:|---:|---:|
| 5 | 27 | 12 | 1.0000 | 0.7927 | 3.0 | 0.0000 |
| 15 | 27 | 15 | 0.9583 | 1.2382 | 11.0 | 0.00649 |
| 25 | 29 | 20 | 0.8917 | 1.6010 | 22.0 | 0.00653 |
| 35 | 27 | 21 | 0.8167 | 1.6713 | 23.0 | 0.00653 |

By shear modulus:

| mu [kPa] | Cases | Truncated | Median valid fraction | Median score | Median rank | Median relative distance |
|---:|---:|---:|---:|---:|---:|---:|
| 25 | 36 | 36 | 0.7250 | 1.6878 | 26.0 | 0.00653 |
| 50 | 38 | 29 | 0.9167 | 1.4495 | 15.0 | 0.00651 |
| 100 | 36 | 3 | 1.0000 | 0.7727 | 2.0 | 0.0000 |

The hardest regimes are low shear modulus and high IOP. Some extreme cases have strong internal gaps or very low official valid fraction, so they should remain caution cases even when the score finds candidates.

### Interpretation

This grid answers a specific question:

> When `atlasA0` becomes truncated, does the branch-identity score usually find a locally plausible continuation candidate?

For this 110-case grid, the answer is yes: all 68 officially truncated cases had at least one strong or caution candidate.

Possible outcomes:

- If most truncated cases have strong/caution candidates, the next step is to implement a new optional diagnostic branch policy.
- If many truncated cases have no candidate, the score is not sufficiently general.
- If candidates appear only in narrow parameter regions, the score may be useful as a diagnostic flag but not as a production branch policy.

### Promotion rule

Do not promote this score to production until its candidate branches are checked for physical plausibility and continuity over full branches, not only pointwise local windows. In particular, high-frequency behavior should be treated as a soft prior, not a hard monotonicity or saturation constraint.

The next implementation step should be an optional diagnostic policy, not a replacement of `atlasA0`, for example `identityA0Diagnostic`, that writes a separate candidate branch while preserving the official fields.

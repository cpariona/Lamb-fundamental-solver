### Branch-identity score grid validation

This diagnostic validates the branch-identity score over a moderate parameter grid before considering any new optional branch policy.

It is diagnostic only. It does not modify:

- `result.Cp`
- `result.validCp`
- `options.atlasBranchPolicy`

The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Runnable script

`validate_acoustoelastic_iop_hgo_branch_identity_score_grid`

Run from the desired output root, for example:

```matlab
cd('E:\')
startup
validate_acoustoelastic_iop_hgo_branch_identity_score_grid
AcoustoelasticIOPHGOBranchIdentityScoreGridAggregate
```

The script writes outputs under:

`Results/acoustoelastic_iop_hgo_branch_identity_score_grid`

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

The script writes:

- `acoustoelastic_iop_hgo_branch_identity_score_grid_summary.csv`
- `acoustoelastic_iop_hgo_branch_identity_score_grid_best_candidates.csv`
- `acoustoelastic_iop_hgo_branch_identity_score_grid_aggregate.csv`
- `acoustoelastic_iop_hgo_branch_identity_score_grid_workspace.mat`

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

### Interpretation

This grid answers a specific question:

> When `atlasA0` becomes truncated, does the branch-identity score usually find a locally plausible continuation candidate?

Possible outcomes:

- If most truncated cases have strong/caution candidates, the next step is to implement a new optional diagnostic branch policy.
- If many truncated cases have no candidate, the score is not sufficiently general.
- If candidates appear only in narrow parameter regions, the score may be useful as a diagnostic flag but not as a production branch policy.

### Promotion rule

Do not promote this score to production until it passes a broader validation and its candidate branches are checked for physical plausibility. In particular, high-frequency behavior should be treated as a soft prior, not a hard monotonicity or saturation constraint.

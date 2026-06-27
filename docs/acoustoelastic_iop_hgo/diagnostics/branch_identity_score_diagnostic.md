### Branch-identity score diagnostic

This diagnostic scores local minima near atlasA0 terminal failures using a soft branch-identity criterion.

It is diagnostic only. It does not modify:

- `result.Cp`
- `result.validCp`
- `options.atlasBranchPolicy`

The maintained official policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Motivation

The failure-landscape diagnostic showed that `iop_25mmHg` and `mu_25kPa` do not fail because no nearby minimum exists. Instead, many minima crowd the continuation neighborhood, and the minimum closest to the previous branch often has low rank.

Therefore, a candidate should not be judged only by objective rank or by the deepest minimum. It should be scored by branch identity.

### Main helper

`analysis/acoustoelastic_iop_hgo/aeScoreBranchIdentityCandidates.m`

The helper returns:

- `score.summary`
- `score.candidateTable`

By default, it recomputes deeper local minima from `result.objectiveMap` using:

`DeepMinimaTopN = 80`

This is important because the production atlas may retain only `atlasTopNMinima = 18`, while the continuation-like minimum can appear at rank 25-35 in crowded landscapes.

### Runnable script

Use the short entrypoint:

`diagnose_idA0_score`

Legacy descriptive implementation:

`diagnose_acoustoelastic_iop_hgo_branch_identity_score`

The script analyzes:

- `iop_25mmHg`
- `mu_25kPa`

Preferred output folder:

`Results/ae_iop_hgo/idA0_score`

Legacy output folder from earlier runs may still exist under:

`Results/acoustoelastic_iop_hgo_branch_identity_score`

### Score components

The diagnostic score combines:

- relative Cp distance to the previous valid branch point;
- slope mismatch against the recent valid branch trend;
- local-minimum rank penalty;
- objective-depth penalty relative to the deepest local minimum;
- crowding penalty within a 5% Cp neighborhood;
- high-frequency drop penalty;
- high-frequency oscillation penalty.

The high-frequency physics prior is soft. It penalizes abrupt drops or slope reversals but does not force monotonic growth or saturation.

### Candidate classes

The score assigns each candidate to one of:

- `strong_diagnostic_candidate`
- `caution_diagnostic_candidate`
- `not_recommended`

These classes are not production branch labels. They are evidence for later tracker design.

### Output tables

The short-path script writes:

- `<case>_candidates.csv`
- `<case>_summary.csv`
- `idA0_score_summary.csv`
- `idA0_score_workspace.mat`

It also writes plots under:

`Results/ae_iop_hgo/idA0_score/plots`

### Validation command

Run from the desired output root, for example `E:\`:

```matlab
cd('E:\')
startup
diagnose_idA0_score
AcoustoelasticIOPHGOBranchIdentityScoreSummary
```

### Validation snapshot

The first validation workspace produced plausible diagnostic candidates for both unresolved cases.

| Case | Last official valid [kHz] | First terminal missing [kHz] | Best-frequency candidates | Strong candidates | Caution candidates | Median best score | Median best rank | Median best relative Cp distance | Median best crowding |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `iop_25mmHg` | 15.9224 | 16.7258 | 13 | 9 | 4 | 1.3504 | 18.0 | 0.00653 | 3.0 |
| `mu_25kPa` | 9.2649 | 9.7324 | 13 | 8 | 5 | 1.3621 | 16.0 | 0.00653 | 1.0 |

Interpretation:

- The branch-identity score finds locally plausible candidates for both cases.
- The selected best candidates are close to the previous valid Cp, with median relative distance near 0.65%.
- The median rank is lower than in the focused failure-landscape table because this helper recomputes deeper minima from the stored objective map and scores candidates by continuity, not by nearest-only rank.
- This supports the idea that a physically and numerically informed continuation is possible, but it remains diagnostic evidence only.

### Interpretation policy

A low diagnostic score means that a candidate is locally plausible under the chosen score. It does not mean the candidate should replace `atlasA0`.

Before promotion to production, the score must be validated over a wider parameter grid and compared against known physical expectations for Lamb-like high-frequency behavior.

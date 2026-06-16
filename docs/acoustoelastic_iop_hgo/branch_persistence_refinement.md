### Branch-persistence refinement for atlasA0

This diagnostic layer evaluates whether the maintained `atlasA0` branch has locally defensible continuation candidates after high-frequency truncation.

The maintained solver output remains unchanged:

- `result.Cp`
- `result.validCp`

The refinement is returned separately:

- `refinement.CpCandidate`
- `refinement.validCandidate`
- `refinement.candidateMode`
- `refinement.analysis`
- `refinement.classification`
- `refinement.summary`

The candidate branch is diagnostic only. It must not automatically replace `result.Cp`.

### Result-location policy

Sweep and diagnostic scripts should be launched from the folder where the user wants the `Results` directory to be created. For example, if MATLAB is currently in `E:\`, outputs are written under:

`E:\Results\...`

The repository only needs to be on the MATLAB path through `startup`; results do not need to be stored inside the repository checkout.

The branch-persistence diagnostic captures the launch folder before calling `startup` and then writes under:

`fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_branch_persistence_refinement')`

### Intended use

Run this diagnostic after generating the IOP and shear-modulus sweeps from the same launch folder:

- `sweep_acoustoelastic_iop_hgo_iop`
- `sweep_acoustoelastic_iop_hgo_mu`
- `diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement`

### Classification

The diagnostic classification uses:

- `not_recommended`
- `weak_partial_extension`
- `caution_low_rank_branch`
- `accepted_contiguous_extension`

The classification order is conservative:

1. no accepted continuation is `not_recommended`;
2. very short, low-bandwidth, or non-contiguous continuation is `weak_partial_extension`;
3. sufficiently long continuation with low-rank or weak minima is `caution_low_rank_branch`;
4. sufficiently long continuation supported only by strong minima is `accepted_contiguous_extension`.

These classes are reporting labels only. The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

### Validation snapshot

The current validation snapshot uses the maintained `atlasA0` output and the branch-persistence diagnostic. The candidate branch remains separate from the official branch.

| Case | Official valid points | Added diagnostic points | Extension [kHz] | Median accepted rank | Classification | Interpretation |
|---|---:|---:|---:|---:|---|---|
| `iop_20mmHg` | 107 | 7 | 16.544 | 6 | `caution_low_rank_branch` | Long continuation exists, but accepted minima are not consistently strong. Use as diagnostic evidence only. |
| `iop_25mmHg` | 104 | 1 | 0.803 | 4 | `weak_partial_extension` | Only one local continuation point is accepted. This is not enough to support a branch extension. |
| `mu_25kPa` | 92 | 0 | 0 | NaN | `not_recommended` | No accepted continuation survives the persistence gates. Keep high-frequency values as `NaN`. |

The validation supports keeping `atlasA0` as the maintained conservative result while exposing `CpCandidate` only for diagnostics.

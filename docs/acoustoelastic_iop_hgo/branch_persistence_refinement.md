### Branch-persistence refinement for atlasA0

This document records the historical branch-persistence refinement diagnostic used during `atlasA0` validation.

The executable diagnostic entrypoints were removed from the maintained examples tree after the conservative `atlasA0` policy was established. The reusable helper layer remains available and tested:

```matlab
aeAnalyzeBranchPersistenceCandidates
aeRefineAtlasA0BranchPersistence
```

The maintained solver output remains unchanged:

- `result.Cp`
- `result.validCp`

The refinement candidate is diagnostic only and remains separate from official solver output:

- `refinement.CpCandidate`
- `refinement.validCandidate`
- `refinement.candidateMode`
- `refinement.analysis`
- `refinement.classification`
- `refinement.summary`

The candidate branch must not automatically replace `result.Cp`.

### Historical result-location policy

Historical runs of the removed diagnostic wrote to:

```text
Results/ae_iop_hgo/branch_persistence
```

Short-path output files were:

```text
branch_persistence_summary.csv
branch_persistence_workspace.mat
<case>_summary.csv
<case>_candidates.csv
```

Legacy output folders from earlier runs may also exist under:

```text
Results/acoustoelastic_iop_hgo_branch_persistence_refinement
```

These folders are retained only as historical output locations. New routine workflows should not depend on them.

### Historical classification

The diagnostic classification used:

- `not_recommended`
- `weak_partial_extension`
- `caution_low_rank_branch`
- `accepted_contiguous_extension`

The classification order was conservative:

1. no accepted continuation is `not_recommended`;
2. very short, low-bandwidth, or non-contiguous continuation is `weak_partial_extension`;
3. sufficiently long continuation with low-rank or weak minima is `caution_low_rank_branch`;
4. sufficiently long continuation supported only by strong minima is `accepted_contiguous_extension`.

These classes are reporting labels only. The official branch policy remains:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

### Validation snapshot

The validation snapshot used the maintained `atlasA0` output and the branch-persistence diagnostic. The candidate branch remained separate from the official branch.

| Case | Official valid points | Added diagnostic points | Extension [kHz] | Median accepted rank | Classification | Interpretation |
|---|---:|---:|---:|---:|---|---|
| `iop_20mmHg` | 107 | 7 | 16.544 | 6 | `caution_low_rank_branch` | Long continuation exists, but accepted minima are not consistently strong. Use as diagnostic evidence only. |
| `iop_25mmHg` | 104 | 1 | 0.803 | 4 | `weak_partial_extension` | Only one local continuation point is accepted. This is not enough to support a branch extension. |
| `mu_25kPa` | 92 | 0 | 0 | NaN | `not_recommended` | No accepted continuation survives the persistence gates. Keep high-frequency values as `NaN`. |

The validation supports keeping `atlasA0` as the maintained conservative result while exposing persistence candidates only as diagnostic evidence.

### Current executable status

The historical scripts:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_branch_persistence.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement.m
```

were removed from the maintained examples tree.

The helper behavior remains covered by:

```matlab
test_acoustoelastic_iop_hgo_branch_persistence_refinement
```

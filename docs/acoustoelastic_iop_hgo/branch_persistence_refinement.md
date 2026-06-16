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

### Intended use

Run this diagnostic after generating the IOP and shear-modulus sweeps:

- `sweep_acoustoelastic_iop_hgo_iop`
- `sweep_acoustoelastic_iop_hgo_mu`
- `diagnose_acoustoelastic_iop_hgo_branch_persistence_refinement`

Outputs are written under:

`fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_branch_persistence_refinement')`

### Classification

The diagnostic classification uses:

- `not_recommended`
- `caution_low_rank_branch`
- `weak_partial_extension`
- `accepted_contiguous_extension`

These classes are reporting labels only. The official branch policy remains:

`options.atlasBranchPolicy = "atlasA0";`

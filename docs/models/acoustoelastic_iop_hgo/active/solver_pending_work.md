# Acoustoelastic IOP/HGO solver pending work

This document records bounded solver-side work that must remain separate from
GUI and repository-hygiene tasks.

## Current status

The maintained production branch policy remains:

```text
atlasA0 = conservative official output
```

The IOP/HGO wrapper separates:

```text
internal atlas tracking grid
requested output frequency grid
```

The previously reported high-frequency waviness in `Cp(f)` has been resolved by
replacing the former sub-grid candidate interpolation stage with continuous
refinement of the already selected atlas branch.

## Final numerical pipeline

The maintained atlas workflow is now:

```text
1. Evaluate log10(sigma_min(M)) on the discrete atlas frequency-velocity grid.
2. Detect local candidate minima strictly on cGrid.
3. Link the discrete candidates into branches.
4. Select the maintained A0 branch with the atlasA0 policy.
5. Refine only the explicit points of the selected branch by minimizing the true
   SVD objective in log(Cp) between neighboring cGrid samples.
6. Assign the refined branch to the requested output frequencies and interpolate
   only across gaps allowed by the existing policy.
```

Candidate discovery, branch metrics, branch linking, and branch selection remain
based on the discrete atlas. Continuous minimization cannot alter candidate
ranking or branch identity because it occurs only after A0 selection.

The refinement implementation is owned by:

```text
models/acoustoelastic_iop_hgo/tracking/aeRefineSelectedAtlasBranch.m
```

and is invoked from:

```text
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m
```

## Configuration contract

The final continuous-refinement stage is controlled by:

```text
refineLocalMinima
selectedBranchRefinementTolLogCp
selectedBranchRefinementMaxFunEvals
selectedBranchRefinementMaxIter
```

`refineLocalMinima=false` disables continuous refinement and preserves a fully
discrete official branch on `cGrid`. The candidate table remains discrete in
both configurations.

## Validation evidence

For the representative 1-15 kHz case used during development:

```text
- all 141 requested points remained valid;
- nearestRank and nearestBranchID remained unchanged;
- maximum high-frequency |Delta2Cp/Cp| decreased by about 42x;
- median high-frequency |Delta2Cp/Cp| decreased by about 10x;
- median high-frequency objective improved from about -1.46 to -6.20;
- repeated alternating benchmarks measured about 6.3% median runtime overhead;
- the maintained acoustoelastic smoke and extended test suites passed.
```

Temporary diagnostic scripts used to obtain this evidence were removed after
validation.

## Remaining solver-side work

The resolved waviness issue should not be reopened through plotting-side
smoothing. Remaining numerical work, if separately prioritized, includes:

```text
- low-frequency modal degeneracy characterization;
- optional modal-signature/MAC reinforcement near difficult branch crossings;
- controlled runtime characterization for other solvers and parameter regimes.
```

Any future change should remain focused, preserve official output contracts,
and include numerical and runtime evidence.

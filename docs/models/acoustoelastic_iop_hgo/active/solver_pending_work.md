# Acoustoelastic IOP/HGO solver pending work

This document records bounded solver-side work that must remain separate from
GUI and repository-hygiene tasks.

## Current status

The maintained production branch policy remains:

```text
atlasA0 = conservative official output
```

The IOP/HGO wrapper still separates:

```text
internal atlas tracking grid
requested output frequency grid
```

The previously reported high-frequency waviness in `Cp(f)` has been addressed
through selected-branch continuous refinement.

## Resolved numerical issue: residual waviness in Cp(f)

The investigation established that:

```text
1. The selected branch identity remained stable.
2. Increasing atlasNumYPoints did not remove the waviness and increased runtime.
3. Disabling refinement produced quantized plateaus and large jumps.
4. The three-point parabolic fit did not represent the narrow true SVD residual valleys.
```

The production fix keeps the atlas responsible for candidate discovery,
branch linking, and A0 selection. After the maintained branch has been selected,
only its explicit points are refined by minimizing the true objective

```text
log10(sigma_min(M))
```

with `fminbnd` in `log(Cp)` between neighboring atlas velocity samples.

The implementation is owned by:

```text
models/acoustoelastic_iop_hgo/tracking/aeRefineSelectedAtlasBranch.m
```

and is invoked from:

```text
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m
```

## Configuration contract

The selected-branch refinement is controlled by:

```text
refineSelectedAtlasBranch
selectedBranchRefinementTolLogCp
selectedBranchRefinementMaxFunEvals
selectedBranchRefinementMaxIter
```

`refineLocalMinima=false` disables both the original local-minimum refinement
and the selected-branch continuous refinement, preserving the discrete-grid
contract used by characterization tests.

## Validation evidence

For the representative 1-15 kHz case used during the investigation:

```text
- all 141 requested points remained valid;
- nearestRank and nearestBranchID were unchanged;
- maximum high-frequency |Delta2Cp/Cp| decreased by about 42x;
- median high-frequency |Delta2Cp/Cp| decreased by about 10x;
- median high-frequency objective improved from about -1.46 to -6.20;
- repeated alternating benchmarks measured about 6.3% median runtime overhead;
- the maintained acoustoelastic smoke and extended test suites passed.
```

The temporary diagnostic scripts used to obtain this evidence were removed from
the implementation branch after validation.

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

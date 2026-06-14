# Naming strategy

This document records the maintained naming strategy for solver APIs, examples, diagnostics, future GUI-facing integrations, and dedicated rename work. This is documentation-only guidance; it does not rename existing MATLAB functions.

## Rayleigh-Lamb

* Use `rl*` for model functions.
* Existing `rl*` API remains the reference style.

## mRLFE

* Use `mrlfe*` for internal/model-specific functions when lowercase style is appropriate.
* Existing public names such as `computeMRLFE`, `solveMRLFEBranch`, and `refineMRLFERealKRoot` may remain.
* Future public mRLFE functions should prefer `computeMRLFE...`, `solveMRLFE...`, or `refineMRLFE...`.
* Avoid “prototype” in maintained example names.

## Acoustoelastic IOP/HGO

* Existing long author-neutral names such as `solveAcoustoelasticIOPHGOBranch` may remain for now.
* New acoustoelastic functions should prefer the short `ae*` prefix.
* Use `ae*` for functions that are clearly inside `models/acoustoelastic_iop_hgo/`.
* Use `aeIOPHGO*` only for high-level public functions where the IOP/HGO specificity must be explicit.
* Do not reintroduce `Li2024`.

Recommended future acoustoelastic naming examples:

```matlab
aeDefaultOptions
aeSolveBranch
aeSolveAtlasBranch
aeSolveDispersion
aeSolveComplexC
aeBuildMatrix
aeResidual
aeComplexDeterminant
aeComputeABG
aeComputeSRoots
aeComputePrestress
aeSolveStretch
```

Alternative high-level explicit names, only when needed:

```matlab
aeIOPHGODefaultOptions
aeIOPHGOSolveBranch
aeIOPHGOSolveAtlasBranch
aeIOPHGOSolveDispersion
```

## Examples

* Use `run_*` for basic executable examples.
* Use `sweep_*` for parameter sweeps.
* Use `diagnose_*` for diagnostic scripts.
* Use `compare_*` for comparative scripts.
* Use `track_*` only for branch-tracking diagnostics.

## GUI

* GUI code should call model APIs, not scripts in `examples/`.
* GUI code may keep using the existing long author-neutral API initially.
* If shorter `ae*` aliases are later introduced, they should be added in a dedicated pull request with tests and documentation.

## Renaming policy

Existing function names should not be renamed casually. Renames should happen only in dedicated pull requests with:

1. path checks,
2. smoke tests,
3. updated examples,
4. updated docs,
5. a clear migration note.

# Naming strategy

This document records the maintained naming strategy for solver APIs, examples, diagnostics, future GUI-facing integrations, and dedicated rename work.

## Core rule

Use folders to carry model context. Use short executable filenames for MATLAB entrypoints.

MATLAB only recognizes function/script names up to `namelengthmax`, usually 63 characters. Long descriptive filenames can be truncated and fail at runtime. Windows paths can also become fragile if every folder and file repeats the full model name.

Therefore:

```text
Good:  examples/acoustoelastic_iop_hgo/diagnostics/diagnose_idA0_plausibility.m
Avoid: examples/acoustoelastic_iop_hgo/diagnostics/diagnose_acoustoelastic_iop_hgo_identityA0_physical_plausibility.m
```

The folder already states the model. The filename should state the task.

## Practical limits

For new executable `.m` scripts:

- keep names below about 45 characters;
- never exceed MATLAB `namelengthmax`;
- avoid repeating the model name if the folder already contains it;
- prefer short task tags such as `idA0`, `A0`, `iop`, `mu`, `grid`, `plausibility`, `landscape`.

Long descriptive scripts may remain temporarily as implementation or legacy files, but user-facing commands should use short entrypoints.

## Result-folder convention

For new acoustoelastic IOP/HGO outputs, prefer:

```text
Results/ae_iop_hgo/<task>
```

Examples:

```text
Results/ae_iop_hgo/idA0_score_grid
Results/ae_iop_hgo/idA0_grid
Results/ae_iop_hgo/idA0_plausibility
```

Avoid repeating the full model name in every output folder:

```text
Results/acoustoelastic_iop_hgo_identityA0_physical_plausibility
```

Legacy long folders remain valid for backward compatibility, but new scripts should write to the short result root.

## Helper functions for paths

Use:

```matlab
aeOutputFolder(launchFolder, taskName)
```

for new output folders. It returns:

```text
<launchFolder>/Results/ae_iop_hgo/<taskName>
```

Use:

```matlab
aeResolveResultFile(launchFolder, shortTaskName, shortFileName, legacyFolderName, legacyFileName)
```

when a script must support both new short outputs and older long outputs. It checks the short path first, then falls back to the legacy path.

## Rayleigh-Lamb

* Use `rl*` for model functions.
* Existing `rl*` API remains the reference style.

## mRLFE

* Use `mrlfe*` for internal/model-specific functions when lowercase style is appropriate.
* Existing public names such as `computeMRLFE`, `solveMRLFEBranch`, and `refineMRLFERealKRoot` may remain.
* Future public mRLFE functions should prefer `computeMRLFE...`, `solveMRLFE...`, or `refineMRLFE...`.
* Avoid “prototype” in maintained example names.

## Acoustoelastic IOP/HGO

* Existing long author-neutral public solver names such as `solveAcoustoelasticIOPHGOBranch` may remain.
* New model-specific helper functions should prefer the short `ae*` prefix.
* New diagnostic and validation entrypoints under `examples/acoustoelastic_iop_hgo/` should use short task names.
* Use `ae*` for functions clearly inside `models/acoustoelastic_iop_hgo/` or `analysis/acoustoelastic_iop_hgo/`.
* Use `aeIOPHGO*` only for high-level public functions where IOP/HGO specificity must be explicit.
* Do not reintroduce `Li2024`.

Recommended future acoustoelastic helper naming examples:

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
aeOutputFolder
aeResolveResultFile
```

Recommended diagnostic entrypoint examples:

```matlab
validate_idA0_score_grid
validate_idA0_grid
diagnose_idA0_plausibility
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
* Use `validate_*` for validation grids and regression-style checks.
* Use `diagnose_*` for diagnostic scripts.
* Use `compare_*` for comparative scripts.
* Use `track_*` only for branch-tracking diagnostics.
* Prefer short task-oriented names when the folder already contains model context.

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

For the current issue, use short wrappers and short result paths for new work. Full migration/renaming of legacy files should be handled after the issue is closed.

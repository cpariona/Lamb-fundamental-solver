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

Long descriptive scripts may remain as retained implementation files or diagnostic implementations, but user-facing commands should use short entrypoints.

Simple compatibility aliases that only redirect to short entrypoints should not be reintroduced.

## Result-folder convention

For new acoustoelastic IOP/HGO outputs, prefer:

```text
Results/ae_iop_hgo/<task>
```

relative to the MATLAB launch folder.

Examples:

```text
Results/ae_iop_hgo/iop_sweep
Results/ae_iop_hgo/mu_sweep
Results/ae_iop_hgo/idA0_score_grid
Results/ae_iop_hgo/idA0_grid
Results/ae_iop_hgo/idA0_plausibility
```

Avoid repeating the full model name in every output folder:

```text
Results/acoustoelastic_iop_hgo_identityA0_physical_plausibility
```

Legacy long folders may remain valid for fallback reads, but new scripts should write to the short result root.

## Mechanical parameter convention

For soft-material and OCE-facing examples, use `mu`, `nu`, and `rho` as the canonical user-facing isotropic elastic inputs.

Rationale:

- mRLFE and AE/OCE workflows are naturally expressed in terms of shear stiffness for nearly incompressible materials.
- Sweeps and plots should expose comparable parameters across Rayleigh-Lamb, mRLFE, and acoustoelastic models.
- Rayleigh-Lamb and mRLFE may solve internally through wave speeds or Lamé parameters, but those should be derived from the canonical user-facing inputs.

Recommended external sweep and GUI parameters:

```text
mu          shear modulus, user-facing elastic stiffness
nu          Poisson ratio, user-facing compressibility control for RL/mRLFE
rho         density
2h          full thickness
etaS        shear viscosity, when the model is viscoelastic
IOP         pressure/loading parameter, when the model is acoustoelastic
```

Recommended derived quantities for linear isotropic elastic models:

```matlab
E           = 2*mu*(1 + nu)
lambda_Lame = 2*mu*nu/(1 - 2*nu)
K           = lambda_Lame + 2*mu/3
CT          = sqrt(mu/rho)
CL          = sqrt((lambda_Lame + 2*mu)/rho)
```

For nearly incompressible reference cases, `nu` may be fixed close to 0.5 but should not equal 0.5 because `lambda_Lame` diverges. Avoid exposing `E` as the primary sweep variable for soft-material comparisons unless the goal is specifically an engineering-stress/Young-modulus study.

Lamé parameters are acceptable inside solver kernels and derivations, but they should not be the primary user-facing sweep parameters unless the script is specifically validating the Lamé formulation. Use the name `lambda_Lame` in user-facing documentation to avoid confusion with stretch variables in acoustoelastic/HGO workflows.

## Helper functions for paths and legacy execution

Use:

```matlab
aeOutputFolder(launchFolder, taskName)
```

for new output folders. It returns:

```text
<launchFolder>/Results/ae_iop_hgo/<taskName>
```

`launchFolder` should be the user's MATLAB working directory at the time the maintained entrypoint is called. It should not be assumed to be the repository root or the folder containing the script.

Use:

```matlab
aeResolveResultFile(launchFolder, shortTaskName, shortFileName, legacyFolderName, legacyFileName)
```

when a script must support both new short outputs and older long outputs. It checks the short path first, then falls back to the legacy path.

Use:

```matlab
aeRunLegacyScript(scriptPath)
```

only when a short entrypoint still needs to execute a retained legacy implementation script. Do not use it to preserve simple compatibility aliases that only redirect to another short command.

## Rayleigh-Lamb

* Use `rl*` for model functions.
* Existing `rl*` API remains the reference style.
* Rayleigh-Lamb examples should keep basic runs under `examples/rayleigh_lamb/basic/`, sweeps under `examples/rayleigh_lamb/sweeps/`, and validation scripts under `examples/rayleigh_lamb/validation/`.
* For soft-material comparisons, expose `mu` and `nu` and derive the solver-required elastic representation internally.

## mRLFE

* Use `mrlfe*` for internal/model-specific functions when lowercase style is appropriate.
* Existing public names such as `computeMRLFE`, `solveMRLFEBranch`, and `refineMRLFERealKRoot` may remain.
* Future public mRLFE functions should prefer `computeMRLFE...`, `solveMRLFE...`, or `refineMRLFE...`.
* Avoid “prototype” in maintained example names.
* For maintained sweeps, expose `mu`, `etaS`, and `2h` rather than `E` when comparing against Rayleigh-Lamb or AE/OCE workflows.

## Acoustoelastic IOP/HGO

* Existing long author-neutral public solver names such as `solveAcoustoelasticIOPHGOBranch` may remain.
* New model-specific helper functions should prefer the short `ae*` prefix.
* New diagnostic and validation entrypoints under `examples/acoustoelastic_iop_hgo/` should use short task names.
* Use `ae*` for functions clearly inside `models/acoustoelastic_iop_hgo/` or `analysis/acoustoelastic_iop_hgo/`.
* Use `aeIOPHGO*` only for high-level public functions where IOP/HGO specificity must be explicit.
* Do not reintroduce `Li2024`.

Recommended acoustoelastic helper naming examples:

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
aeRunLegacyScript
```

Recommended user-facing entrypoints:

```matlab
run_atlas_branch
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
validate_idA0_score_grid
validate_idA0_grid
diagnose_idA0_score
diagnose_modal_atlas
track_raw_branch1
```

`diagnose_idA0_plausibility` requires the workspace generated by `validate_idA0_grid`; it is not a standalone smoke-test command.

`diagnose_modal_atlas` now starts at low frequency by design. Do not reintroduce the removed `diagnose_modal_atlas_lowfreq` entrypoint.

Alternative high-level explicit names, only when needed:

```matlab
aeIOPHGODefaultOptions
aeIOPHGOSolveBranch
aeIOPHGOSolveAtlasBranch
aeIOPHGOSolveDispersion
```

## Examples

* Use `run_*` for basic executable examples.
* Use `<model>_sweep_<parameter>_<branch>` for maintained public sweep entrypoints.
* Use `validate_*` for validation grids and regression-style checks.
* Use `diagnose_*` for diagnostic scripts.
* Use `compare_*` for comparative scripts.
* Use `track_*` only for branch-tracking diagnostics.
* Prefer short task-oriented names when the folder already contains model context.

## GUI

* GUI code should call model APIs, not scripts in `examples/`.
* GUI code should expose `mu`, `nu`, `rho`, and `2h` as primary soft-material inputs, and display `E`, `lambda_Lame`, `K`, `CT`, and `CL` as derived quantities.
* Do not add aliases for renamed sweep entrypoints.

## Renaming policy

Existing function names should not be renamed casually. Renames should happen only in dedicated pull requests with:

1. path checks,
2. smoke tests,
3. updated examples,
4. updated docs,
5. a clear migration note.

For current migration work, prefer short entrypoints plus short result paths. Rename maintained sweep entrypoints directly, update active references, and do not keep compatibility wrappers for the old names. Retain long descriptive files only when they contain implementation, heavy validation, diagnostic, or reproducibility logic that has not been migrated into a short implementation file.

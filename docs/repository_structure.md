# Repository structure

This document describes the active repository layout for GUI-focused development. The current MATLAB implementation is organized around the clean Rayleigh-Lamb `rl*` API, shared isotropic material helpers, the mRLFE model, the author-neutral acoustoelastic IOP/HGO API, and a GUI adapter layer. Naming guidance is documented in `docs/naming_strategy.md` and the acoustoelastic short-path convention is summarized in `docs/acoustoelastic_iop_hgo/naming_and_paths_convention.md`.

## Active top-level areas

```text
app/                         MATLAB GUI entrypoints, UI helpers, adapters, and sweep helpers.
analysis/                    Generic analysis utilities plus model-specific analysis helpers.
docs/                        Active repository, API, validation, and workflow documentation.
docs/rayleigh_lamb/          Rayleigh-Lamb model documentation.
docs/mrlfe/                  mRLFE model documentation.
docs/acoustoelastic_iop_hgo/ Acoustoelastic IOP/HGO model documentation.
examples/rayleigh_lamb/      Maintained Rayleigh-Lamb examples, sweeps, and validation scripts.
examples/mrlfe/              Maintained mRLFE examples, sweeps, diagnostics, and stress tests.
examples/acoustoelastic_iop_hgo/
                             Maintained acoustoelastic IOP/HGO examples, sweeps, and diagnostics.
models/materials/            Shared isotropic elastic material-parameter helpers.
models/rayleigh_lamb/        Clean Rayleigh-Lamb implementation using `rl*` functions.
models/mrlfe/                Modified Rayleigh-Lamb fluid-loaded model implementation.
models/acoustoelastic_iop_hgo/
                             Author-neutral acoustoelastic IOP/HGO implementation.
tests/                       Smoke and consistency tests.
references/                  Reference material used for development and validation context.
```

## Active MATLAB path and startup

`startup.m` prepares the active implementation, GUI, analysis, example, and test folders for use from the repository root. Maintained callers should use the documented public entrypoints.

Recommended setup sequence:

```matlab
clear functions
rehash toolboxcache
startup
```

## App folders

```text
app/
├─ LambFundamental_GUI.m
├─ SweepTool_GUI.m
├─ adapters/
└─ sweep/
```

`app/adapters/` contains GUI-facing model and sweep adapters. GUI callbacks should call adapters rather than calling model internals directly.

`app/sweep/` contains the SweepTool registry, request builder, dispatcher, and plotting helpers. The visible SweepTool families are documented in:

```text
docs/sweep_tool_usage.md
```

## Model folders

### Shared material helpers

```text
models/materials/
├─ elasticFromMuNu.m
└─ elasticFromLame.m
```

These helpers build equivalent isotropic elastic quantities from `mu`, `nu`, `rho`, or Lamé constants. Maintained soft-material workflows expose `mu` and `nu`, while `E`, `lambda_Lame`, `K`, `CT`, and `CL` are derived.

### Rayleigh-Lamb base solver

```text
models/rayleigh_lamb/
├─ approximations/
├─ core/
├─ equations/
└─ tracking/
```

Maintained Rayleigh-Lamb implementation functions use the `rl*` API. See `docs/rayleigh_lamb/public_api.md` for the public function list and `docs/rayleigh_lamb/overview.md` for model context.

### mRLFE model

```text
models/mrlfe/
├─ core/
├─ solvers/
└─ options/
```

The high-level mRLFE entrypoint is:

```matlab
computeMRLFE
```

The mRLFE tracker diagnostic summary is documented in:

```text
docs/mrlfe/tracker_diagnostic_summary.md
```

### Acoustoelastic IOP/HGO model

```text
models/acoustoelastic_iop_hgo/
├─ core/
├─ constitutive/
├─ solvers/
└─ options/
```

Recommended author-neutral entrypoints include:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticIOPHGODispersion
defaultAcoustoelasticIOPHGOOptions
```

GUI code, examples, diagnostics, tests, and analysis scripts should call the author-neutral acoustoelastic IOP/HGO API documented in `docs/acoustoelastic_iop_hgo/public_api.md`.

Model-specific analysis helpers for diagnostics and output paths live in:

```text
analysis/acoustoelastic_iop_hgo/
```

Examples:

```matlab
aeOutputFolder
aeResolveResultFile
aeRunLegacyScript
aeScoreBranchIdentityCandidates
aeBuildIdentityA0DiagnosticBranch
```

## Example folders

```text
examples/rayleigh_lamb/
├─ basic/
├─ sweeps/
└─ validation/
examples/mrlfe/
├─ basic/
├─ sweeps/
└─ diagnostics/
examples/acoustoelastic_iop_hgo/
├─ basic/
├─ sweeps/
└─ diagnostics/
```

Rayleigh-Lamb examples and validation scripts live under `examples/rayleigh_lamb/`. The old top-level `examples/basic/` folder has been removed. Within each model folder, `basic/` is reserved for minimal default runs, `sweeps/` for parametric sweeps, `validation/` for validation checks, and `diagnostics/` for diagnostic investigations.

The old top-level validation folder has been removed. Rayleigh-Lamb validation scripts now live under `examples/rayleigh_lamb/validation/`, and mRLFE stress tests now live under `examples/mrlfe/diagnostics/`.

Maintained examples are intended to exercise active APIs only. Archived example material is not part of the active documentation set.

For acoustoelastic IOP/HGO examples, sweeps, and diagnostics, the folder already provides model context. New executable scripts should therefore use short task-oriented names, for example:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
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
diagnose_modal_atlas_lowfreq
track_raw_branch1
```

rather than repeating `acoustoelastic_iop_hgo` in the filename.

## Result folders

The preferred result root for new acoustoelastic IOP/HGO outputs is:

```text
Results/ae_iop_hgo/<task>
```

Examples:

```text
Results/ae_iop_hgo/idA0_score_grid
Results/ae_iop_hgo/idA0_grid
Results/ae_iop_hgo/idA0_plausibility
```

Legacy long result folders remain valid and should not be deleted automatically. New scripts should write to the short root and, during migration, may read from short paths first and legacy paths second using `aeResolveResultFile`.

## Tests

Maintained tests are stored in:

```text
tests/run_all_smoke_tests.m
tests/test_gui_normalized_adapters_smoke.m
tests/test_gui_sweep_adapters_smoke.m
tests/test_gui_sweep_registry_smoke.m
tests/test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke.m
tests/mrlfe/
tests/acoustoelastic_iop_hgo/
```

Recommended smoke-test sequence after documentation or path-sensitive refactors:

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
```

For short acoustoelastic entrypoint path checks, run:

```matlab
test_acoustoelastic_iop_hgo_short_entrypoints
```

# Rayleigh-Lamb base solver reorganization plan

## Purpose

This document is a documentation-only architecture audit and future migration plan for the current Rayleigh-Lamb base solver. It records the present folder layout, identifies the MATLAB files that appear to form the base solver, and proposes a conservative reorganization path for a later implementation phase.

This phase makes the organized `rl*` functions under `models/rayleigh_lamb/` the primary Rayleigh-Lamb implementation entrypoints, without moving files or intentionally altering numerical behavior. The old top-level Rayleigh-Lamb function names in `core/`, `equations/`, `approximations/`, and `tracking/` remain in place as compatibility wrappers that forward to the `rl*` implementations. For the public `rl*` API table and old-name mapping, see [Rayleigh-Lamb public API](rayleigh_lamb_public_api.md). For the policy governing the old top-level compatibility wrappers, see [Rayleigh-Lamb legacy wrapper policy](rayleigh_lamb_legacy_wrapper_policy.md). For the release checklist for this implementation handoff milestone, see [Rayleigh-Lamb wrapper layer release checklist](rayleigh_lamb_wrapper_release_checklist.md). Lightweight smoke coverage exists for both the old top-level compatibility wrappers and the `rl*` implementation entrypoints in `tests/run_all_smoke_tests.m`; the compatibility section verifies selected old-vs-new forwarding behavior for safe helper functions without full dispersion sweeps, and the minimal numerical regression section checks representative A0/S0 outputs without broad sweeps. The Acoustoelastic IOP/HGO author-neutral API migration is treated as completed and tagged as `v0.4.0-acoustoelastic-author-neutral-api`; this plan is about the next possible Rayleigh-Lamb base solver cleanup.

## Current repository structure

The following relevant folders exist in the current repository:

- `core/`: Top-level base solver orchestration, defaults, validation, material/geometry construction, frequency-vector construction, and branch specification helpers for the fundamental Rayleigh-Lamb workflow.
- `equations/`: Normalized antisymmetric and symmetric Rayleigh-Lamb residual equations used by the base solver.
- `approximations/`: Low-frequency analytical approximations for the fundamental A0 and S0 Lamb modes.
- `tracking/`: Continuation/root-tracking logic for following a fundamental branch across frequency points.
- `models/`: Model-specific implementations that already use model-scoped folders, including Acoustoelastic IOP/HGO and mRLFE code. The Rayleigh-Lamb `rl*` implementation layer now exists under `models/rayleigh_lamb/`; the old top-level base function names forward to this layer for compatibility.
- `examples/`: Runnable examples, sweeps, diagnostics, validation scripts, and archived exploratory scripts for the base solver and model-specific extensions.
- `tests/`: MATLAB smoke tests for maintained functionality, including Acoustoelastic IOP/HGO and mRLFE checks.
- `docs/`: Architecture, migration, validation, release-readiness, and maintained-entrypoint documentation.
- `analysis/`: Analysis and summarization helpers, including parameter sweep utilities and Acoustoelastic IOP/HGO tracking-quality summaries.
- `app/`: MATLAB GUI application files and related UI helpers.

## Current Rayleigh-Lamb base components

The current base Rayleigh-Lamb solver appears to be spread across four top-level folders rather than under a model-scoped folder.

`core/` appears to contain the high-level base solver and shared setup helpers:

- `core/computeFundamentalLambModes.m`: Main base-solver orchestration entrypoint for computing fundamental A0/S0 results and optional model extensions.
- `core/defaultParams.m`: Default material, geometry, and frequency parameters.
- `core/defaultOptions.m`: Default solver, tracking, and related numerical options.
- `core/validateParams.m`: Parameter validation.
- `core/validateOptions.m`: Solver-option validation.
- `core/computeMaterial.m`: Material-property construction from supported parameterizations.
- `core/computeGeometry.m`: Plate geometry construction.
- `core/buildFrequencyVector.m`: Frequency grid construction.
- `core/makeBranchSpec.m`: Branch-specific physical guesses and search ranges for A0/S0.

`equations/` appears to contain the base Rayleigh-Lamb residual equations:

- `equations/rayleighLambAResidual.m`: Normalized antisymmetric Rayleigh-Lamb residual objective.
- `equations/rayleighLambSResidual.m`: Normalized symmetric Rayleigh-Lamb residual objective.

`approximations/` appears to contain analytical comparison curves for fundamental branches:

- `approximations/computeAnalyticalApproximations.m`: Aggregates analytical approximations.
- `approximations/computeA0ThinPlateApproximation.m`: Low-frequency A0 thin-plate flexural approximation.
- `approximations/computeS0ExtensionalApproximation.m`: Low-frequency S0 extensional plate approximation.

`tracking/` appears to contain branch continuation logic:

- `tracking/solveFundamentalBranch.m`: Frequency-continuation solver for one fundamental branch, using residual scans, local minima, refinement, prediction, and scoring controls.

## Current dependencies and likely call flow

The likely current call flow is:

1. A caller such as a basic example, GUI callback, analysis helper, or test creates `params` with `defaultParams` and `options` with `defaultOptions`, or provides compatible structures directly.
2. The caller invokes `computeFundamentalLambModes(params, options)`.
3. `computeFundamentalLambModes` validates inputs through `validateParams` and `validateOptions`.
4. It constructs derived physical inputs with `computeMaterial`, `computeGeometry`, and `buildFrequencyVector`.
5. It computes analytical reference curves through `computeAnalyticalApproximations`, which calls the A0 and S0 approximation helpers.
6. For A0 and/or S0, it creates branch-specific settings with `makeBranchSpec`.
7. It builds residual-function handles around `rayleighLambAResidual` and/or `rayleighLambSResidual`.
8. It passes those residual handles to `solveFundamentalBranch`, which performs the branch tracking/root refinement across the frequency vector.
9. It packs A0/S0 outputs into the returned `results` structure.
10. Depending on options, it may also call model-specific extensions such as mRLFE routines after the base modes are available.

This call flow is inferred from file names, function names, and observed references. It should be treated as a high-level map rather than a complete dependency graph; nested helper functions inside individual MATLAB files and optional model-extension paths may add details not captured here.

## Proposed future package structure

A future implementation phase could move the base Rayleigh-Lamb solver into a model-scoped folder that matches the organization already used by model-specific code. One possible target structure is:

```text
models/rayleigh_lamb/core/
models/rayleigh_lamb/equations/
models/rayleigh_lamb/approximations/
models/rayleigh_lamb/tracking/
models/rayleigh_lamb/options/
models/rayleigh_lamb/examples/
```

Possible mapping for a later code-moving phase:

- `core/computeFundamentalLambModes.m` -> `models/rayleigh_lamb/core/computeFundamentalLambModes.m`
- `core/computeMaterial.m`, `core/computeGeometry.m`, `core/buildFrequencyVector.m`, and `core/makeBranchSpec.m` -> `models/rayleigh_lamb/core/`
- `core/defaultParams.m`, `core/defaultOptions.m`, `core/validateParams.m`, and `core/validateOptions.m` -> `models/rayleigh_lamb/options/`
- `equations/rayleighLambAResidual.m` and `equations/rayleighLambSResidual.m` -> `models/rayleigh_lamb/equations/`
- `approximations/*.m` -> `models/rayleigh_lamb/approximations/`
- `tracking/solveFundamentalBranch.m` -> `models/rayleigh_lamb/tracking/`
- selected future Rayleigh-Lamb examples, if reorganized, -> `models/rayleigh_lamb/examples/` or a clearly documented examples subtree.

The `core/`, `equations/`, `approximations/`, and `tracking/` folders now exist under `models/rayleigh_lamb/` as the primary `rl*` implementation layer. The original top-level files have not been physically removed; they remain as compatibility wrappers.

## Compatibility strategy

Future reorganization should preserve current public function names through wrappers, path aliases, or a staged path transition. Existing callers should continue to resolve names such as `computeFundamentalLambModes`, `defaultParams`, `defaultOptions`, `rayleighLambAResidual`, `rayleighLambSResidual`, and `solveFundamentalBranch` while the implementation is moved.

MATLAB primary function names must continue to match their file names. Therefore, if a maintained implementation file is renamed or moved into a new file, the primary function inside that file must use the same name as the file. If legacy callable names remain public, same-named wrapper files should remain at the old paths until deprecation is explicitly documented and tested.

The transition should avoid changing `startup.m` path behavior and public entrypoint resolution in the same commit as numerical code movement unless path-level smoke checks already cover both old and new locations. Current path-level smoke checks cover the existing Rayleigh-Lamb base function locations before any future reorganization.

## Migration phases

- Phase 1: documentation and inventory only.
- Phase 2: add path-level smoke checks for current Rayleigh-Lamb base functions. **Completed:** `run_all_smoke_tests` checks that current base functions in `core/`, `equations/`, `approximations/`, and `tracking/` resolve on the MATLAB path.
- Phase 3: introduce author-neutral maintained entrypoints if needed. **Completed for the wrapper layer:** `models/rayleigh_lamb/` introduced `rl*` entrypoints without changing numerical behavior.
- Phase 4: hand off primary implementation responsibility to `models/rayleigh_lamb/` while preserving old top-level compatibility wrappers. **Completed for the base function pairs listed in this plan:** `rl*` files now contain the implementation logic, old top-level names forward to them, and lightweight smoke checks compare selected old-vs-new helper outputs. Files have not yet been physically removed.
- Phase 5: physical file removal or broader archive/prototype migration remains deferred.
- Phase 6: update examples and docs.
- Phase 7: add numerical regression tests before removing or deprecating any legacy paths.

## Guardrails for future implementation

- Do not change dispersion equations.
- Do not change root-finding behavior.
- Do not change tracking behavior.
- Do not change default tolerances.
- Do not change output structures.
- Do not rename functions without wrappers.
- Do not move files without smoke tests.
- Keep code-moving commits separate from numerical behavior changes.
- Keep documentation-only phases free of MATLAB source, test, example, diagnostic, sweep, GUI, archive, prototype, startup, and model implementation changes.

## Deferred decisions

- Exact public API naming.
- Whether to keep current top-level folders temporarily.
- Whether to add MATLAB packages using `+package` folders.
- Whether to create formal numerical regression fixtures.
- Whether to reorganize examples before or after core files.

## Current implementation handoff status

As of this handoff phase, maintained Rayleigh-Lamb call sites should treat the `rl*` functions in `models/rayleigh_lamb/` as the primary implementation entrypoints. The old top-level Rayleigh-Lamb functions are retained as compatibility wrappers and have not been physically removed. Archive/prototype migration remains deferred. No numerical algorithms, equations, default values, tolerances, root-finding behavior, tracking behavior, or output structures were intentionally changed. Lightweight compatibility smoke checks now verify selected old top-level Rayleigh-Lamb wrappers against their primary `rl*` implementations; minimal numerical regression smoke fixtures now cover representative A0/S0 outputs without heavy sweeps.

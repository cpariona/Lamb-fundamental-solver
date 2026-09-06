# AGENTS.md

## Project purpose

This repository provides maintained MATLAB implementations for fundamental Lamb-wave dispersion and inverse dispersion fitting in soft materials.

The two primary scientific capabilities are:

1. forward dispersion solvers;
2. fitting model parameters to experimental dispersion data.

Sensitivity sweeps and solver investigations are secondary study tools, not peer product capabilities.

## Canonical architecture target

```text
src/+lamb/
  +models/       canonical forward physical models
  +fitting/      inverse dispersion fitting
  +elasticity/   neutral isotropic elastic conversions
  +grids/        neutral frequency/discretization construction
  +sweeps/       minimal generic parameter-iteration utility, only if justified

app/             solver and fitting human interfaces
studies/         sensitivity studies and solver investigations
tests/           automated validation
docs/            current architecture, scientific contracts, and model documentation
```

Do not create a generic `analysis/`, `shared/`, `common/`, or equivalent catch-all owner. A capability must have one precise semantic owner.

## Canonical model families

- Rayleigh-Lamb (`rayleigh_lamb`)
- modified Rayleigh-Lamb frequency equation (`mrlfe`)
- acoustoelastic IOP/HGO (`acoustoelastic_iop_hgo`)

Where a responsibility exists, a model may use the established internal roles:

```text
configuration
core
equations / constitutive when scientifically justified
solvers
tracking
policies when scientifically justified
quality
results
```

Do not create empty folders or wrappers merely for visual symmetry.

## Scientific and numerical invariants

Structural work must preserve the currently approved scientific behavior unless the user explicitly authorizes a scientific/numerical change.

Do not alter during structural migration:

- governing equations or constitutive laws;
- branch definitions or branch-selection policy;
- tracking algorithms;
- AE atlas strategy;
- AE Cp-dependent state caching;
- AE bounded continuous refinement;
- mRLFE candidate discovery, dense rescue, selected-candidate refinement, or physical termination policy;
- numerical presets/defaults or accepted tolerances;
- fitting objectives, recovery behavior, or scientific parameter meaning;
- scientific goldens/baselines merely to make a refactor pass.

Performance optimizations already present in production are canonical implementation, not experiments.

## Public scientific contracts

Official curves use column vectors:

```text
frequency_Hz
phaseVelocity_mps
wavenumber_radpm
validMask
```

Invalid official phase velocity is `NaN` with `validMask = false`.

Core quality fields are:

```text
pointCount
validCount
validFraction
accepted
reason
```

Model results expose:

```text
configuration.requested.parameters
configuration.requested.options
configuration.effective.parameters
configuration.effective.options
```

Execution metadata contains at least:

```text
engine
elapsedSeconds
```

Quality evaluates an already selected official result. It must not silently reconnect, interpolate, replace, or select a scientific branch.

## Dependency direction

- Models must not depend on app, studies, tests, or documentation.
- Fitting calls canonical model APIs; it must not duplicate solver physics.
- Studies call maintained APIs; production code never depends on studies.
- App coordinates and translates requests; it does not own equations, residuals, tracking, fitting algorithms, or hidden alternate solvers.
- Generic infrastructure used by multiple model families has a neutral owner.
- The intentional scientific cross-family dependency is limited to `mRLFE seed -> Rayleigh-Lamb solver` where documented.

Do not add compatibility aliases or forwarding wrappers only to preserve migration-era names. Git history preserves retired layouts and implementations.

## Canonical versus transitional naming

Current validated implementations are canonical. Do not label them `new`, `current`, `active`, `final`, `v2`, `candidate`, `experimental`, or similar merely because they replaced an older implementation.

Such terms are allowed only when they describe a real runtime/scientific distinction.

Examples: execution profiles `Fast`, `Balanced`, `Robust` and a scientifically meaningful branch policy name may remain.

## Sweeps, studies, and diagnostics

Sweep is an application of a solver, not a peer scientific model.

Keep only a small reusable sweep engine if it materially reduces duplication. Sensitivity campaigns and figure-generating sweeps belong in `studies/sensitivity/`.

Solver investigations such as branch-family inspection, grid sensitivity, modal-atlas inspection, or tracking reliability belong in `studies/solver_diagnostics/` unless a small piece is truly model-owned quality metadata.

A diagnostic investigation must not maintain a second copy of production scientific logic.

The SweepTool GUI is not part of the target product architecture unless a concrete user requirement is established.

## Development workflow

- `main` is the validated integration target and is not modified directly during major migration work.
- Current migration is tracked by GitHub issue #139.
- Integration branch: `architecture/canonical-src-layout`.
- Phase branches target the integration branch.
- The user performs final merges to `main` unless explicitly stated otherwise.
- Keep changes reviewable and responsibility-focused.

## MATLAB validation

The canonical validation surface is:

```matlab
startup
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

The validated pre-migration baseline is 115 passing tests on `main` commit `0609f6f3d4dc12b1eccdde84bf2053397be5c797`.

When MATLAB execution is unavailable to an implementation agent, do not claim tests passed. Report the exact commands for the user to run.

## Documentation authority

During migration, preserve the permanent ideas in:

- `docs/repository/structural_symmetry_contract.md`
- `docs/repository/maintainability_policy.md`
- model documentation under `docs/models/`

The target architecture is defined in `docs/repository/canonical_architecture.md`.

At the end of issue #139, consolidate permanent conventions and remove obsolete planning, audit, handoff, transition-status, and superseded architecture documents. Documentation should describe the repository that exists now; Git and PR history preserve how it got there.

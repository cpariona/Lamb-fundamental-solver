# mRLFE production core

Last reviewed: 2026-07-07

## Scope

The real-k mRLFE public API now executes through a model-layer production core:

```text
mrlfeSolve
  -> mrlfeResolveConfiguration
  -> mrlfeBuildProblem
  -> mrlfeSolveBranch
       -> mrlfeSolveElasticBranch
       -> mrlfeSolveViscoelasticBranch
       -> mrlfeBuildSeed
       -> mrlfeTrackBranchAdaptive
       -> mrlfeApplyTerminationPolicy
  -> mrlfeBuildResult
```

The core preserves the audited FitTool atlas-first numerical behavior without
calling `mrlfeEvaluateAtlasFitModel`, `mrlfeEvaluateFitModel`, or GUI adapters.
FitTool fitting now reaches this core through the public API:

```text
guiFitMRLFESolver
  -> mrlfeFitDispersionData
  -> mrlfeEvaluateFitModel
  -> mrlfeBuildFitSolveRequest
  -> mrlfeSolve
```

The fitting adapter does not select low-level trackers, fallback, or quality
logic. It translates app input into the fitting workflow and normalizes the
final fit result. Main GUI and SweepTool mRLFE routes are not migrated in this
phase.

## Configuration

`mrlfeResolveConfiguration` merges the request with public defaults, validates
physical inputs and policies, resolves the numerical preset, and reports neutral
effective engine names:

```text
elastic_adaptive
viscoelastic_adaptive
```

Numerical preset remains separate from branch policy, termination, and fallback.

## Problem Construction

`mrlfeBuildProblem` prepares:

```text
requested frequency grid
internal solve grid
Rayleigh-Lamb seed result
material
geometry
fluid properties
branch name
```

The Rayleigh-Lamb dependency is isolated in the model layer and is used only to
build seed modes. It disables unrelated mRLFE routes when computing the seed.

## Elastic Path

`mrlfeSolveElasticBranch` reproduces the zero-viscosity adaptive behavior used by
the maintained FitTool route:

```text
seed construction
adaptive branch tracking
optional A0 physical-tail termination
resampling to the requested frequency grid
```

It deliberately does not use the direct elastic modal branch as the production
zero-viscosity baseline.

## Viscoelastic Path

`mrlfeSolveViscoelasticBranch` reproduces the viscous adaptive behavior used by
the maintained FitTool route:

```text
seed construction
viscoelastic adaptive tracking options
adaptive branch tracking
optional A0 physical-tail termination
S0 continuation behavior
resampling to the requested frequency grid
```

`fast` maps to 260 scan points, 5 candidates, no refinement, and reduced
adaptive windows. `dense` maps to 900 scan points, 8 candidates, refinement, and
maintained dense adaptive windows.

## Tracking

`mrlfeTrackBranchAdaptive` is the neutral production entry point for adaptive
tracking. It currently delegates to the maintained lower-level adaptive tracker
to avoid duplicating the numerical algorithm while the public architecture is
being separated.

## Termination

`mrlfeApplyTerminationPolicy` centralizes initial production policies:

```text
physicalTail  applies the A0 physical-tail policy when requested
none          applies no additional termination policy
continuity    preserves existing adaptive-continuation semantics
```

No fallback occurs in termination policy handling.

## Result Construction

`mrlfeBuildInternalBranchResult` normalizes the internal branch result and
preserves diagnostic raw output. `mrlfeBuildResult` remains the public schema
builder for units, vector orientation, invalid-value handling, execution
metadata, termination metadata, fallback metadata, and quality metadata.

FitTool fitting preserves the public `modelResult` in the compatibility-shaped
fitting raw result. The compatibility fields still consumed by FitTool are the
branch identity, requested frequencies, fitted Cp values, valid mask, route path
metadata, preset metadata, and raw branch diagnostics used by full-curve
diagnostics. New metadata comes from `mrlfeBuildResult`: requested/effective
preset, neutral internal engine, termination policy, fallback policy/applied
state, and quality summary.

## Remaining Transitional Dependencies

The production core still calls these maintained lower-level helpers:

| Responsibility | Current helper |
| --- | --- |
| Seed construction logic | `mrlfeMakePhysicalSeedMode` |
| Adaptive tracking algorithm | `solveMRLFEBranchAdaptiveAtlas` |
| A0 physical-tail cut | `mrlfeApplyPhysicalCorridorCut` |

These dependencies are implementation details. The next migration phase should
move or rename the lower-level helpers behind neutral model-layer names without
changing numerical behavior.

`mrlfeEvaluateAtlasFitModel` remains available only as a transitional
diagnostic/reference oracle for characterization and migration tests. It should
not be used as the maintained FitTool production evaluator.

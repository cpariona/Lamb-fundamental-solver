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
            -> rlComputeFundamentalLambModes
       -> mrlfeTrackBranchAdaptive
       -> mrlfeApplyTerminationPolicy
  -> mrlfeBuildResult
```

The core preserves the audited FitTool atlas-first numerical behavior without
calling `mrlfeEvaluateAtlasFitModel`, `mrlfeEvaluateFitModel`, or GUI adapters.
Main GUI forward solving reaches this core through the public API:

```text
guiRunMRLFEModel
  -> mrlfeBuildGuiSolveRequest
  -> mrlfeSolve
```

The Main GUI adapter translates app input and adapts the public result for
plotting/export compatibility. It does not select low-level trackers, apply
physical-tail cuts, or perform zero-viscosity fallback.

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
final fit result.

SweepTool mRLFE forward sweeps also reach this core through the public API:

```text
guiRunMRLFESweep
  -> mrlfeBuildSweepSolveRequest
  -> mrlfeSolve, once per sweep point
```

The sweep adapter translates each point into a public model request and
normalizes point and aggregate metadata. It does not call the Main GUI adapter,
select low-level trackers, or apply fallback.

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
material
geometry
fluid properties
branch name
```

`mrlfeBuildSeed` is the sole owner of the intentional Rayleigh-Lamb dependency.
It requests the matching fundamental RL branch, converts that result into the
mRLFE seed mode, and preserves the raw seed result as diagnostic evidence. RL
does not expose or disable any mRLFE route while producing this seed.

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
tracking. The maintained candidate generation, prediction, residual scoring,
candidate selection, validity decisions, and adaptive continuation diagnostics
now live behind this neutral model-layer name.

For A0Like, `mrlfeTrackBranchRobustStart` first attempts ordinary forward
tracking and then probes the configured candidate start frequencies only when
the required valid run is not established. It tracks forward from the first
stable candidate; earlier frequencies remain invalid and no backward tracking
or solver fallback is introduced. S0Like does not use this policy. The focused
contract is `test_mrlfe_robust_start_contract`.

## Termination

`mrlfeApplyTerminationPolicy` centralizes initial production policies:

```text
physicalTail  applies the A0 physical-tail policy when requested
none          applies no additional termination policy
continuity    preserves existing adaptive-continuation semantics
```

No fallback occurs in termination policy handling.

The A0 physical-tail evaluation is implemented by
`mrlfeEvaluatePhysicalTail`, a neutral production helper called only through
`mrlfeApplyTerminationPolicy`. The policy name remains `physicalTail`; no
`physicalCorridor` public policy is exposed.

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

Main GUI preserves the public `modelResult` for each requested visible branch
under normalized metadata. Its compatibility raw result keeps the existing
`models.mRLFERealK.branches.<branch>` shape required by normalized plotting,
workspace inspection, and compact exports, but the branch data is adapted from
`mrlfeBuildResult` output. Partial-quality results remain visible and are
reported with neutral status metadata instead of being replaced by fallback.

SweepTool stores the same public `modelResult` for each sweep point. Aggregate
sweep metadata reports unique effective presets, engines, termination policies,
and fallback policies across all points, plus point counts and failure counts,
instead of reporting one point's route as sweep-wide state. The maintained
SweepTool route uses the public `fast` preset, adaptive selection, no fallback,
`physicalTail` termination for A0Like, and `none` termination for S0Like.

## Neutralized Helper Dependencies

The maintained production core no longer depends on the historically named
seed, adaptive tracker, or A0 tail-cut helpers. Their maintained implementations
now reside behind:

```text
mrlfeBuildSeed
mrlfeTrackBranchAdaptive
mrlfeApplyTerminationPolicy
  -> mrlfeEvaluatePhysicalTail
```

The old historical helper files have been removed from the maintained
production surface. Broad legacy routes such as `computeMRLFE`,
`solveMRLFEAtlasUnified`, `solveMRLFEViscoBranchAtlas`,
`solveMRLFEBranchModalAtlas`, `solveMRLFEBranchDP`, and
`mrlfeEvaluateAtlasFitModel` have also been removed. Historical route-audit
documents may still mention those names as pre-migration evidence, but they are
not callable maintained entrypoints.

# mRLFE production core

Last reviewed: 2026-09-04

## Scope

The real-k mRLFE public API now executes through a model-layer production core:

```text
lamb.models.mrlfe.mrlfeSolve
  -> lamb.models.mrlfe.configuration.mrlfeResolveConfiguration
  -> lamb.models.mrlfe.core.mrlfeBuildProblem
  -> lamb.models.mrlfe.solvers.mrlfeSolveBranch
       -> lamb.models.mrlfe.solvers.mrlfeSolveElasticBranch
       -> lamb.models.mrlfe.solvers.mrlfeSolveViscoelasticBranch
       -> lamb.models.mrlfe.tracking.mrlfeBuildSeed
            -> lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes
       -> lamb.models.mrlfe.tracking.mrlfeTrackBranchAdaptive
       -> lamb.models.mrlfe.policies.mrlfeApplyTerminationPolicy
  -> lamb.models.mrlfe.results.mrlfeBuildResult
```

The core owns model physics and tracking without calling analysis evaluators
or application adapters. Main GUI forward solving reaches this core through the public API:

```text
guiRunMRLFEModel
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve
```

The Main GUI adapter translates app input and adapts the public result for
plotting/export presentation. It does not select low-level trackers, apply
physical-tail cuts, or perform zero-viscosity fallback.

FitTool fitting now reaches this core through the public API:

```text
guiFitMRLFESolver
  -> lamb.fitting.mrlfe.mrlfeFitDispersionData
  -> lamb.fitting.solveDispersionFitProblem
  -> lamb.fitting.mrlfe.mrlfeEvaluateFitModel
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve
```

The fitting adapter does not select low-level trackers, fallback, or quality
logic. It translates app input into the fitting workflow and normalizes the
final fit result.

mRLFE sensitivity studies also reach this core through the public API:

```text
runMRLFESensitivity
  -> lamb.sweeps.runParametricSweep
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve, once per sweep point
```

The opt-in study translates each point into a public model request. It does not
call an app adapter, select low-level trackers, or apply fallback.

## Configuration

`lamb.models.mrlfe.configuration.mrlfeResolveConfiguration` merges the request with public defaults, validates
physical inputs and policies, resolves the numerical preset, and reports neutral
effective engine names:

```text
elastic_adaptive
viscoelastic_adaptive
```

Numerical preset remains separate from branch policy, termination, and fallback.
Candidate refinement is not a public preset choice. All maintained presets use
the same internal selected-candidate continuous refinement policy.

Fast uses a two-stage Cp scan internally: 100 coarse points for ordinary local
minimum tracking and a 260-point rescue scan only when the coarse pass returns a
valley fallback or no valid candidate. Balanced, Robust, and Dense keep fixed
scan densities of 420, 620, and 900 points respectively and therefore do not
perform an additional rescue scan.

## Problem Construction

`lamb.models.mrlfe.core.mrlfeBuildProblem` prepares:

```text
requested frequency grid
internal solve grid
material
geometry
fluid properties
branch name
```

`lamb.models.mrlfe.tracking.mrlfeBuildSeed` is the sole owner of the intentional Rayleigh-Lamb dependency.
It requests the matching fundamental RL branch, converts that result into the
mRLFE seed mode, and preserves the raw seed result as diagnostic evidence. RL
does not expose or disable any mRLFE route while producing this seed.

## Elastic Path

`lamb.models.mrlfe.solvers.mrlfeSolveElasticBranch` reproduces the zero-viscosity adaptive behavior used by
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

`lamb.models.mrlfe.solvers.mrlfeSolveViscoelasticBranch` reproduces the viscous adaptive behavior used by
the maintained FitTool route:

```text
seed construction
viscoelastic adaptive tracking options
adaptive branch tracking
optional A0 physical-tail termination
S0 continuation behavior
resampling to the requested frequency grid
```

The public numerical presets differ in internal frequency step, Cp scan density,
candidate budget, and adaptive windows. They do not select different candidate
refinement algorithms.

## Tracking

`lamb.models.mrlfe.tracking.mrlfeTrackBranchAdaptive` is the neutral production entry point for adaptive
tracking. The maintained candidate generation, prediction, residual scoring,
candidate selection, validity decisions, and adaptive continuation diagnostics
now live behind this neutral model-layer name.

The production lifecycle is:

```text
coarse local Cp scan
-> strict local-minimum discovery
-> optional dense rescue scan when coarse tracking is ambiguous
-> discrete candidate scoring and selection
-> bounded continuous refinement of the selected strict minimum
-> validity and continuation checks
```

The dense rescue repeats the same search window and scoring policy at higher Cp
resolution. It does not change branch policy, prediction, continuation limits,
or residual definition. The Fast rescue trigger is intentionally narrow:
`valleyFallback` or no valid coarse candidate.

The bounded refinement uses the true mRLFE residual through `fminbnd`; it is
applied only after candidate identity is selected. This removes Cp scan
quantization without allowing the continuous refinement step to choose a
different branch candidate.

For established A0Like branches, the optional valley fallback is reserved for
shallow shoulders that are not already represented by a strict local minimum.
A fallback candidate is not added when the same trust region already contains a
strict minimum, preventing duplicate representations of the same residual valley.

For A0Like, `lamb.models.mrlfe.tracking.mrlfeTrackBranchRobustStart` first attempts ordinary forward
tracking and then probes the configured candidate start frequencies only when
the required valid run is not established. It tracks forward from the first
stable candidate; earlier frequencies remain invalid and no backward tracking
or solver fallback is introduced. S0Like does not use this policy. The focused
contract is `test_mrlfe_robust_start_contract`.

## Termination

`lamb.models.mrlfe.policies.mrlfeApplyTerminationPolicy` centralizes initial production policies:

```text
physicalTail  applies the A0 physical-tail policy when requested
none          applies no additional termination policy
continuity    preserves existing adaptive-continuation semantics
```

No fallback occurs in termination policy handling.

The A0 physical-tail evaluation is implemented by
`lamb.models.mrlfe.policies.mrlfeEvaluatePhysicalTail`, a neutral production helper called only through
`lamb.models.mrlfe.policies.mrlfeApplyTerminationPolicy`. The policy name remains `physicalTail`; no
`physicalCorridor` public policy is exposed.

## Result Construction

`lamb.models.mrlfe.results.mrlfeBuildInternalBranchResult` normalizes the internal branch result and
preserves diagnostic raw output. `lamb.models.mrlfe.results.mrlfeBuildResult` remains the public schema
builder for units, vector orientation, invalid-value handling, execution
metadata, termination metadata, fallback metadata, and quality metadata.

FitTool fitting preserves the final public evaluation under
`fitResult.modelEvaluation`. Metadata comes from `lamb.models.mrlfe.results.mrlfeBuildResult`: requested/effective
preset, neutral internal engine, termination policy, fallback policy/applied
state, and quality summary.

Main GUI preserves the completed public `modelResult` and derives a shallow
presentation view for plotting and export. Partial-quality results remain visible and are
reported with neutral status metadata instead of being replaced by fallback.

Sensitivity studies store the public result for each point and may summarize
effective presets, engines, termination policies, and fallback policies. The
representative study uses the public `fast` preset, adaptive selection, no
fallback, `physicalTail` termination for A0Like, and `none` for S0Like.

## Boundary

Seed, tracking, termination, result construction, and quality are model-owned.
Human consumers reach this core through lamb.models.mrlfe.mrlfeSolve. No production dependency
points back to studies, app, tests, or executable examples/diagnostics.

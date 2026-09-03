# mRLFE public API

Last reviewed: 2026-09-03

## Scope

The maintained model-oriented entry point for real-k mRLFE solving is:

```matlab
result = mrlfeSolve(request);
```

Main GUI, FitTool, and SweepTool consume this model-owned API. Application
adapters translate units and policies but do not own tracking or physics.

## Request

`mrlfeSolve` accepts one struct. The public concepts are intentionally separate:

```matlab
request.branch = "A0Like";
request.frequency_Hz = frequency_Hz;

request.material = struct( ...
    'mu_Pa', 75e3, ...
    'etaS_Pas', 0.05, ...
    'rho_kgm3', 1000, ...
    'nu', 0.4999);

request.geometry = struct('thickness_m', 0.5e-3);

request.fluid = struct( ...
    'density_kgm3', 1000, ...
    'soundSpeed_mps', 1500);

request.numerics = struct('preset', "fast");
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");
```

Supported branches are:

```text
A0Like
S0Like
```

Unsupported branches, presets, physical inputs, policies, and nonascending or
invalid frequency grids fail with stable `mrlfe:*` error identifiers.

## Defaults

Use:

```matlab
params = mrlfeDefaultParameters();
options = mrlfeDefaultOptions();
```

The default physical values are `mu_Pa = 75e3`, `etaS_Pas = 0.05`,
`rho_kgm3 = 1000`, `nu = 0.4999`, `thickness_m = 0.5e-3`,
`fluidDensity_kgm3 = 1000`, and `fluidSoundSpeed_mps = 1500`.

Default policies are:

```text
numerical preset   fast
selection strategy adaptive
A0 termination     physicalTail
S0 termination     none
fallback policy    none
```

The API never substitutes another branch as fallback.

## Presets

Public requests select `request.numerics.preset` as `"fast"`, `"balanced"`,
`"robust"`, or `"dense"`.
`mrlfeGetNumericalPreset` is the internal configuration owner that resolves
those names; it is not an additional public API.

`fast` maps to the maintained FitTool fast-atlas settings:

```text
scan points       260
candidate count   5
candidate refine  false
adaptive windows  [0.20 0.40 0.80]
```

`balanced` uses 420 scan points and 6 refined candidates; `robust` uses
620 scan points and 8 refined candidates. Their high-frequency grid steps are
25 and 20 Hz respectively (Fast 50 Hz, Dense 10 Hz).

`dense` maps to the maintained dense atlas settings:

```text
scan points       900
candidate count   8
candidate refine  true
adaptive windows  maintained dense adaptive windows
```

Preset resolution does not change branch policy or fallback policy.

## Result

Successful calls return one normalized schema:

```matlab
result.model
result.branch
result.frequency_Hz
result.phaseVelocity_mps
result.wavenumber_radpm
result.validMask
result.quality
result.termination
result.fallback
result.execution
result.configuration
```

Vectors are column vectors on the requested frequency grid. Invalid points are
represented by `NaN` phase velocity and `validMask = false`.

Quality metadata includes valid count, point count, valid fraction, last valid
frequency, maximum relative jump, accepted flag, reason, and thresholds. A
partial branch is still returned when `quality.accepted` is false.

Termination metadata reports whether a physical-tail or continuity cut was
observed from the underlying branch. Neutral defaults are used when no cut was
reported.

Fallback metadata is explicit. The maintained fallback contract is:

```matlab
result.fallback.policy = "none";
result.fallback.applied = false;
```

Execution metadata reports requested preset, effective preset, internal engine,
and elapsed seconds as distinct fields.

Configuration is explicitly split:

```matlab
result.configuration.requested
result.configuration.effective
```

The first preserves the caller request. The second records resolved physical
parameters, output frequency grid, numerical preset, policies, and engine.

The production implementation path is neutral:

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
            -> mrlfeEvaluatePhysicalTail
  -> mrlfeBuildResult
```

## Main GUI Use

The maintained Main GUI mRLFE chain is:

```text
LambFundamental_GUI
  -> guiRunMRLFEModel
  -> mrlfeBuildSolveRequest
  -> mrlfeSolve
  -> GUI result adapter
```

The GUI request mapper translates the current Main GUI SI parameters (`mu`,
`etaS`, `rho`, `nu`, `thickness`, fluid density, fluid sound speed, frequency
grid, and branch toggles) to the public material, geometry, and fluid fields.
The Main GUI defaults to `Balanced`, which maps directly to public preset
`balanced`; explicit Fast and Robust selections map to `fast` and `robust`.
A0Like uses adaptive
selection with `physicalTail` termination and no fallback. S0Like uses adaptive
selection with no additional termination and no fallback.

Main GUI no longer contains mRLFE seed construction, low-level tracker
selection, atlas candidate inspection, physical-tail cutting, or zero-viscosity
fallback logic. Partial-quality public results are returned and reported with
their `quality.accepted` and `quality.reason` metadata; the GUI does not replace
them with a legacy branch.

## FitTool Fitting Use

The maintained FitTool mRLFE fitting chain is:

```text
FitTool_GUI
  -> guiFitMRLFESolver
  -> mrlfeFitDispersionData
  -> solveDispersionFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeBuildSolveRequest
  -> mrlfeSolve
```

The fitting request mapper translates the existing SI fitting parameters
(`mu`, `etaS`, `rho`, `nu`, `thickness`, fluid density, and fluid sound speed)
to public material, geometry, and fluid fields. FitTool defaults to Fast while
preserving direct Fast/Balanced/Robust preset mapping. A0Like fitting uses adaptive selection with
`physicalTail` termination and no fallback. S0Like fitting uses adaptive
selection with no additional termination and no fallback.

Objective evaluations, automatic full-curve diagnostics, and explicit requested
fitted-curve evaluations use the same public solver route with the final fitted
parameters. Characterization compares maintained consumers directly against `mrlfeSolve`.

## SweepTool Use

The maintained SweepTool mRLFE chain is:

```text
SweepTool_GUI
  -> guiBuildSweepRequest
  -> guiRunSweep
  -> guiRunMRLFESweep
  -> runParametricSweep
  -> mrlfeBuildSolveRequest
  -> mrlfeSolve, once per sweep point
```

The sweep request mapper translates current SweepTool SI parameters (`mu`,
`etaS`, `rho`, `nu`, `thickness`, fluid density, and fluid sound speed) to the
public material, geometry, and fluid fields. The maintained SweepTool preset is
public `fast`. A0Like sweeps use adaptive selection with `physicalTail`
termination and no fallback. S0Like sweeps use adaptive selection with no
additional termination and no fallback.

SweepTool no longer delegates mRLFE solving to `guiRunMRLFEModel` and no longer
inherits Main GUI zero-viscosity fallback. Each point stores the full public
model result under `sweepResult.points{i}.modelResult`; aggregate sweep metadata
reports all unique effective engines, presets, termination policies, and
fallback policies represented by the points.

## Diagnostics and debug boundary

Stable diagnostic summary fields live directly under `result.diagnostics`.
Complete internal solver state is explicitly unstable and has one owner under
`result.debug.solverResult`. It is not duplicated under diagnostics, and
application adapters do not inspect it.

## Algorithm and limitations

See `production_core.md` for model-layer algorithm ownership. The engines are
`elastic_adaptive` for etaS=0 and `viscoelastic_adaptive` for etaS>0.
The real-k approximation does not solve a complex-wavenumber attenuation
problem. Branches may be partial or quality-rejected; validMask and quality
must be honored. Do not infer physical absence solely from a numerical cut.

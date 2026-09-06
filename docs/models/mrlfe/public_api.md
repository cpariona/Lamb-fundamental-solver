# mRLFE public API

Last reviewed: 2026-09-05

## Scope

The maintained model-oriented entry point for real-k mRLFE solving is:

```matlab
result = lamb.models.mrlfe.mrlfeSolve(request);
```

Main GUI, FitTool, and SweepTool consume this model-owned API. Application
adapters own surface state and presentation, but canonical mRLFE request
translation is model-owned by `lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest` under
`src/+lamb/+models/+mrlfe/+configuration/`.

## Request

`lamb.models.mrlfe.mrlfeSolve` accepts one struct. The public concepts are intentionally separate:

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

`lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest` is the reusable translation owner for maintained
workflow/app aliases such as `mu`, `rho`, `thickness`, `etaS`, fluid density,
fluid sound speed, execution profile, and branch name. It produces the canonical
request above and is independent of GUI handles, fitting, sweeps, and plotting.

## Defaults

Use:

```matlab
params = lamb.models.mrlfe.mrlfeDefaultParameters();
options = lamb.models.mrlfe.mrlfeDefaultOptions();
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
`lamb.models.mrlfe.configuration.mrlfeGetNumericalPreset` is the model configuration owner that resolves those
names; it is not an additional public API.

The maintained presets are:

| Preset | High-frequency step | Coarse Cp scan | Rescue Cp scan | Candidate count |
| --- | ---: | ---: | ---: | ---: |
| `fast` | 50 Hz | 100 | 260 | 5 |
| `balanced` | 25 Hz | 420 | 420 | 6 |
| `robust` | 20 Hz | 620 | 620 | 8 |
| `dense` | 10 Hz | 900 | 900 | 8 |

Fast therefore uses the optimized policy introduced by the numerical-alignment
campaign: a 100-point coarse scan is used for normal candidate discovery and a
260-point dense scan is used only as rescue when needed. Candidate discovery is
discrete; after one candidate is selected, the selected candidate is refined
continuously with bounded refinement. This does not smooth or post-process the
reported dispersion curve.

The adaptive windows are:

```text
fast      [0.20 0.40 0.80]
balanced  [0.20 0.35 0.50 0.80]
robust    [0.20 0.35 0.50 0.80 1.20]
dense     [0.20 0.35 0.50 0.80 1.20]
```

All presets retain the maintained hybrid frequency-grid policy with fixed
low-frequency anchors up to 500 Hz and the preset-specific constant step above
that transition. Preset resolution does not change branch policy or fallback
policy.

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

Quality metadata includes the common lower-camel core fields
`pointCount`, `validCount`, `validFraction`, `accepted`, and `reason`, plus
model-specific branch-quality evidence. A partial branch is still returned when
`quality.accepted` is false.

Termination metadata reports whether a physical-tail or continuity cut was
observed from the underlying branch. Neutral defaults are used when no cut was
reported.

Fallback metadata is explicit. The maintained fallback contract is:

```matlab
result.fallback.policy = "none";
result.fallback.applied = false;
```

Execution metadata includes the common fields `engine` and `elapsedSeconds`,
plus mRLFE preset/engine evidence required by maintained consumers.

Configuration follows the shared requested/effective envelope:

```matlab
result.configuration.requested.parameters
result.configuration.requested.options
result.configuration.effective.parameters
result.configuration.effective.options
```

`requested` records the canonical values explicitly supplied by the caller in
parameter/option form; omitted requested values remain absent/empty in that
requested view. `effective` records the resolved physical parameters, output
frequency grid, numerical preset, policies, material regime, and internal engine
after defaults and validation are applied. The raw caller struct is not exposed
as a parallel public alias.

The production implementation path is neutral:

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
            -> lamb.models.mrlfe.policies.mrlfeEvaluatePhysicalTail
  -> lamb.models.mrlfe.results.mrlfeBuildResult
```

The only intentional cross-family dependency is `lamb.models.mrlfe.tracking.mrlfeBuildSeed ->
lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes` for the scientific seed.

## Main GUI Use

The maintained Main GUI mRLFE chain is:

```text
LambFundamental_GUI
  -> guiRunMRLFEModel
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve
  -> GUI result adapter
```

The request builder translates the current Main GUI SI parameters (`mu`,
`etaS`, `rho`, `nu`, `thickness`, fluid density, fluid sound speed, frequency
grid, and branch toggles) to the public material, geometry, and fluid fields.
The Main GUI defaults to `Balanced`, which maps directly to public preset
`balanced`; explicit Fast and Robust selections map to `fast` and `robust`.
A0Like uses adaptive selection with `physicalTail` termination and no fallback.
S0Like uses adaptive selection with no additional termination and no fallback.

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
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve
```

The fitting workflow translates the existing SI fitting parameters (`mu`,
`etaS`, `rho`, `nu`, `thickness`, fluid density, and fluid sound speed) through
the same model-owned request builder. FitTool defaults to Fast while preserving
direct Fast/Balanced/Robust preset mapping. A0Like fitting uses adaptive
selection with `physicalTail` termination and no fallback. S0Like fitting uses
adaptive selection with no additional termination and no fallback.

Objective evaluations, automatic full-curve diagnostics, and explicit requested
fitted-curve evaluations use the same public solver route with the final fitted
parameters. Characterization compares maintained consumers directly against
`lamb.models.mrlfe.mrlfeSolve`.

## SweepTool Use

The maintained SweepTool mRLFE chain is:

```text
SweepTool_GUI
  -> guiBuildSweepRequest
  -> guiRunSweep
  -> guiRunMRLFESweep
  -> runParametricSweep
  -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest
  -> lamb.models.mrlfe.mrlfeSolve, once per sweep point
```

The sweep workflow translates current SweepTool SI parameters (`mu`, `etaS`,
`rho`, `nu`, `thickness`, fluid density, and fluid sound speed) through the same
model-owned request builder. The maintained SweepTool default is public `fast`.
A0Like sweeps use adaptive selection with `physicalTail` termination and no
fallback. S0Like sweeps use adaptive selection with no additional termination
and no fallback.

SweepTool no longer delegates mRLFE solving to `guiRunMRLFEModel`. Each point
stores the full public model result under `sweepResult.points{i}.modelResult`;
aggregate sweep metadata reports the effective engines, presets, termination
policies, and fallback policies represented by the points.

## Diagnostics and debug boundary

Stable diagnostic summary fields live under `result.diagnostics`. Complete
internal solver state is explicitly unstable and has one owner under
`result.debug.solverResult`. It is not duplicated under diagnostics, and
application adapters do not inspect it.

## Algorithm and limitations

See `production_core.md` for model-layer algorithm ownership. The engines are
`elastic_adaptive` for etaS=0 and `viscoelastic_adaptive` for etaS>0.
The real-k approximation does not solve a complex-wavenumber attenuation
problem. Branches may be partial or quality-rejected; `validMask` and quality
must be honored. Do not infer physical absence solely from a numerical cut.

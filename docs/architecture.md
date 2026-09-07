# Repository architecture

Lamb Fundamental Solver has two primary scientific capabilities: forward
dispersion solving and inverse fitting. Every maintained responsibility has one
semantic owner.

## Ownership map

- `src/+lamb/+models/` owns the Rayleigh-Lamb, mRLFE, and acoustoelastic
  IOP/HGO forward models, including equations, tracking, policies, quality, and
  canonical results.
- `src/+lamb/+fitting/` owns family fit APIs, fit-problem construction,
  residuals, optimization, and neutral fitting metrics. It evaluates models
  only through their canonical forward APIs.
- `src/+lamb/+elasticity/` owns model-neutral isotropic elastic conversions.
- `src/+lamb/+grids/` owns neutral frequency/discretization construction.
- `src/+lamb/+sweeps/` owns only the generic repeated-evaluation primitive.
- `app/solver/` and `app/fitting/` own the two GUI workflows. The root GUI
  files are `LambFundamental_GUI` and `FitTool_GUI`.
- `app/execution_profiles/` translates Fast, Balanced, and Robust surface
  requests; `app/utilities/` contains only small helpers shared by both GUIs.
- `studies/sensitivity/` and `studies/solver_diagnostics/` own opt-in research
  campaigns and investigations.
- `examples/` contains six short, opt-in solver and fitting demonstrations.
- `tests/` mirrors these owners and keeps runners, repository guards, and test
  tooling explicit.

The dependency direction is:

```text
GUI -> fitting API -> model API -> model implementation
GUI ----------------> model API -> model implementation
study -> sweep primitive and/or maintained API
example -> maintained API
```

Models never depend on fitting, app, studies, examples, or tests. Production
never depends on studies, examples, or tests. The sole intentional scientific
cross-family route is the documented mRLFE seed through the Rayleigh-Lamb
solver.

## Human interfaces and execution profiles

`runApp` launches `LambFundamental_GUI`; `FitTool_GUI` is the independent fitting
surface. The GUIs coordinate requests and presentation while scientific owners
calculate. Export serializes an existing result and never recomputes it.

The execution-profile metadata contract records requested and effective
profiles, numerical presets, override evidence, supported profiles, surface,
and quality information. The established `robustness` compatibility alias is
accepted only at app normalization boundaries; `executionProfile` is the
canonical surface field. Profiles control numerical effort, not physical
meaning.

## Maintained public surface

Run `startup` before using these entrypoints:

```matlab
runApp
LambFundamental_GUI
FitTool_GUI
lamb.models.rayleigh_lamb.rlDefaultParams
lamb.models.rayleigh_lamb.rlDefaultOptions
lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes
lamb.models.rayleigh_lamb.approximations.rlComputeAnalyticalApproximations
lamb.models.mrlfe.mrlfeDefaultParameters
lamb.models.mrlfe.mrlfeDefaultOptions
lamb.models.mrlfe.mrlfeSolve
lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions
lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch
lamb.fitting.rayleigh_lamb.rlFitDispersionData
lamb.fitting.rayleigh_lamb.rlEvaluateFitModel
lamb.fitting.mrlfe.mrlfeFitDispersionData
lamb.fitting.mrlfe.mrlfeEvaluateFitModel
lamb.fitting.mrlfe.mrlfeDefaultFitParameters
lamb.fitting.mrlfe.mrlfeDefaultFitOptions
lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData
lamb.fitting.acoustoelastic_iop_hgo.aeEvaluateFitModel
lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitParameters
lamb.fitting.acoustoelastic_iop_hgo.aeDefaultFitOptions
lamb.sweeps.runParametricSweep
```

## Canonical result contracts

Official curves use column vectors named `frequency_Hz`,
`phaseVelocity_mps`, `wavenumber_radpm`, and `validMask`. Invalid phase velocity
is `NaN` and has `validMask = false`. Core quality fields are `pointCount`,
`validCount`, `validFraction`, `accepted`, and `reason`. Results expose requested
and effective parameters/options under `configuration`, plus execution metadata
containing at least `engine` and `elapsedSeconds`.

Model-specific scientific details live under [models](models/). Validation
policy is documented in [validation.md](validation.md), and maintainability
rules in [conventions.md](conventions.md).

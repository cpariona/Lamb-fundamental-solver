# Repository structure

## Ownership

```text
models/
  materials/
  shared/                  neutral cross-family infrastructure
  rayleigh_lamb/           api, configuration, core, solvers, tracking, quality, results
  mrlfe/                   api, configuration, core, solvers, tracking, policies, quality, results
  acoustoelastic_iop_hgo/ api, configuration, constitutive, core, solvers, tracking, policies, quality, results
analysis/
  fitting/                shared optimizer and model-specific evaluators
  sweeps/                 shared 1D iteration and model workflows; explicit AE 2D
  requests/               mRLFE SI request translation
  plotting/               render completed sweep results
  io/                     output paths and persistence
  diagnostics/            reusable inspection of scientific evidence
app/
  LambFundamental_GUI.m
  FitTool_GUI.m
  SweepTool_GUI.m
  main/                   controls, model translation, result view, export
  fitting/                experimental data, fit request, fit view
  sweep/                  sweep request, result view, interactive grid plot
  shared/                 execution profiles and shared struct translation
examples/<family>/        basic, fitting, sweeps, optional diagnostics
tests/                    app, models, shared, runners, tooling
docs/                     current contracts and operating handoff
```

The common model-family spine is `api/configuration/core/solvers/tracking/quality/results` where the responsibility exists. Scientific directories such as RL `equations/` and `approximations/`, AE `constitutive/`, and model-specific `policies/` remain where justified; empty directories are not created for appearance.

## Dependency contract

| Caller | Allowed scientific/workflow dependencies | Forbidden |
| --- | --- | --- |
| models | own internals, shared materials/infrastructure; mRLFE seed may call RL | app, analysis, examples, tests |
| analysis | analysis and models | app, examples, tests |
| app | app, analysis, models | examples, tests |
| examples/diagnostics | maintained APIs and scientific inspection | ownership of production calculations |
| tests | all maintained layers | becoming a production dependency |

The only intentional cross-family seed edge is
`mrlfeBuildSeed -> rlComputeFundamentalLambModes`. RL never calls mRLFE.
Generic infrastructure is model-neutral; model-family code must not use another
family merely as a utility owner.

Model-owned AE diagnostic candidate construction is an explicitly requested
inspection mode; it does not select production branches. Executable diagnostic
scripts live under examples. Benchmark/matrix tooling that calls app surfaces
lives under tests, not analysis.

## Canonical owners

| Responsibility | Owner |
| --- | --- |
| RL public API | `rlComputeFundamentalLambModes` and RL public defaults under `api/` |
| RL configuration | RL frequency wrapper and validation under `configuration/` |
| RL physics/tracking | RL residuals, model solver, and `rlSolveFundamentalBranch` |
| mRLFE physics/tracking | mRLFE matrix/residual and adaptive tracking |
| AE public API | `solveAcoustoelasticIOPHGOBranch` under `api/` |
| AE physics/tracking | constitutive/SVD objective, discrete atlas linking, selected-branch `fminbnd` refinement |
| Public scientific results | `rlBuildResult`, `mrlfeBuildResult`, `aeBuildResult` |
| Quality | `rlEvaluateModeQuality`, `mrlfeEvaluateBranchQuality`, `aeEvaluateAtlasA0Quality` |
| Fitting optimizer | `solveDispersionFitProblem` |
| 1D sweep iteration | `runParametricSweep` |
| AE 2D sweep | `aeRunGridSweep` |
| Execution profiles | app/shared model-specific resolvers |
| Main GUI view/export | app/main; export serializes existing curves |
| Plotting | app surface renderers and analysis/plotting |
| Validation | six runners and opt-in tests/tooling |

Model results distinguish official SI arrays, quality, diagnostics,
`configuration.requested`, `configuration.effective`, and operational execution
metadata. Requested/effective configuration uses `parameters` and `options`
substructures. RL branches live naturally under `modes.A0`/`modes.S0`. mRLFE
internal state has one owner at `debug.solverResult`. AE diagnostic candidates
live under `diagnostics.identityA0`. Display curves are not alternate scientific
results.

## Paths and invocation

`startup` resets repository-owned paths, adds root plus maintained models,
analysis, and app trees, and exposes only `tests/runners/` as a narrow
validation-launcher exception. Test bodies/tooling and examples are not
globally loaded. Source `results/` directories contain result builders and
must not be confused with generated root `Results/`.

Each runner calls `configureTestPath` from tests/tooling, executes its explicit
test list in a local workspace, and restores the caller path with `onCleanup`.
Maintained direct tests are functions and do not configure their own path or
publish scientific outputs into the base workspace. Individual tests can be
run after explicitly adding tests/tooling and invoking `configureTestPath`.
Call `startup` to return to production-only operation.

Examples bootstrap root from `mfilename('fullpath')` and are run by file path.
Generated output roots are `Results/rayleigh_lamb/`, `Results/mrlfe/`, and
`Results/ae_iop_hgo/`. Validation exports use `Results/validation/`.
Generated results, figures, and archives are never source paths.

[Human call traces](../workflows/gui/adapter_architecture.md) and
[test ownership](../../tests/README.md) complete this map.

# Repository structure

## Ownership

```text
src/+lamb/
  +models/                  canonical forward solvers
  +fitting/                 inverse fitting and neutral fitting primitives
  +elasticity/              neutral elastic conversions
  +grids/                   neutral grid construction
  +sweeps/
    runParametricSweep.m    generic repeated-evaluation engine only
app/
  LambFundamental_GUI.m
  FitTool_GUI.m
  main/                     solver request/view/export adapters
  fitting/                  fitting request/view adapters
  shared/                   transitional app utilities and profile translation
studies/
  sensitivity/
    rayleigh_lamb/
    mrlfe/
    acoustoelastic_iop_hgo/
  solver_diagnostics/
    mrlfe/
    acoustoelastic_iop_hgo/
examples/<family>/          short basic and fitting API demonstrations only
tests/                      app, models, fitting, sweeps, studies, runners, tooling
docs/                       scientific and architectural contracts
```

`analysis/`, `app/sweep/`, and the SweepTool GUI are retired. No generic
`shared/` owner exists under production or studies. The remaining
`app/shared/` organization is an app-only transitional concern reserved for a
later app canonicalization phase.

## Dependency contract

| Caller | Allowed dependencies | Forbidden |
| --- | --- | --- |
| models | own internals and neutral infrastructure; documented mRLFE seed may call RL | fitting, app, studies, examples, tests |
| fitting | canonical model APIs and neutral fitting primitives | app, studies, examples, tests |
| sweeps | callback-driven parameter iteration only | models, fitting, app, studies, examples, tests |
| app | app helpers, fitting, and model APIs | studies, examples, tests |
| studies | canonical APIs and study-local interpretation/rendering/persistence | app, examples, ownership of production algorithms |
| examples | maintained model/fitting APIs | ownership of production calculations |
| tests | all maintained layers | becoming a production dependency |

The only intentional cross-family model edge is
`lamb.models.mrlfe.tracking.mrlfeBuildSeed -> lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`.

## Canonical owners

| Responsibility | Owner |
| --- | --- |
| Forward physics, tracking, quality and results | `lamb.models.<family>` |
| Inverse fitting | `lamb.fitting` |
| Generic one-dimensional iteration | `lamb.sweeps.runParametricSweep` |
| Sensitivity orchestration, plots and persistence | `studies/sensitivity/` |
| Solver investigations | `studies/solver_diagnostics/` |
| Execution-profile translation | app profile resolvers |
| Solver GUI view/export | `app/main/` |
| Fitting GUI view | `app/fitting/` |
| Validation | six runners and opt-in tests/tooling |

AE identity diagnostics remain model-owned because the maintained
`identityA0Diagnostic` solve path constructs them as returned diagnostic
evidence. They do not replace the official atlasA0 curve.

## Paths and invocation

`startup` resets repository-owned paths and adds only root, `src`, `app`, and
`tests/runners`. It does not add studies or examples. Each study script opts in
through `studies/configureStudyPath.m`; calling `startup` again restores the
production-only path.

Generated output roots remain under root `Results/` and are never source paths
or tracked artifacts.

[Human call traces](../workflows/gui/adapter_architecture.md) and
[test ownership](../../tests/README.md) complete this map.

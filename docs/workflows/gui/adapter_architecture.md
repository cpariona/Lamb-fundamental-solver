# GUI adapter architecture

The maintained human interfaces are the solver GUI and FitTool. They translate
UI state to canonical APIs and render returned results; they do not own physics,
tracking, residuals, or optimizers.

```text
LambFundamental_GUI
  -> app/main model adapter
  -> lamb.models.<family> public solver
  -> canonical result
  -> app/main view/export

FitTool_GUI
  -> app/fitting request adapter
  -> lamb.fitting.<family> fit API
  -> canonical family evaluator
  -> lamb.models.<family> public solver
  -> app/fitting view
```

## Solver routes

| Surface/model | Route |
| --- | --- |
| Solver GUI / RL | `guiRunRayleighLambModel -> lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes` |
| Solver GUI / mRLFE | `guiRunMRLFEModel -> lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest -> lamb.models.mrlfe.mrlfeSolve` |
| Solver GUI / AE | `guiRunAcoustoelasticIOPHGOModel -> lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch` |
| FitTool / RL | `guiFitRLSolver -> lamb.fitting.rayleigh_lamb.rlFitDispersionData` |
| FitTool / mRLFE | `guiFitMRLFESolver -> lamb.fitting.mrlfe.mrlfeFitDispersionData` |
| FitTool / AE | `guiFitAcoustoelasticIOPHGOSolver -> lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData` |

The former sweep GUI and its adapters are retired. Sensitivity work is
programmatic, opt-in study code under `studies/sensitivity/`; it never routes
through app adapters.

## Execution profiles

The application normalizes Fast/Balanced/Robust requests and records requested
and effective profiles. Model-owned configuration remains authoritative for
numerical presets and scientific policy. Display/export adapters serialize
existing results and never invoke a second solver.

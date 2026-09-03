# AE IOP/HGO public API

```matlab
opts = defaultAcoustoelasticIOPHGOOptions;
result = solveAcoustoelasticIOPHGOBranch(params, opts);
```

The production branch policy is `atlasA0`. Official result arrays are
`frequency_Hz`, `phaseVelocity_mps`, `wavenumber_radpm`, and `validMask`; the
official assessment is `quality`. Configuration metadata records requested and
effective numerical settings.

Application surfaces translate their requests before calling the same solver:

```matlab
guiRunAcoustoelasticIOPHGOModel
guiRunAcoustoelasticIOPHGOSweep
guiFitAcoustoelasticIOPHGOSolver
```

Reusable analysis APIs are `aeRunSweep`, `aeRunGridSweep`, and
`aeFitDispersionData`. Diagnostic solvers and modal-atlas helpers are internal
inspection facilities, not additional supported production policies.

Validation is owned by `run_quick_contract_tests`, `run_quick_smoke_tests`,
`run_numerical_regression_tests`, and `run_extended_integration_tests`.

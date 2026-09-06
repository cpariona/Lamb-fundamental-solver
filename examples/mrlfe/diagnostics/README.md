# mRLFE diagnostics

`validate_grid_presets` is the single maintained executable diagnostic. It
compares public numerical presets against a dense reference through the
canonical `lamb.models.mrlfe.mrlfeSolve` route. Broader characterization is automated by
`run_extended_integration_tests` and performance evidence by
`run_performance_and_benchmark_tests`.

Generated `.mat`, `.csv`, `.fig`, and `.png` outputs are not source artifacts.

The diagnostic is opt-in, not on the production path. From repository root:

```matlab
run('examples/mrlfe/diagnostics/validate_grid_presets.m')
```

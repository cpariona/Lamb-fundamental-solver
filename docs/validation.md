# Validation

Run `startup`, then execute the complete maintained validation surface:

```matlab
startup
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

- Repository hygiene protects layout, naming, dependency boundaries,
  documentation links, tracked artifacts, test ownership, and startup isolation.
- Quick contracts protect bounded APIs, request/result schemas, fitting
  primitives, sweep structure, GUI adapters, and execution-profile contracts.
- Quick smoke exercises representative model, app, fitting, and opt-in study
  routes.
- Numerical regression protects solver snapshots, tracking, branch identity,
  and synthetic fitting recovery.
- Extended integration checks model configuration, fitting workflows, GUI
  consumers, and cross-surface equivalence.
- Performance and benchmark tests record representative runtime and execution
  metadata without hardware-specific correctness thresholds.

Every maintained test must pass. Runners own path setup and restore the caller
path; `startup` exposes runner launchers but not test bodies, studies, or
examples. Individual tests are opt-in through `tests/tooling/configureTestPath`.

The two GUI entrypoints have automated adapter and interaction smoke coverage.
Manual GUI checks, when required by a UI change, should open each surface, reach
its initial state, and close it without changing scientific configuration.

Golden or tolerance changes require separately reviewed scientific evidence.
Structural changes must preserve existing baselines. Finish every validation
with `git diff --check` and an audit for untracked generated outputs.

Model-specific regression evidence and numerical presets are documented with
their family under [models](models/).

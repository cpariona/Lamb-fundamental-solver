# Validation

`startup` exposes exactly six launchers, not all tests. Every runner explicitly
loads `tests/tooling/configureTestPath.m`, executes its own flat test list, and
restores the caller path on success or failure. Tests that reset configuration
use `configureTestPath` rather than the production startup.

| Command | Direct tests | Purpose |
| --- | ---: | --- |
| `run_repository_hygiene_tests` | 7 | structure, docs, naming, artifacts, dependencies, paths |
| `run_quick_contract_tests` | 16 | bounded APIs, schemas, request/import contracts |
| `run_quick_smoke_tests` | 29 | representative model and application execution |
| `run_numerical_regression_tests` | 17 | scientific snapshots, synthetic recovery, tracking |
| `run_extended_integration_tests` | 40 | fitting, sweeps, GUI consumers, characterization |
| `run_performance_and_benchmark_tests` | 5 | descriptive performance and benchmark contracts |

There are 114 maintained tests, each owned directly by exactly one runner.
There are no wrappers, aggregate runner graphs, or generated ownership CSVs.
The hygiene contract checks unique ownership and globally unique filenames.

Test code lives under app, models, and shared subfolders. Tooling owns path
setup, runtime measurement, cross-surface profile matrices, and benchmarks.
For an individual test, explicitly opt in from the repository root:

```matlab
startup
addpath(fullfile(pwd, 'tests', 'tooling'))
configureTestPath
test_rl_result_contract
startup % remove test bodies/tooling again
```

Runtime is descriptive, not a hardware-specific correctness threshold.
Exported measurements belong under `Results/validation/` or the caller's
explicit output path, never under production source.

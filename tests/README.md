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
| `run_performance_and_benchmark_tests` | 4 | descriptive performance contracts |

There are 113 maintained tests, each owned directly by exactly one runner.
There are no wrappers, aggregate runner graphs, or generated ownership CSVs.
The hygiene contract checks unique ownership and globally unique filenames.

Test code lives under app, models, and shared subfolders. Tooling owns path
setup, runtime measurement, and cross-surface profile matrices. Ad hoc
benchmarks and temporary numerical diagnostics are not maintained repository
artifacts.
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

## Historical characterization

The mRLFE core matrix checks 24 Fast and 6 Dense cases. Without an independent
reference it reports schema/coverage only, never an assumed zero delta.
For a historical comparison, evaluate the same test against an isolated
historical models tree and save its two returned cell arrays, `fastResults`
and `denseResults`, to a disposable MAT file. Restore current production/test
paths, clear functions, then call:

```matlab
test_mrlfe_production_core_characterization(referenceFile)
```

That invocation computes actual Cp differences and checks frequency grids,
branches, presets, finite patterns, and masks. It never updates the reference.
The integration comparison uses Phase 1 commit
`1b6b3a15a7ce46b1644918383e1bd6a1c630f5f4`; generated reference files are not
tracked. Human-surface tests independently compare each consumer with the
current public solver.

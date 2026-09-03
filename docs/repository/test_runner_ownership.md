# MATLAB test runner ownership

The six files in `tests/runners/` are the complete maintained runner surface.
Every test has one direct owner, expressed by an explicit call in that owner.
There are no aggregate-to-focused runner edges, dynamic dispatch helpers,
root-level wrappers, or generated ownership CSVs.

| Runner | Responsibility | Direct tests |
| --- | --- | ---: |
| `run_repository_hygiene_tests` | structure, docs, naming, artifacts, boundaries, startup and root resolution | 7 |
| `run_quick_contract_tests` | bounded API, schema, configuration and import contracts | 16 |
| `run_quick_smoke_tests` | representative model and application execution | 29 |
| `run_numerical_regression_tests` | deterministic scientific and result-schema evidence | 17 |
| `run_extended_integration_tests` | fitting, sweeps, GUI consumers and characterization matrices | 40 |
| `run_performance_and_benchmark_tests` | descriptive runtime and benchmark evidence | 5 |

The current total is 114 maintained tests. Static hygiene verifies that every
test is mentioned exactly once, every mention resolves, and only the six
canonical runner files exist.

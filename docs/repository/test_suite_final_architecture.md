# Final MATLAB test-suite architecture

The test suite has four implementation areas plus tooling, and six validation tiers:

```text
tests/
|-- app/
|-- models/
|-- runners/
|-- shared/
`-- tooling/
```

| Tier | Command | Purpose |
| --- | --- | --- |
| repository hygiene | `run_repository_hygiene_tests` | static repository contracts |
| quick contract | `run_quick_contract_tests` | fast API and schema checks |
| quick smoke | `run_quick_smoke_tests` | routine executable coverage |
| numerical regression | `run_numerical_regression_tests` | deterministic scientific evidence |
| extended integration | `run_extended_integration_tests` | cross-surface and characterization coverage |
| performance | `run_performance_and_benchmark_tests` | descriptive timing and benchmarks |

The runners are flat: each test is called directly by exactly one tier and no
runner calls another runner. Root wrappers, dynamic runner dispatch, focused
runner aliases, and generated graph inventories are intentionally absent.

Use `measureTestRuntime` from `tests/tooling/` when machine-specific runtime
evidence is needed. Runtime remains descriptive rather than a correctness
threshold.

# Final MATLAB test-suite architecture

This document owns the stable test layout and validation-tier responsibilities.
Canonical direct ownership is defined separately in `test_runner_ownership.md`.

## Layout

```text
tests/
|-- app/       GUI, FitTool, SweepTool, adapter, and surface contracts
|-- models/    model-family numerical and contract tests
|-- runners/   canonical runner implementations
`-- shared/    fitting, sweeps, regression, path, and repository contracts
```

Nine intentional public wrappers and the standalone Main GUI export runner are
the only MATLAB files outside those stable locations. The wrapper inventory is
owned by `tests/README.md`.

## Validation tiers

| Tier | Command | Responsibility |
| --- | --- | --- |
| repository hygiene | `run_repository_hygiene_tests` | static structure, docs, naming, artifacts, boundaries, paths, and ownership |
| quick contract | `run_quick_contract_tests` | bounded structural, metadata, import, and pure-helper contracts |
| quick smoke | `run_quick_smoke_tests` | routine contracts plus representative GUI, AE, and mRLFE execution |
| numerical regression | `run_numerical_regression_tests` | deterministic model and result-schema evidence |
| extended integration | `run_extended_integration_tests` | matrices, fitting recovery, consumers, and characterization |
| performance | `run_performance_and_benchmark_tests` | descriptive timing and performance evidence |

`run_all_smoke_tests` remains the historical broad aggregate. It is maintained
for public command stability, not as the definition of the quick tier.

## Runner rules

- Every test has one direct canonical owner.
- Aggregates call focused owners rather than sibling tests.
- Repeated transitive reachability is allowed; duplicate direct ownership is not.
- Runtime is descriptive and never a pass/fail threshold.
- New tests belong in the stable layout and must be added to one canonical owner.
- New public wrappers require a documented external command contract.

Use `measureTestRuntime` when machine-specific runtime evidence is needed.
Completed timing snapshots are not permanent architecture documents.

Current generated inventory: 110 tests, 43 runner implementations, 9 public
wrappers, 3 helpers, and 231 graph edges. The exact direct-owner mapping is
regenerated rather than duplicated here.

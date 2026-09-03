# Tests

The maintained test layout is:

```text
tests/app/       application and GUI surfaces
tests/models/    model-family contracts and numerical tests
tests/runners/   the six canonical validation commands
tests/shared/    shared fitting, sweep, regression, and repository contracts
tests/tooling/   descriptive measurement utilities
```

`startup` adds `tests/` recursively. There are no root-level wrappers and no
generated ownership inventory.

## Validation commands

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

Each maintained test is named explicitly in exactly one runner. The runners do
not call one another. New tests must be placed in the stable layout and added
to exactly one tier. Runtime evidence is descriptive and must not introduce a
hardware-dependent pass/fail threshold.

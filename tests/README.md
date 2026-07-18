# Tests

The maintained test implementation layout is:

```text
tests/app/       application and GUI surfaces
tests/models/    model-family contracts and numerical tests
tests/runners/   canonical runner implementations
tests/shared/    shared fitting, sweep, regression, and repository contracts
```

`startup` adds `tests/` recursively, so canonical runner implementations are
public MATLAB commands without requiring root-level wrappers.

## Public convenience wrappers

Five established public commands retain thin wrappers that delegate through
`runRepositoryTestRunner` to same-named implementations under `tests/runners/`:

```text
tests/run_acoustoelastic_smoke_tests.m
tests/run_all_smoke_tests.m
tests/run_core_smoke_tests.m
tests/run_gui_smoke_tests.m
tests/run_mrlfe_smoke_tests.m
```

Every wrapper contains no validation logic and delegates to exactly one
same-named canonical runner. No additional test implementation or wrapper may
be placed at the root.

Specialized commands resolve directly from `tests/runners/`, including:

```matlab
run_fit_validation_tests
run_main_gui_export_tests
run_mrlfe_production_core_tests
run_mrlfe_public_contract_tests
run_mrlfe_route_integrity_tests
```

The recursive test path keeps these command names stable without duplicate
definitions or physical-path exceptions.

## Maintained commands

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

`run_quick_smoke_tests` is the routine developer command.
`run_all_smoke_tests` is the maintained historical broad aggregate.
Performance commands have no hardware-dependent pass/fail threshold.

## Ownership

Every maintained test has one direct canonical owner. The generated evidence
and regeneration command are documented in
`docs/repository/test_runner_ownership.md`. New tests must be added to the
stable layout and exactly one focused owner.

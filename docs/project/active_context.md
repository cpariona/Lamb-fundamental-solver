# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Ownership-tier base: `02971360f755b16c1896cc0715636385cd05d17f`
Active branch: `test/test-runner-ownership-and-tiers`

## Current development focus

The MATLAB suite now has one canonical direct owner for every maintained test
or an explicit manual classification. Routine, numerical, extended, and
performance validation are separate commands:

```matlab
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

The machine-readable contract is
`analysis/test_inventory/test_runner_ownership.csv`; the maintained rationale
and compatibility mapping are in
`docs/repository/test_runner_ownership.md`.

## Current static baseline

```text
160 tracked MATLAB files under tests/
104 tests
44 runner implementations
9 compatibility wrappers
3 helpers
203 runner graph edges
103 tests with one canonical direct owner
1 explicit manual/deferred test
0 tests with multiple executable direct runner memberships
```

Reachability is 14 quick-contract tests, 47 quick-smoke tests, 17 numerical
regressions, 40 extended-integration tests, and 54 tests from historical
`run_all_smoke_tests`.

## Measured validation

MATLAB R2024b on PCWIN64, one in-process run with no hard timeout:

Measured runner implementation commit:
`ed1035f960b6a145cc6cd64a1c59972b1b7efa31`.

```text
run_quick_contract_tests                 passed   134.42 s
run_quick_smoke_tests                    passed   352.14 s
run_numerical_regression_tests           passed   256.08 s
run_fit_tool_requested_curve_tests       passed    27.961 s
run_gui_execution_profile_tests          passed    23.583 s
run_gui_extended_tests                   passed    50.810 s
run_performance_and_benchmark_tests      passed    46.794 s
wrapper/target resolution check          passed
```

The measurements are descriptive. No runner enforces duration thresholds.

## Compatibility and deferred work

- All nine wrappers and all historical public commands remain.
- Historical public commands lose no tests. `run_all_smoke_tests` and
  `run_gui_smoke_tests` add requested-curve coverage; the AE and all-smoke
  commands add the two formerly standalone AE contracts.
- The obsolete mapped-to-Fast benchmark is the sole manual-only test and
  remains deferred for redesign.
- The 36-case profile matrix and multi-minute mRLFE characterization were not
  rerun for this ownership-only change.
- No test assertion, production implementation, numerical option, public API,
  file location, or entrypoint name changed.

## Primary references

- `docs/project/session_handoff.md`
- `docs/repository/test_runner_ownership.md`
- `docs/repository/test_suite_runtime_evidence.md`
- `docs/repository/validation_status.md`
- `analysis/test_inventory/README.md`

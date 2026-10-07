# Validation contract

Run normal maintenance from the repository root:

```matlab
clear functions;
startup;
addpath(fullfile(pwd, "tests", "runners"), "-end");
summary = run_regression_tests;
```

`tests/runners/run_regression_tests.m` is the canonical gate. Its private static
catalog, `tests/runners/private/repository_test_catalog.m`, assigns every
maintained test file exactly once to repository hygiene, quick contracts, quick
smoke, numerical regression, extended integration, or performance/benchmarks.
The catalog rejects duplicate ownership, missing files, and uncatalogued tests
before execution. Group and test order are deterministic. Native function-test
suites execute all their cases; ordinary test functions execute directly.

The gate restores the caller path on success or failure and fails on any failed
or incomplete test. Its summary records each file, group, status and elapsed
time. For affected checks, `run_regression_tests("Groups", "quick_contracts")`
selects a catalog group; normal delivery requires the full gate, including
performance/benchmarks.

Scientific snapshots and their tolerances belong to their maintained tests,
including `tests/models/test_lightweight_numerical_regression.m`. The gate has
no baseline-update mode. Changes to snapshots, tolerances or performance presets
require explicit scientific authorization and independent numerical evidence.
Never change them to obtain PASS.

The performance/benchmarks group owns runtime-schema checks, fitting-grid
accuracy/coverage characterization and production timing measurements. Existing
tests retain their assertions; timing characterizations are not a universal
runtime threshold. Compare equivalent before/after measurements when evaluating
a structural change and investigate material regressions.

Tests under the maintained test tree are catalogued executable contracts.
Temporary diagnostics and observational measurements stay outside the maintained
surface and do not replace regression evidence. Inspect generated artifacts and
finish with `git diff --check`. Record run results in delivery reports and Git/PR
history, not in this document.

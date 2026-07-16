# Validation status

This document owns the current validation commands, repository architecture
status, test counts, and bounded compatibility debt. Detailed run logs belong
in Git and pull-request history.

## Maintained commands

Repository structure and documentation:

```matlab
run_repository_hygiene_tests
```

Routine validation:

```matlab
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
```

Focused model and application validation:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_smoke_tests
run_ae_quick_tests
run_acoustoelastic_smoke_tests
run_gui_quick_tests
run_gui_smoke_tests
run_fit_validation_tests
run_execution_profile_contract_tests
run_execution_profile_integration_tests
```

Final aggregates:

```matlab
run_all_smoke_tests
run_extended_integration_tests
```

Performance and full benchmark commands are descriptive and run only for
explicit performance work.

## Repository hygiene contract

`run_repository_hygiene_tests` owns the structure, documentation, naming,
tracked-artifact, dependency-boundary, startup-path, repository-root, and test
ownership checks. The maintained final state requires:

- only `analysis/`, `app/`, `docs/`, `examples/`, `models/`, and `tests/` as
  tracked top-level content directories;
- no root `shared/` directory and no archive directories in source trees;
- no production or analysis dependency on examples or tests;
- no model dependency on analysis or app code;
- no broken relative Markdown links or missing exact documented files;
- one tracked definition for each documented MATLAB identifier, except the
  nine intentional public-wrapper pairs;
- no tracked generated figures, images, MAT files, or result folders;
- only approved test inventories or fixtures as tracked CSV files;
- one canonical owner for every maintained test and no runner cycles.

## Current architecture and inventory

The repository is validated against the ownership and naming contracts in
`repository_structure.md`, `naming_strategy.md`, `maintained_entrypoints.md`,
`test_suite_final_architecture.md`, and `test_runner_ownership.md`.

The generated inventory is the source of truth for exact test and runner
counts:

```text
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
analysis/test_inventory/test_runner_ownership.csv
```

Current generated state: 110 tests, 43 canonical runner implementations, 9
public compatibility wrappers, 3 test helpers, 231 graph edges, and 110
canonical owners. Validation reports 0 manual-only tests, 0 unowned tests, 0
multiple canonical owners, 0 sibling direct overlaps, and 0 runner cycles.

Current static reach is 19 tests from quick contracts, 52 from quick smoke, 14
from numerical regression, 44 from extended integration, and 59 from the
historical all-smoke aggregate.

## Compatibility debt

| Exception | Owner | Current consumer | Reason retained | Removal condition |
| --- | --- | --- | --- | --- |
| Nine public test wrappers | `tests/README.md`; `runRepositoryTestRunner` | Users and automation invoking the established public runner commands | Keeps public validation commands stable while canonical implementations live under `tests/runners/` | Remove only through an explicit public deprecation after external callers migrate. |
| `robustness` request/control alias | `guiNormalizeExecutionProfile`; `guiNormalizeControlExecutionProfile` | Existing GUI controls, adapters, request builders, tests, and external request structs | Preserves the established profile field while `executionProfile` is canonical | Remove after all maintained and external producers emit only `executionProfile` and a release deprecation is complete. |
| `result.diagnostics.rawInternalResult` | `mrlfeBuildResult` | Six maintained numerical/contract tests; compatibility adapters may inspect raw state | Keeps the pre-debug-path diagnostic schema while `result.debug.rawInternalResult` is canonical | Migrate all consumers to `result.debug.rawInternalResult`, validate parity, then remove in a schema-versioned change. |
| `aeResolveResultFile` legacy-result fallback | AE analysis layer | Seven maintained AE diagnostics reading previously generated workspaces | Reproduces current scientific diagnostics from both canonical and documented legacy output roots | Remove after required diagnostic fixtures are regenerated in canonical result roots and legacy inputs are no longer part of repeatable workflows. |

No new compatibility alias is authorized by this table.

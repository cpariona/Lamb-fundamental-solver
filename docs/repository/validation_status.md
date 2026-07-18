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
  five intentional public-wrapper pairs;
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

Current generated state: 121 tests, 43 canonical runner implementations, 5
public convenience wrappers, 3 test helpers, 239 graph edges, and 121
canonical owners. Validation reports 0 manual-only tests, 0 unowned tests, 0
multiple canonical owners, 0 sibling direct overlaps, and 0 runner cycles.

Current static reach is 21 tests from quick contracts, 60 from quick smoke, 17
from numerical regression, 47 from extended integration, and 70 from the broad
all-smoke aggregate.

AE configuration, result, tracking/policy, workflow-route, final-architecture,
and result-file compatibility contracts are assigned to the maintained focused
runners; the deterministic inventory CSVs include their canonical ownership
edges.

## Compatibility debt

| Exception | Owner | Current consumer | Reason retained | Removal condition |
| --- | --- | --- | --- | --- |
| Five public test wrappers | `tests/README.md`; `runRepositoryTestRunner` | Users and automation invoking the broad established smoke commands | Keeps the small convenience surface stable while canonical implementations live under `tests/runners/` | Remove only through an explicit public deprecation after external callers migrate. |
| `robustness` request/control alias | `guiNormalizeExecutionProfile`; `guiNormalizeControlExecutionProfile` | Existing GUI controls, adapters, request builders, tests, and external request structs | Preserves the established profile field while `executionProfile` is canonical | Remove after all maintained and external producers emit only `executionProfile` and a release deprecation is complete. |
| `result.diagnostics.rawInternalResult` | `mrlfeBuildResult` | No maintained production or numerical-test consumer; the public result-schema contract test verifies temporary alias availability and parity | Keeps the pre-debug-path diagnostic schema while `result.debug.rawInternalResult` is canonical | Remove only through an explicit schema-versioned compatibility change after external callers are considered. |
| `aeResolveResultFile` legacy-result fallback | AE analysis layer | Five maintained diagnostic scripts at eight call sites reading previously generated workspaces | Resolves the canonical task/file first while preserving repeatability from explicitly supplied legacy result roots | Remove after required diagnostic fixtures are regenerated in canonical result roots, external legacy inputs have migrated, and focused plus manual loading checks pass. |

No new compatibility alias is authorized by this table.

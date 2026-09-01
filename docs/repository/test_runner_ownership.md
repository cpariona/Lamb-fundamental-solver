# MATLAB test runner ownership

This document owns the canonical direct-owner policy for `tests/`. The exact
generated graph is maintained in:

```text
analysis/test_inventory/test_inventory.csv
analysis/test_inventory/runner_edges.csv
analysis/test_inventory/test_runner_ownership.csv
```

## Invariants

- Every maintained test has exactly one executable direct runner owner.
- No test is manual-only.
- No test has multiple canonical owners.
- Sibling runners do not call the same test directly.
- The runner graph has no cycles.
- Aggregate reachability does not change direct ownership.

## Hygiene ownership

`run_repository_hygiene_tests` directly owns:

```matlab
test_repository_structure_contract
test_repository_documentation_contract
test_repository_naming_contract
test_repository_tracked_artifacts_contract
test_repository_dependency_boundaries_contract
test_startup_path_policy
test_repository_root_utilities
```

`run_core_contract_tests` calls the hygiene owner and separately owns the model
output-folder and shared fitting-helper contracts.

## Regeneration

```matlab
clear functions
rehash toolboxcache
startup

[inventory, edges] = buildTestInventory('WriteCsv', true);
ownership = buildTestOwnership('WriteCsv', true, 'ValidateActual', true);
```

The parser is conservative static evidence. Dynamic wrapper dispatch through
`runRepositoryTestRunner` is modeled explicitly, and maintained runners must
also be executed.

The public wrapper surface contains five delegation-only commands. Specialized
commands, including fitting, Main GUI export, and focused mRLFE validation,
resolve directly from canonical implementations under `tests/runners/`.

Current generated state: 113 tests, 43 runner implementations, 5 wrappers, 3
helpers, 228 graph edges, and 113 canonical owners, with 0 manual-only,
unowned, multiply owned, sibling-overlapping, or cyclic tests/runners.

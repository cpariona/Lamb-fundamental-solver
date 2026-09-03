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

Current generated state: 116 tests, 43 canonical runner implementations, 5
public convenience wrappers, 3 test helpers, 231 graph edges, and 116
canonical owners. Validation reports 0 manual-only tests, 0 unowned tests, 0
multiple canonical owners, 0 sibling direct overlaps, and 0 runner cycles.

Current static reach is 24 tests from quick contracts, 55 from quick smoke, 17
from numerical regression, 47 from extended integration, and 65 from the broad
all-smoke aggregate.

AE configuration, result, tracking/policy, workflow-route, final-architecture,
and result-file compatibility contracts are assigned to the maintained focused
runners; the deterministic inventory CSVs include their canonical ownership
edges.

## Phase 3 result-contract validation

Validation completed on 2026-09-02 for
`restructure/phase-03-result-contracts`:

- repository hygiene, quick contracts, and quick smoke passed;
- mRLFE production core, route integrity, and smoke passed;
- AE extended, execution-profile end-to-end, and focused fitting validation
  passed;
- mRLFE production characterization covered 24 Fast and 6 Dense cases with
  maximum absolute difference `0 m/s`, maximum relative difference `0`, and no
  validity-mask differences;
- Main GUI, FitTool, and SweepTool mRLFE characterizations each covered 24
  cases with maximum absolute difference `0 m/s`, maximum relative difference
  `0`, and no validity-mask differences;
- AE synthetic atlasA0 fitting recovered `mu` with relative error
  `5.062e-08`, using the maintained bounded `fminbnd` path.

The lightweight numerical regression retains one known baseline failure:
`AE IOP/HGO atlasA0 Cp snapshot changed.` The Phase 3 migration does not update
that golden or relax its `1e-12` tolerance.

## Phase 4 analysis-workflow validation

Validation completed on 2026-09-02 for
`restructure/phase-04-analysis-workflows`:

- repository hygiene, quick contracts, and quick smoke passed;
- mRLFE production core, route integrity, smoke, and execution-profile
  end-to-end suites passed;
- focused fitting validation passed for RL, mRLFE, and AE, including bounds,
  fixed parameters, physical quality, and identifiability;
- focused SweepTool validation passed, including request mapping, effective
  configuration, summaries, and canonical per-point results;
- mRLFE production, FitTool, and SweepTool characterizations each reported
  maximum absolute difference `0 m/s`, maximum relative difference `0`, and no
  validity-mask differences;
- mRLFE fitting retained objective evaluation counts `11`, `8`, `7`, and `7`
  for A0Like mu, A0Like etaS, S0Like mu, and S0Like etaS respectively;
- AE extended validation passed, including the explicit one-dimensional and
  two-dimensional sweep routes and synthetic atlasA0 recovery with relative mu
  error `5.06201e-08`;
- the three maintained test inventories were regenerated: 116 tests, 231
  edges, and 116 canonical owners.

The numerical regression still stops only at the known
`AE IOP/HGO atlasA0 Cp snapshot changed.` baseline. Phase 4 changes neither its
golden data nor its tolerance.

## Phase 5 physical-architecture validation

Validation completed on 2026-09-02 for
`restructure/phase-05-physical-architecture`:

- repository hygiene, quick contracts, and the final quick smoke aggregate
  passed after a clean `startup`;
- mRLFE production core, route integrity, smoke, and execution-profile
  end-to-end suites passed;
- focused fitting plus FitTool, SweepTool, Main GUI, and result-contract suites
  passed with the new physical paths;
- production mRLFE covered 24 Fast and 6 Dense cases with maximum absolute
  difference `0 m/s`, maximum relative difference `0`, and no validity-mask
  differences;
- FitTool, SweepTool, and Main GUI each covered 24 mRLFE cases with maximum
  absolute difference `0 m/s`, maximum relative difference `0`, and no
  validity-mask differences;
- Main GUI versus SweepTool and Main GUI versus FitTool both reported maximum
  `Cp` difference `0`;
- mRLFE fitting retained objective evaluation counts `11`, `8`, `7`, and `7`,
  and the production performance contract passed with medians between `2.60 s`
  and `2.87 s` for its four characterized scenarios;
- AE extended validation and synthetic atlasA0 recovery passed with relative mu
  error `5.06201e-08`;
- the regenerated inventories remain at 116 tests, 231 graph edges, and 116
  canonical owners.

The lightweight numerical regression continues to report only
`AE IOP/HGO atlasA0 Cp snapshot changed.` The remaining RL and mRLFE numerical
regressions passed independently. Phase 5 changes neither the AE golden nor its
`1e-12` tolerance.

## Compatibility debt

| Exception | Owner | Current consumer | Reason retained | Removal condition |
| --- | --- | --- | --- | --- |
| Five public test wrappers | `tests/README.md`; `runRepositoryTestRunner` | Users and automation invoking the broad established smoke commands | Keeps the small convenience surface stable while canonical implementations live under `tests/runners/` | Remove only through an explicit public deprecation after external callers migrate. |
| `robustness` request/control alias | `guiNormalizeExecutionProfile`; `guiNormalizeControlExecutionProfile` | Existing GUI controls, adapters, request builders, tests, and external request structs | Preserves the established profile field while `executionProfile` is canonical | Remove after all maintained and external producers emit only `executionProfile` and a release deprecation is complete. |
| `aeResolveResultFile` legacy-result fallback | AE analysis layer | Five maintained diagnostic scripts at eight call sites reading previously generated workspaces | Resolves the canonical task/file first while preserving repeatability from explicitly supplied legacy result roots | Remove after required diagnostic fixtures are regenerated in canonical result roots, external legacy inputs have migrated, and focused plus manual loading checks pass. |

No new compatibility alias is authorized by this table.

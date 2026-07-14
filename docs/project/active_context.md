# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Last known good merge: `d3fcfd0c6a279df72b3e11caf7684e77f21c3aae` (PR #112, including PR #111)
Active audit branch: `test/test-suite-audit-2026-07-14`

## Current development focus

PR #111 restored the maintained mRLFE and execution-profile test-contract
baseline. Fast, Balanced, and Robust now map directly to the matching public
mRLFE numerical presets on Main GUI, SweepTool, and FitTool surfaces.

The repository-wide static audit of `tests/` is complete on the audit branch.
It provides a reproducible 137-file inventory, runner graph, wrapper audit,
runtime-purpose classification, six unregistered-test candidates, overlap
analysis, and a staged cleanup plan. No test membership or behavior changed.

The task brief is:

```text
docs/repository/test_suite_audit_brief.md
```

Audit evidence is in:

```text
docs/repository/test_suite_audit.md
analysis/test_inventory/
```

## Recently completed capabilities

- Public mRLFE API and production-core organization.
- Removal of obsolete mRLFE atlas/direct-visco production routes.
- Direct Fast/Balanced/Robust mRLFE execution-profile support.
- FitTool optimizer evaluations on a bounded `fitOptimized` grid.
- Explicit requested fitted-curve evaluation on the selected numerical preset.
- Repository hygiene phase 1 through PR #110.
- mRLFE and execution-profile contract repair through PR #111.

## Active architectural contracts

- GUI surfaces delegate to adapters and backends.
- Model physics remains in model layers.
- Fitting uses request -> dispatcher -> adapter -> maintained model API.
- `executionProfile` is distinct from route policy and optimizer options.
- Main GUI, SweepTool, and FitTool map Fast/Balanced/Robust directly to
  `fast`/`balanced`/`robust` for mRLFE.
- A0Like uses `physicalTail`; S0Like uses `none`; fallback remains disabled.
- FitTool optimization uses `gridPolicy = "fitOptimized"`.
- Explicit fitted-curve evaluation uses `gridPolicy = "numericalPreset"`.
- Exact cross-surface Cp equality is valid only when request and grid policy
  match.
- Public test-runner wrappers under `tests/` may be intentional compatibility
  entrypoints.
- The user performs merges manually unless explicitly requesting otherwise.

## Validation baseline from PR #111

The user executed and reported passing:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_legacy_cleanup_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_smoke_tests
run_gui_smoke_tests
test_execution_profile_cleanup_contract
test_execution_profile_state_transition_contract
test_execution_profile_fit_curve_metadata
run_execution_profile_cleanup_tests
test_execution_profile_validation_matrix
```

The execution-profile validation matrix completed all 36 combinations in about
178.7 seconds. It is extended integration validation, not a lightweight smoke
test.

## Known test-suite concerns

- `run_all_smoke_tests` delegates to several groups and has previously exceeded
  practical interactive time limits.
- Some smoke runners include synthetic fitting or numerical regression work.
- Execution-profile runners overlap and repeat tests.
- `test_execution_profile_validation_matrix` is too heavy for routine smoke use.
- `test_mrlfe_execution_profile_benchmark_contract` and
  `benchmarkMRLFEExecutionProfiles` still characterize the former
  mapped-to-Fast policy and need a separate diagnostic redesign.
- `run_mrlfe_production_core_tests` mixes contracts, characterization, and
  performance.
- Some root-level runner files are compatibility wrappers; they must not be
  deleted without consumer and documentation checks.
- Some test implementations remain outside the target `tests/app`,
  `tests/models`, `tests/runners`, and `tests/shared` layout.
- Static search may miss MATLAB dynamic invocation through `eval`, `feval`,
  function handles, `run`, `which`, or path-based dispatch.

## Test-suite audit constraints

- Audit before editing.
- Do not change solver, GUI, fitting, sweep, numerical, or validation behavior.
- Do not move, rename, delete, or consolidate test files in the audit phase.
- Do not change maintained runner names or wrapper behavior.
- Do not claim runtime measurements that were not executed in MATLAB.
- Distinguish static classification from measured runtime evidence.
- Prefer a staged cleanup plan over a bulk reorganization.

## Next development guidance

1. Review the audit findings and generated CSV evidence.
2. Merge the audit branch manually if accepted.
3. Start cleanup with the documentation-only wrapper/counter phase.
4. Keep each later layout or runner-membership change in a separate small PR.
5. Do not treat static non-registration as proof that a test is dead.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/project/templates/codex_task.md`
- `docs/repository/test_suite_audit_brief.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/maintained_entrypoints.md`
- `docs/repository/validation_status.md`
- `docs/repository/repository_hygiene_plan.md`
- `tests/README.md`

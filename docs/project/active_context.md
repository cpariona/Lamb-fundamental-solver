# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Last known good merge: `ca0ccfc3ea636ae2e77f1a672d9d4e8d3304e7ba` (PR #110)
Active branch: `test/mrlfe-contract-baseline`

## Current development focus

The mRLFE public-solver migration and repository hygiene phase 1 are complete and
merged into `main`.

The current focused branch restores the maintained mRLFE test-contract baseline.
It updates stale preset and execution-profile expectations, removes duplicated
FitTool work from the legacy-cleanup characterization, and requires exact
consumer equivalence only when the compared routes use the same numerical grid
policy.

No solver mathematics, numerical presets, grid construction, GUI behavior,
fitting behavior, sweep behavior, startup behavior, or runner names are changed.

## Recently completed capabilities

- Public mRLFE API and production-core organization.
- Removal of legacy mRLFE atlas/direct-visco production routes.
- End-to-end execution-profile integration across Main GUI, SweepTool, and FitTool.
- Fast, Balanced, Robust, and dense/reference numerical presets.
- Direct SweepTool use of `mrlfeSolve` per sweep point.
- FitTool objective evaluations on a bounded fit-optimized internal grid.
- Fit-result normalization without automatic solver reevaluation.
- Explicit user-requested fitted-curve solver evaluation.
- Fit-versus-requested-curve consistency diagnostics.
- Repository-wide hygiene audit and conservative phase 1 cleanup through PR #110.
- Removal of generated execution-profile CSV snapshots.
- Removal of the superseded `guiEvaluateFitFullCurve` helper.
- Removal of two obsolete unregistered direct-visco route tests.
- Restoration of the mRLFE public-contract, legacy-cleanup, Main GUI, FitTool,
  mRLFE smoke, and GUI smoke validation baseline on
  `test/mrlfe-contract-baseline`.

Detailed phase 1 evidence:

```text
docs/repository/repository_cleanup_phase1_report.md
```

## Active architectural contracts

- GUI surfaces delegate to adapters and backends. See `docs/workflows/gui/adapter_architecture.md`.
- Model physics remains in model layers. See `docs/repository/repository_structure.md`.
- Fitting uses request -> dispatcher -> adapter -> maintained model API. See `docs/workflows/fitting/architecture.md`.
- `executionProfile` is distinct from route policy and optimizer options.
- Main GUI, SweepTool, and FitTool resolve Fast, Balanced, or Robust into the corresponding public mRLFE numerical preset.
- A0Like uses `physicalTail`; S0Like uses `none`; fallback remains disabled.
- FitTool optimization uses `gridPolicy = "fitOptimized"`.
- A complete fitted curve is evaluated only after the explicit **Evaluate fitted curve** action and uses `gridPolicy = "numericalPreset"`.
- Exact cross-surface Cp equality is a valid contract only when the compared routes use the same request and internal grid policy.
- Main GUI quality status is derived from the returned public result; tests must not depend on one fixed case remaining marginal across validated preset changes.
- AE IOP/HGO still uses valid atlas terminology; mRLFE legacy-atlas cleanup must not remove AE atlas code, tests, examples, or documentation.
- Public test-runner wrappers under `tests/` remain intentional compatibility entrypoints.
- The user performs merges manually unless explicitly requesting another workflow.

## Validation status for the active branch

The user executed and reported passing:

```matlab
test_mrlfe_public_contract_validation
run_mrlfe_public_contract_tests
test_mrlfe_main_gui_result_contract
run_mrlfe_legacy_cleanup_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_smoke_tests
run_gui_smoke_tests
```

The first individual defaults and consumer-equivalence tests were also exercised
while diagnosing the runner failures. No extended grid matrix or broad fitting
validation was required because this branch changes tests only and preserves all
production numerical policies.

## Known limitations and open issues

- Existing synthetic and route-contract tests are not external physical validation.
- Grid-quality classifications near marginal branch tails can depend on the internal grid.
- Dense full-matrix validation is expensive and should not be repeated for documentation or test-contract-only changes.
- Some long mRLFE suites exceeded the available execution timeout during hygiene phase 1; no pass is claimed for suites not rerun on this branch.
- Historical documents may mention removed mRLFE routes as evidence; those names are not maintained production contracts.
- Some tests intentionally inspect names, paths, runner wrappers, generated inventories, or absence of legacy routes.
- Repository search alone may miss dynamic MATLAB calls; removal decisions require conservative verification.
- A later dedicated test-suite audit may classify runners by scope and runtime, map unregistered tests, and reduce duplicated heavy coverage. It must remain separate from this localized repair.

## Provisional next-objective candidates

These are options for review after the current branch is merged, not an approved sequence:

1. **Documentation consolidation**
   - stale generic execution-profile audit and benchmark material;
   - historical mRLFE atlas/grid/route documents and exact-path tests;
   - fitting phase-log archive.
2. **Test-suite audit**
   - map tests to runners and identify unregistered or duplicated coverage;
   - classify smoke, contract, regression, characterization, and heavy diagnostics;
   - record practical runtime budgets without moving broad test families in the same task.
3. **Diagnostic and compatibility audit**
   - diagnostic runtime/value review;
   - `aeCopyLegacyResultFolder`;
   - shared Rayleigh-Lamb mRLFE compatibility fields;
   - old `solveMRLFEBranch` implementation.

High-risk compatibility or solver-layer work must use separate model-focused
branches and must not be combined with documentation or test-suite cleanup.

## Next development guidance

1. Complete static diff checks and open a PR from `test/mrlfe-contract-baseline`.
2. The user reviews and merges the PR manually.
3. After merge, update local `main` from `origin/main` before selecting another objective.
4. Keep future changes small, localized, validated, and isolated by branch.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/maintained_entrypoints.md`
- `docs/repository/validation_status.md`
- `docs/repository/repository_hygiene_plan.md`
- `docs/repository/repository_cleanup_audit_2026-07-14.md`
- `docs/repository/repository_cleanup_phase1_report.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
- `docs/models/mrlfe/README.md`
- `docs/models/acoustoelastic_iop_hgo/documentation_index.md`

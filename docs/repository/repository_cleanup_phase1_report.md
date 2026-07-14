# Repository cleanup phase 1 report

Audit date: 2026-07-14
Branch: `repo-hygiene-phase1-audit`
Base: `main` at `b74b8b4babbf02c5ed9c0e400343a40e5c42f6a3`

## Outcome

This phase completed a repository-wide hygiene audit and a conservative first
cleanup batch. It removed one superseded FitTool helper, two obsolete and
unregistered mRLFE tests, and two generated CSV snapshots. It did not change
solver mathematics, GUI behavior, fitting behavior, sweep behavior, startup,
runner architecture, model parameters, or numerical policies.

The repository is not considered fully clean. Historical-document
consolidation, diagnostic review, compatibility helpers, old Rayleigh-Lamb
mRLFE option fields, and the similarly named solver layer remain explicit later
phase work.

## Initial repository state

- `git fetch origin`, `git switch main`, and `git pull --ff-only origin main`
  completed before the audit branch was created.
- Local `main` and `origin/main` both resolved to the base SHA above.
- The working tree was clean.
- The audit branch was created from that exact commit.

## Methodology and coverage

The audit read the required project and repository contracts in their mandated
order, followed by candidate-specific fitting, mRLFE, execution-profile, test,
diagnostic, and AE documentation.

Read-only evidence included:

- `git ls-files`, `git status -sb`, extension and top-level counts;
- tracked binary, empty-file, empty-directory, and duplicate-basename checks;
- exact symbol, filename, path, runner, registry, callback, fixture, CSV, and
  documentation searches with `git grep` and `rg`;
- inspection of root-level files and every tracked top-level area:
  `analysis/`, `app/`, `docs/`, `examples/`, `models/`, `references/`, and
  `tests/`;
- runner-wrapper mapping between `tests/run_*.m` and `tests/runners/run_*.m`;
- exact caller checks for AE compatibility helpers and both similarly named
  mRLFE branch solvers;
- inspection of Git history for the helper, legacy tests, CSVs, AE copy helper,
  old solver layer, and reference note;
- a diagnostic MATLAB execution of the two obsolete tests;
- static review of maintained diagnostic indexes instead of executing costly
  diagnostics or the two-day grid matrix.

The audited base contained 543 tracked files: 422 MATLAB, 117 Markdown, two
CSV, one `.gitignore`, and one extensionless license file. No binary file, zero
byte file, or tracked empty directory was present. Duplicate basenames were
model-specific `README.md`, `public_api.md`, and `fitting_workflow.md` files plus
intentional public test-runner wrappers.

## Complete classification summary

The classification is at the candidate or coherent candidate-group level. Each
row identifies the exact path or exhaustive path set reviewed in that group.

| Exact path or path set | Class | Purpose and dependency evidence | Contract / replacement / risk | Action and validation |
| --- | --- | --- | --- | --- |
| `examples/acoustoelastic_iop_hgo/sweeps/figures/**`, `examples/mrlfe/sweeps/figures/**`, `examples/rayleigh_lamb/sweeps/figures/**` | RETAIN (local output only) | Seventeen FIG and seventeen PNG files exist locally, but `git ls-files` and Git history find no tracked file. Sweep scripts regenerate them through `aeSaveExampleFigure`, `mrlfeSaveExampleFigure`, and `rlSaveExampleFigure`. No test fixture or Markdown image consumes them. | `figures/` is already narrowly ignored and startup excludes every `figures` directory. Risk: low. | No repository deletion or ignore change. User-local ignored outputs were left untouched. |
| `app/fitting/guiEvaluateFitFullCurve.m` | REMOVE | Exact symbol search found only the definition and documentation; no callback, registry, function handle, `str2func`, `feval`, code caller, or test caller. `FitTool_GUI` calls `guiEvaluateRequestedFitCurve`; normalization calls `guiBuildFitDisplayCurve`. | Replacements split objective-consistent display interpolation from explicit requested solver evaluation. The orphan also performed automatic dense reevaluation, contrary to the current fitting contract. Risk: medium, reduced by exact/dynamic searches and GUI/FitTool tests. | Removed; active GUI and entrypoint documents repaired. Validate with mRLFE FitTool and GUI smoke runners. |
| `tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_opt_in_contract.m` | REMOVE | Exact name appears only in itself, the old audit, and the stale generated inventory. No maintained runner invokes it. Direct execution fails an assertion. | Tests deleted `A0DelayedCut` / direct-visco behavior. Current absence coverage is `test_mrlfe_no_legacy_routes`, `test_mrlfe_no_legacy_route_flags`, and `test_mrlfe_legacy_cleanup_characterization`. Risk: medium. | Removed; validate the legacy-cleanup, public-contract, production-core, and mRLFE smoke runners. |
| `tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_s0_guard_contract.m` | REMOVE | Same search and runner result as the preceding test; direct execution also fails an assertion. | It asserts deleted route behavior and has maintained absence replacement coverage. Risk: medium. | Removed with the same focused validation. |
| `analysis/execution_profiles/execution_profile_inventory.csv` | REMOVE | `inventoryExecutionProfiles` is the sole generator; no code or test reads the CSV. Documentation names it only as generated output. The snapshot had 1,076 rows, 160 unique paths, and 35 paths that no longer exist. | The generator remains, defaults to the same path, and supports `WriteCsv=false`. `*.csv` is already ignored. Risk: low. | Removed from tracking; intentional generator/documentation references remain. |
| `analysis/performance/execution_profile_benchmark_results.csv` | REMOVE | `run_execution_profile_benchmark` is the sole generator; no code or test reads the snapshot. The file records machine-specific R2024b timings and documentation says it is not a cross-machine contract. | Generator and provenance documentation remain; `*.csv` already ignores regeneration. Risk: low. | Removed from tracking; intentional output-path references remain. |
| `docs/models/mrlfe/atlas_policy_notes.md` | DEFER | Exact path has active index, audit, and test references; `test_mrlfe_maintained_entrypoints_naming` requires the file. Content is historical and contains removed route terminology. | Protects a current exact-path test despite stale content. Risk: medium. | Defer relocation/consolidation until the path test and indexes are deliberately revised. |
| `docs/models/mrlfe/fittool_grid_path_sensitivity.md`, `docs/models/mrlfe/docs_cleanup_audit.md` | DEFER | Both have multiple inbound documentation/index references; the former preserves grid/path evidence and the latter audit history. | Historical evidence, not current behavior contract. Risk: low-to-medium due to inbound references. | Phase 2 documentation consolidation. |
| `docs/validation/mrlfe_legacy_route_inventory.md` | RETAIN | Referenced by the mRLFE README, diagnostic indexes, maintained-entrypoint document, and cleanup tests as absence/migration evidence. | Explicitly historical and useful for current legacy-absence interpretation. Risk: low. | Retained. |
| `docs/validation/mrlfe_solver_route_audit.md`, `docs/validation/mrlfe_solver_route_quick_results.md` | DEFER | No inbound reference beyond the cleanup audit, but both contain unique pre-migration route evidence. | Git history may ultimately be sufficient; evidence consolidation needs content review. Risk: low-to-medium. | Phase 2 archive/consolidation decision. |
| `docs/archive/fitting_phase_logs.md`, `docs/archive/fitting_phases/fitting_phase1_status.md` through `fitting_phase11_status.md` | CONSOLIDATE (deferred) | Already excluded from active startup paths and explicitly indexed as archive. Individual files have inbound archive/history references. | Unique chronology exists but is duplicated across a summary plus eleven phase files. Risk: low. | Consolidate in a documentation-only phase, not with code/test cleanup. |
| `docs/models/acoustoelastic_iop_hgo/audits/**`, `docs/models/acoustoelastic_iop_hgo/archive/**` | RETAIN | `documentation_index.md` explicitly classifies every audit and archived record. Audit files support current maintainer decisions; archive files are clearly labeled historical. | AE atlas terminology is maintained and unrelated to removed mRLFE routes. Risk of indiscriminate cleanup: medium. | Retained without moves. |
| `examples/mrlfe/diagnostics/**` | RETAIN | `examples/mrlfe/diagnostics/README.md` and `maintained_entrypoints.md` enumerate the current diagnostics and state their manual/heavy purpose. They use public or neutral APIs; generated outputs go to ignored output locations or local files. | Unique performance, grid, residual, and validity evidence; several are intentionally too expensive for smoke tests. Risk: medium-high. | Retained; individual runtime review remains phase 3. |
| `examples/acoustoelastic_iop_hgo/diagnostics/**` | RETAIN | Active examples inventory, documentation index, audit records, wrappers, and AE tests map these files and their prerequisites. | They support the maintained AE `atlasA0` policy and must not be treated as mRLFE legacy atlas code. Risk: high. | Retained. |
| `analysis/acoustoelastic_iop_hgo/aeRunLegacyScript.m`, `aeDeleteExampleFigure.m`, `aeResolveResultFile.m` | RETAIN | Exact callers exist in maintained AE diagnostics/sweeps; public API/docs and AE smoke tests protect them. Dynamic execution via `aeRunLegacyScript` is intentional. | Maintained compatibility/output behavior. Risk: high. | Retained. |
| `analysis/acoustoelastic_iop_hgo/aeCopyLegacyResultFolder.m` | DEFER | Exact search finds no code caller; an AE audit says no bridge is required. Git history identifies it as a migration helper. | High-risk group was explicitly reserved for an AE-focused cleanup; broad AE validation is required. | Defer to phase 4 despite orphan evidence. |
| `tests/run_acoustoelastic_smoke_tests.m`, `tests/run_all_smoke_tests.m`, `tests/run_core_smoke_tests.m`, `tests/run_gui_smoke_tests.m`, `tests/run_mrlfe_legacy_cleanup_tests.m`, `tests/run_mrlfe_production_core_tests.m`, `tests/run_mrlfe_public_contract_tests.m`, `tests/run_mrlfe_smoke_tests.m` | RETAIN | Each is a thin public wrapper that delegates through `runRepositoryTestRunner` to the same-named implementation under `tests/runners/`. `tests/README.md` declares this compatibility layout intentional. | Public runner commands and path behavior are maintained contracts. Risk: high. | Retained. |
| `tests/run_main_gui_export_tests.m` | RETAIN | Standalone public runner directly invokes the maintained export contract test; no same-named canonical runner exists. | Not a duplicate wrapper. Risk: medium. | Retained. |
| `tests/app/fitting/test_mrlfe_fit_grid_policy_performance.m` | RETAIN | No runner registration, but the source is a deliberate manual lightweight performance characterization of `fitOptimized` versus `numericalPreset`. | Protects current grid-policy evidence and is appropriately kept out of routine smoke runs. Risk: medium. | Retained; document registration policy in a later test audit. |
| `models/mrlfe/solvers/mrlfeSolveBranch.m` | RETAIN | Direct caller is public `mrlfeSolve`; production-core docs and tests require the exact path/name. | Current neutral dispatcher. Risk: high. | Retained. |
| `models/mrlfe/solvers/solveMRLFEBranch.m` | DEFER | Exact search finds only its definition plus historical/audit references. It is an older full tracker implementation with dynamic/path compatibility risk and long Git history. | Similar name does not imply safe duplication. Broad solver/startup validation would be required. Risk: high. | Defer to a dedicated solver-layer audit. |
| `models/rayleigh_lamb/core/rlDefaultOptions.m` legacy fields `mrlfeDirectViscoAtlasPolicy` and `mrlfeDirectViscoAtlasComputeElasticReference` | DEFER | Exact search shows the fields persist in the shared RL options object; the removed tests were their only active behavior assertions. | Core model file is outside conservative phase 1 and may preserve compatibility. Risk: high. | Later compatibility-field audit; no model edit here. |
| `analysis/performance/run_execution_profile_benchmark.m`, `docs/architecture/execution_profiles_benchmark.md`, `analysis/execution_profiles/inventoryExecutionProfiles.m`, `docs/architecture/execution_profiles_audit.md` | DEFER | Exact searches show paired script/document ownership. Several mRLFE route descriptions and recorded branch/PR references predate the public-solver migration. Newer mRLFE-specific benchmark code and validation docs are maintained and tested. | Cross-model scripts may still be useful, but their mRLFE narrative is misleading. Risk: medium. | Phase 2 should archive or refresh the generic documents/scripts without changing numerical policy. |
| `references/PYTHON_REPO_NOTES.md` | DEFER | No inbound reference except the cleanup audit; contains only three external provenance links and has a long early-project history. | Possible provenance value, but unclear current contract. Risk: low. | Decide archive/removal in documentation phase. |
| `.agents/` | RETAIN (local only) | Empty on disk, absent from `git ls-files`, and therefore not part of repository history. | Removing it would create no reviewable Git change and may affect local tooling. Risk: low. | Left untouched. |
| Root `README.md`, `LICENSE`, `runApp.m`, `startup.m`, `configureProjectPath.m` | RETAIN | `runApp` is the documented GUI entrypoint; `startup` calls `configureProjectPath`; path-policy tests cover startup behavior. | Maintained setup/public surface. Risk: high. | Retained. |

## Evidence for changed candidates

### FitTool helper

The exact symbol search returned the function itself and documentation only.
The exact filename search returned documentation only. Searches for callbacks,
function handles, `str2func`, and `feval` found no invocation. Current code and
tests call:

```text
guiNormalizeFitResult -> guiBuildFitDisplayCurve
FitTool explicit action -> guiEvaluateRequestedFitCurve
```

The removed helper's `localEvaluateDenseSolverDiagnostic` called RL, mRLFE, or
AE solvers automatically. That behavior is specifically excluded by the active
fitting architecture and the maintained mRLFE on-demand curve test.

### Obsolete tests

Neither test name occurs in a maintained runner. Both tests call the old
Rayleigh-Lamb-hosted mRLFE route and assert `A0DelayedCut` behavior. Their
diagnostic execution on the base commit produced:

```text
test_mrlfe_a0_delayed_direct_visco_opt_in_contract  FAIL MATLAB:assertion:failed
test_mrlfe_a0_delayed_direct_visco_s0_guard_contract FAIL MATLAB:assertion:failed
```

The maintained legacy-cleanup runner tests absence rather than deleted route
behavior, so removal does not reduce supported-behavior coverage.

### Generated CSV snapshots

Exact filename searches found one generator and documentation for each file,
with no `readtable`, `readmatrix`, fixture, registry, or test consumer. The
inventory snapshot was demonstrably stale: 35 of its 160 unique recorded paths
were absent. The benchmark snapshot contains local hardware timings and states
that it is not a cross-machine contract. Both generators remain executable and
their default paths are already covered by the existing `*.csv` ignore rule.

## Files changed, removed, or moved

Removed:

```text
app/fitting/guiEvaluateFitFullCurve.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_opt_in_contract.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_s0_guard_contract.m
analysis/execution_profiles/execution_profile_inventory.csv
analysis/performance/execution_profile_benchmark_results.csv
```

Updated active references:

```text
docs/repository/maintained_entrypoints.md
docs/workflows/gui/adapter_architecture.md
docs/workflows/gui/integration_audit.md
docs/project/session_handoff.md
```

Added:

```text
docs/repository/repository_cleanup_phase1_report.md
```

No files were moved or archived in this phase.

## Validation

Static validation:

```text
git status -sb                                      reviewed
git diff --stat                                     reviewed
git diff --check                                    passed
git diff                                            reviewed
exact removed symbol/filename/path searches         passed
tracked binary and empty-file checks                passed
CSV consumer searches                               no consumers found
```

MATLAB validation:

| Command | Result |
| --- | --- |
| `run_mrlfe_fit_public_solver_tests` | PASS. Includes optimized fit-grid, no-solver display curve, public route guard, characterization, and parameter regression. |
| `run_gui_smoke_tests` | PASS. All reported GUI groups passed, including the on-demand full-curve contract. |
| `run_mrlfe_smoke_tests` | PASS. All 14 reported mRLFE smoke groups passed. |
| `run_mrlfe_legacy_cleanup_tests` | PARTIAL. `test_mrlfe_no_legacy_routes` and `test_mrlfe_no_legacy_route_flags` passed; `test_mrlfe_legacy_cleanup_characterization` failed at pre-existing exact equality assertion `FitTool forward Cp mismatch.` No changed file participates in that numerical comparison. |
| `run_mrlfe_public_contract_tests` | FAIL on the base contract expectation that preset `balanced` throw `mrlfe:InvalidNumericalPreset`; the maintained implementation supports Balanced. The cleanup did not modify presets or this test. |
| `run_mrlfe_neutral_production_helper_tests` | TIMEOUT at five minutes; no pass claimed. |
| Independent focused-plus-`run_all_smoke_tests` batch | TIMEOUT at twenty minutes before buffered per-suite results were available; no pass claimed. |

Before cleanup, both removed delayed-direct-visco tests were also executed
directly; each failed with `MATLAB:assertion:failed`, confirming that they did
not protect currently passing behavior.

The extended two-day mRLFE grid matrix was intentionally not run because no
solver or grid-policy behavior changed. The production-core performance suite
was not rerun separately after the neutral-helper timeout because phase 1 does
not modify production code.

## Implementation commits

```text
875961ea837ef4de05d9870f5530b0edec2db273  Stop tracking generated execution profile snapshots
26063236a231874911024c5ecb79c730aa0daabb  Remove superseded FitTool curve evaluator
5d12a6ce93db2a8ab4b96950f7b7a54ada5057cd  Remove obsolete direct visco route tests
```

The final documentation commit contains this report and the updated session
handoff; its SHA is recorded in the delivery report because a commit cannot
include its own final SHA.

## Remaining phases

1. Documentation-only consolidation: stale mRLFE migration documents, generic
   execution-profile audit/benchmark material, and fitting phase logs.
2. Diagnostic-by-diagnostic review with runtime budgets and output-path checks.
3. AE-specific review of `aeCopyLegacyResultFolder` and remaining wrapper
   targets, with AE smoke validation.
4. High-risk compatibility and solver-layer audit for shared RL mRLFE flags,
   `solveMRLFEBranch`, and any runner changes.

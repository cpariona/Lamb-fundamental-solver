# mRLFE documentation cleanup audit

## Scope

This audit covers the repository-hygiene pass for mRLFE documentation, diagnostics, examples, and test-runner references. It keeps solver behavior unchanged.

## Current maintained references

Active mRLFE documentation should point to these files first:

```text
docs/mrlfe/README.md
docs/mrlfe/fitting_workflow.md
docs/mrlfe/fittool_grid_path_sensitivity.md
docs/mrlfe/current_sweeps.md
docs/mrlfe/diagnostics/README.md
docs/mrlfe/diagnostics/tracker_diagnostic_summary.md
docs/mrlfe_atlas_policy_notes.md
docs/gui/mrlfe_atlas_policy_integration.md
examples/mrlfe/diagnostics/README.md
```

## Current audit status

The mRLFE documentation is mostly consistent on the active FitTool route:

```text
mrlfeFitDispersionData
  -> mrlfeBuildFitProblem
  -> mrlfeEvaluateFitModel
  -> mrlfeEvaluateAtlasFitModel
  -> official mRLFE atlas branch output
```

Current active-doc wording consistently treats:

```text
adaptivePhysicalTail  -> current FitTool A0Like fitting default
delayedCut            -> conservative comparison/diagnostic policy
legacy reference/DP   -> explicit diagnostic route only
```

The main cleanup need is no longer test relocation. The test layout migration has been completed, and mRLFE tests now live under:

```text
tests/models/mrlfe/
tests/app/fitting/
tests/app/gui/
tests/runners/
```

Remaining cleanup should focus on documentation consistency, diagnostics classification, examples/diagnostic inventory, and stale historical references.

## Audit findings in this pass

### Active route documentation

Status: keep.

`docs/mrlfe/fitting_workflow.md`, `docs/mrlfe/README.md`, `docs/mrlfe_atlas_policy_notes.md`, and `docs/gui/mrlfe_atlas_policy_integration.md` agree on the maintained atlas-first FitTool fitting route and on the `adaptivePhysicalTail` A0Like FitTool default.

No solver behavior change is implied by this audit.

### Diagnostic documentation

Status: keep, but treat as diagnostic evidence rather than active API contract.

`docs/mrlfe/diagnostics/README.md`, `docs/mrlfe/diagnostics/tracker_diagnostic_summary.md`, and `examples/mrlfe/diagnostics/README.md` preserve useful evidence about tracker behavior, direct-atlas limitations, A0 policy comparisons, and dense diagnostics.

These files should not override the active fitting contract unless the conclusion is also summarized in `docs/mrlfe/fitting_workflow.md` or `docs/mrlfe/README.md`.

### Archived cleanup documentation

Status: keep, but refresh stale paths when they can confuse active maintenance.

`docs/mrlfe/archive/pending_cleanup.md` is correctly marked as archived historical cleanup status. However, some historical test references still used pre-migration paths such as `tests/mrlfe/...`. Those should be updated to current paths or explicitly identified as historical references.

### Repository hygiene plan

Status: keep and update.

`docs/repository_hygiene_plan.md` still describes some pre-migration test locations. The plan remains useful as a hygiene policy document, but its mRLFE test-audit targets should be updated to the current test layout.

## Resolved in pass 1

- Updated the mRLFE docs index so it describes the atlas-first FitTool route rather than the previous reference-based workflow.
- Cross-linked the FitTool grid/path sensitivity note from the mRLFE README and fitting workflow.
- Clarified that `adaptivePhysicalTail` is the current FitTool A0Like fitting default.
- Clarified that `delayedCut` remains a conservative comparison policy for diagnostics and sweep-policy investigations.
- Updated the diagnostics README so it no longer says that `adaptivePhysicalTail` improves difficult A0 branches without changing the default recommendation.

## Resolved in pass 2

- Rewrote `docs/mrlfe_atlas_policy_notes.md` to separate FitTool fitting defaults from forward/sweep diagnostic policy.
- Clarified that `adaptivePhysicalTail` is the current FitTool A0Like fitting default, while `delayedCut` is a conservative diagnostic baseline.
- Preserved the quantitative A0 policy evidence from dense diagnostics, but removed wording that treated `delayedCut` as the unconditional current default.
- Updated `docs/gui/mrlfe_atlas_policy_integration.md` so the FitTool fitted-curve contract includes fit-consistent plotting and dense solver diagnostics.
- Updated the GUI validation wording so `test_gui_mrlfe_fit_full_curve_fast_contract` is described as protecting fit-consistent plotting plus diagnostic dense re-evaluation, not merely extension skipping.

## Resolved in pass 3

- Removed the obsolete `sweep_mrlfe_shear_viscosity_phase_velocity` wrapper reference from `docs/mrlfe/current_sweeps.md` after code search showed it no longer exists.
- Refreshed `docs/mrlfe/archive/pending_cleanup.md` so it clearly identifies itself as archived cleanup status, not active route/fitting/GUI documentation.
- Added an explicit scope note to `docs/mrlfe/diagnostics/tracker_diagnostic_summary.md` clarifying that it is tracker-behavior evidence, not the active FitTool contract.
- Cross-linked active FitTool references from the archived cleanup status and tracker diagnostic summary.

## Resolved in pass 4

- Expanded `examples/mrlfe/diagnostics/README.md` into a complete diagnostic inventory.
- Classified scripts as primary maintained diagnostics, secondary investigation diagnostics, or historical/candidate-for-archive diagnostics.
- Identified historical candidates that should receive reference-search and coverage checks before deletion or archival.
- Preserved all scripts; this pass did not delete or move code.

## Resolved in pass 5

- Started reference checks for historical diagnostic candidates.
- Found active maintained-entrypoint references to `diagnose_mrlfe_visco_direct_atlas`, so it was not deleted.
- Updated the root `README.md` so the mRLFE section reflects the current atlas-first FitTool fitting route and no longer presents `diagnose_mrlfe_visco_direct_atlas` as a focused maintained diagnostic.
- Updated `docs/maintained_entrypoints.md` so maintained mRLFE diagnostics list only current primary diagnostics, while secondary and historical diagnostics are delegated to `examples/mrlfe/diagnostics/README.md`.

## Resolved in pass 6

- Removed eight historical A0 modal-atlas / DP-cost exploration scripts from `examples/mrlfe/diagnostics/`.
- Kept `diagnose_mrlfe_visco_direct_atlas.m` as a secondary diagnostic because it is still tied to direct-atlas route-policy tests and documentation context.
- Updated `examples/mrlfe/diagnostics/README.md` so removed scripts are recorded under historical diagnostics removed in cleanup.

Removed scripts:

```text
diagnose_mrlfe_a0_dp_scan_cost.m
diagnose_mrlfe_a0_modal_atlas.m
diagnose_mrlfe_a0_modal_atlas_candidates_23kHz.m
diagnose_mrlfe_a0_modal_atlas_cluster_cut_policy.m
diagnose_mrlfe_a0_modal_atlas_error_map.m
diagnose_mrlfe_a0_modal_atlas_hook_policy.m
diagnose_mrlfe_a0_modal_atlas_integrated_cut.m
diagnose_mrlfe_a0_modal_atlas_seed_identity.m
```

## Resolved in pass 7

- Consolidated mRLFE test runners without deleting individual tests.
- Removed atlas-specific test execution from `run_mrlfe_smoke_tests` to avoid duplicating `run_mrlfe_atlas_tests`.
- Updated `run_all_smoke_tests` so the complete suite now explicitly runs both `run_mrlfe_smoke_tests` and `run_mrlfe_atlas_tests`.
- Kept all atlas contract tests in the focused atlas runner.

## Resolved in pass 8

- Completed the test-layout migration.
- Moved mRLFE model-family tests under `tests/models/mrlfe/`.
- Moved mRLFE FitTool/app-layer contracts under `tests/app/fitting/`.
- Kept GUI-surface contracts under `tests/app/gui/`.
- Moved maintained runner implementations under `tests/runners/` while preserving compatibility wrappers under `tests/`.
- Documented the final test-layout audit in `tests/README.md`.

## Resolved in pass 9

- Shortened `docs/mrlfe/README.md` into a true index instead of a second workflow specification.
- Added an explicit document-role section to the mRLFE index.
- Preserved the current route summary in the index, but delegated detailed behavior to:
  - `docs/mrlfe/fitting_workflow.md` for the fitting-route contract,
  - `docs/mrlfe_atlas_policy_notes.md` for atlas policy evidence,
  - `docs/gui/mrlfe_atlas_policy_integration.md` for GUI adapter and metadata behavior.
- Kept the active A0 policy wording centralized and concise:
  - `adaptivePhysicalTail` is the current FitTool A0Like fitting default.
  - `delayedCut` is the conservative comparison policy for diagnostics and sweep-policy investigations.

## Remaining audit items

### mRLFE documentation

Review active mRLFE docs for duplication and decide whether some content should be shortened now that the maintained route is stable.

Priority files:

```text
docs/mrlfe/fitting_workflow.md
docs/mrlfe_atlas_policy_notes.md
docs/gui/mrlfe_atlas_policy_integration.md
```

Expected actions:

- Keep `docs/mrlfe/fitting_workflow.md` as the active FitTool fitting route contract.
- Keep `docs/mrlfe_atlas_policy_notes.md` as the detailed policy/evidence note.
- Keep `docs/gui/mrlfe_atlas_policy_integration.md` as the GUI adapter and metadata contract.
- Avoid duplicating long policy tables in the mRLFE index.

### mRLFE diagnostics and examples

Review diagnostic scripts only after reference checks. Do not delete diagnostics solely because they are slow.

Priority file:

```text
examples/mrlfe/diagnostics/README.md
```

Expected actions:

- Keep primary maintained diagnostics.
- Keep secondary diagnostics that support active tests or unresolved solver questions.
- Archive or delete only after reference and coverage checks.

### Repository-level documentation

Update repository-wide hygiene and entrypoint docs when they still mention pre-migration paths or outdated validation groupings.

Priority files:

```text
docs/maintained_entrypoints.md
docs/README.md
```

## Validation after documentation-only passes

Run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_mrlfe_fit_atlas_tests
```

After diagnostic script pruning, run:

```matlab
clear; clc; close all;
startup
run_mrlfe_smoke_tests
run_mrlfe_atlas_tests
run_mrlfe_fit_atlas_tests
run_gui_smoke_tests
```

After runner or test-layout changes, run:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
run_mrlfe_fit_atlas_tests
```

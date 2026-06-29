# mRLFE documentation cleanup audit

## Scope

This audit covers the repository-hygiene pass for mRLFE documentation. It is intentionally documentation-focused and does not delete diagnostics, examples, or tests.

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

## Remaining audit items

### mRLFE examples and diagnostics

Review `examples/mrlfe/diagnostics/` next. Do not delete scripts until each is classified as one of:

- primary maintained diagnostic,
- secondary investigation diagnostic,
- historical diagnostic candidate for archive/removal.

The current diagnostics README already defines primary and secondary categories. The next pass should compare that list against the actual files and identify:

- files listed as primary/secondary but missing,
- files present but not classified,
- files likely superseded by maintained tests or docs.

### mRLFE tests

Review mRLFE tests after docs/examples are classified. Start with:

```text
tests/gui/test_gui_mrlfe_*.m
tests/mrlfe/test_mrlfe_*.m
root-level tests/test_mrlfe_*.m
```

Expected actions:

- Keep tests that protect current route contracts.
- Identify duplicate tests that protect the same contract.
- Consolidate runners only after confirming coverage.

## Validation after documentation-only passes

Run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_mrlfe_fit_atlas_tests
```

Before any deletion or test consolidation, also run:

```matlab
clear; clc; close all;
startup
run_mrlfe_smoke_tests
run_mrlfe_atlas_tests
run_mrlfe_fit_atlas_tests
run_gui_smoke_tests
```

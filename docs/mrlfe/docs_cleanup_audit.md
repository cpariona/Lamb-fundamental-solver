# mRLFE documentation cleanup audit

## Scope

This audit covers the first repository-hygiene pass for mRLFE documentation. It is intentionally documentation-focused and does not delete diagnostics, examples, or tests.

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
examples/mrlfe/diagnostics/README.md
```

## Resolved in this cleanup pass

- Updated the mRLFE docs index so it describes the atlas-first FitTool route rather than the previous reference-based workflow.
- Cross-linked the FitTool grid/path sensitivity note from the mRLFE README and fitting workflow.
- Clarified that `adaptivePhysicalTail` is the current FitTool A0Like fitting default.
- Clarified that `delayedCut` remains a conservative comparison policy for diagnostics and sweep-policy investigations.
- Updated the diagnostics README so it no longer says that `adaptivePhysicalTail` improves difficult A0 branches without changing the default recommendation.

## Remaining audit items

### mRLFE docs

Review these next for duplication and stale wording:

```text
docs/mrlfe_atlas_policy_notes.md
docs/gui/mrlfe_atlas_policy_integration.md
docs/mrlfe/diagnostics/tracker_diagnostic_summary.md
docs/mrlfe/archive/pending_cleanup.md
```

Expected actions:

- Keep one active route-policy summary.
- Move older implementation-status text to archive if it is still useful.
- Remove references to outdated defaults if they conflict with FitTool behavior.

### mRLFE examples and diagnostics

Review `examples/mrlfe/diagnostics/` after documentation is coherent. Do not delete scripts until each is classified as one of:

- primary maintained diagnostic,
- secondary investigation diagnostic,
- historical diagnostic candidate for archive/removal.

The current diagnostics README already defines primary and secondary categories. The next pass should compare that list against the actual files.

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

## Validation after this pass

For this documentation-only pass, run:

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

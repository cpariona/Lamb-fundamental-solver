# Repository hygiene cleanup plan

## Purpose

This document defines the cleanup plan for documentation, examples, diagnostics, and tests after the mRLFE FitTool route and visualization stabilization.

The first cleanup pass is audit-only unless a file is clearly obsolete, duplicated, or contradicted by maintained entrypoints. Deletions should be made only after the file is classified and the relevant smoke or focused test group passes.

## Priorities

1. mRLFE, because it was the last area modified and now has the largest number of active diagnostics and contract tests.
2. GUI and fitting docs, because FitTool and SweepTool are shared surfaces across models.
3. Repository-level docs, because they define maintained entrypoints and structure.
4. Acoustoelastic IOP/HGO docs and diagnostics, after mRLFE is stable.
5. Rayleigh-Lamb docs, examples, and tests, mostly to verify that base-model documentation is still concise and current.

## Cleanup rules

### Keep

Keep files that are one of the following:

- Maintained API or workflow documentation.
- Smoke tests or contract tests that guard current behavior.
- Public examples that demonstrate a supported workflow.
- Diagnostics that are still referenced by active docs or that reproduce a known unresolved numerical issue.

### Archive

Archive files that are historically useful but no longer represent active workflow. Archived files must clearly state that they are not maintained API or current validation evidence.

### Delete

Delete files only when they satisfy all of these conditions:

- The behavior is already covered by a maintained test, doc, or example.
- The file is not referenced by active documentation.
- The file is not needed to reproduce an unresolved numerical issue.
- The relevant focused test group passes after removal.

## mRLFE first-pass audit targets

### Documentation

Review these first:

- docs/mrlfe/README.md
- docs/mrlfe/fitting_workflow.md
- docs/mrlfe/current_sweeps.md
- docs/mrlfe/fittool_grid_path_sensitivity.md
- docs/mrlfe/diagnostics/README.md
- docs/mrlfe/diagnostics/tracker_diagnostic_summary.md
- docs/mrlfe/archive/pending_cleanup.md
- docs/mrlfe/docs_cleanup_audit.md
- docs/mrlfe_atlas_policy_notes.md
- docs/gui/mrlfe_atlas_policy_integration.md

Expected cleanup:

- Ensure only one current mRLFE fitting route is described as maintained.
- Mark legacy direct/reference routes as diagnostics only.
- Cross-link the FitTool grid/path sensitivity note from fitting workflow and diagnostics docs.
- Move stale status text to archive or remove it if superseded.

### Examples and diagnostics

Review examples/mrlfe/diagnostics/ as a separate pass. The likely outcome is not immediate deletion, but classification into:

- maintained diagnostics,
- historical diagnostics,
- candidates for deletion after test coverage review.

### Tests

The test-layout migration is complete. Current mRLFE test and runner locations are:

- `tests/models/mrlfe/test_mrlfe_*.m` for model-family, atlas, residual, and diagnostic-policy contracts.
- `tests/app/fitting/test_gui_mrlfe_*.m` for FitTool-facing mRLFE contracts.
- `tests/app/gui/test_gui_*mrlfe*.m` for main GUI or GUI-surface contracts when present.
- `tests/runners/run_mrlfe_*.m` for maintained runner implementations.
- `tests/run_mrlfe_*.m` for compatibility wrappers only.

Expected cleanup:

- Keep route and FitTool contracts that protect current behavior.
- Identify overlapping tests that protect the same contract only after the focused runners are stable.
- Consolidate or delete individual tests only after duplicate coverage is confirmed.
- Avoid moving GUI/FitTool tests into `tests/models/mrlfe/`; those belong to the app layer.

## Validation policy

After mRLFE documentation-only cleanup:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_mrlfe_fit_atlas_tests
```

After mRLFE test/example cleanup:

```matlab
clear; clc; close all;
startup
run_mrlfe_smoke_tests
run_mrlfe_atlas_tests
run_mrlfe_fit_atlas_tests
run_gui_smoke_tests
```

Before merging broad repository cleanup:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
```

## Branch policy

Use small cleanup branches when changes affect behavior, tests, diagnostics, or large file groups. Documentation-only cleanup may be batched into a single hygiene branch if each edit remains audit-driven.

Do not mix solver behavior changes with repository hygiene changes.

Suggested branch naming:

```text
repo-hygiene-mrlfe-first
repo-hygiene-docs-consolidation
repo-hygiene-test-consolidation
repo-hygiene-mrlfe-docs-audit
```

Merged feature branches can be deleted after confirming their changes are present in main.

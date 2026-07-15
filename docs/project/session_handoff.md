# Session handoff

Updated: 2026-07-15
Branch: `refactor/correct-repository-layer-structure`
Phase 1 source: `a126cd41f0040b922b40e851957af0ada71d3023`
Origin main: `bf79cb468de66b76dbfe0e52ef8389e9ca0d025e`

## Completed work

Phase 2 moved 13 maintained MATLAB files without renaming their functions:
`aeRunSweep`; six shared sweep helpers; four model-specific app adapters;
`createFittingTab`; and the interactive AE grid-sweep visualization. No files
were added or deleted, and no compatibility wrapper was introduced.

Tracked files remain 491. Physical lines changed from 47,010 to 46,935, a net
reduction of 75 lines; MATLAB, Markdown, and CSV counts remain 422, 63, and 4.

The final ownership contract keeps model equations and numerical policies under
`models/`, reusable campaigns and aggregation under `analysis/`, and UI state,
callbacks, adapters, plotting, and export under `app/`. Production, app, and
analysis code have zero callers into `examples/`.

## Validation

Passed on MATLAB R2024b/PCWIN64:

```matlab
test_startup_path_policy
test_repository_root_utilities
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
run_all_smoke_tests
```

Focused AE validation, the AE SweepTool adapter, shared sweep renderer,
execution-profile surface tests, FitTool interaction tests, GUI quick, and GUI
smoke also passed. The bounded `aeRunSweep` before/after comparison was exact
for grids, Cp, validity, reliability, and summary tables.

Test ownership regenerated deterministically at 105 tests and 209 edges with
zero unowned tests, multiple owners, sibling overlaps, manual-only tests, or
cycles. Code Analyzer finished at 0 findings across 18 changed or moved MATLAB
files.

`run_extended_integration_tests` was not executed because file placement did
not materially change app dispatch, fitting orchestration, numerical model
boundaries, grids, policies, or solver behavior.

No pull request or merge was created.

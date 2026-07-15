# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: `test/test-suite-cleanup-phase1`
Base: `origin/main` at `0c3375ed58524e4e85088cb2775d8a0323042617`

## Completed in cleanup phase 1

The branch implements the audit's low-risk first phase without changing runner
membership or production/test behavior:

- active documentation now lists all nine deliberate compatibility wrappers;
- `run_main_gui_export_tests` is documented as a standalone public runner;
- mixed numerical/fitting/characterization runner descriptions are accurate;
- `run_gui_smoke_tests` consistently displays 17 direct tests;
- the three approved test implementations are in the maintained layout;
- exact Fit import `runtests` paths point to `tests/app/fitting/`;
- generated inventory and runner-edge CSVs were regenerated;
- an individual-entry runtime harness, plan, CSV, and evidence report were added.

No tests or wrappers were deleted. No runner calls were added or removed.

## Structural evidence

Before and after phase 1:

```text
tracked MATLAB files:       137
tests:                      104
runner implementations:     21
compatibility wrappers:       9
helpers:                       3
runner edges:                149
run_all reachable tests:      51
unregistered tests:            6
```

After normalizing the three old/new path pairs, the runner-edge diff count is
zero and the test membership diff count is zero.

## Runtime evidence

`analysis/test_inventory/measureTestRuntime.m` supports scalar or vector names,
test/runner selection, repeats, failure continuation, portable CSV output, and
min/median/max durations. It restores path/folder state and closes figures.
Hard timeout interruption is unavailable in-process and is reported as false.

Twenty individual priority tests were measured with MATLAB R2024b on PCWIN64 at
commit `efe9026b6fabc556f4b439e64b9440c7e2630a41`: 17 passed and 3 failed. See
`docs/repository/test_suite_runtime_evidence.md` for every duration, assertion
message, unmeasured test, and provisional planning classification.

The longest measured entries were:

```text
test_mrlfe_production_core_characterization   271.182 s
test_mrlfe_sweep_point_characterization       264.119 s
test_mrlfe_main_gui_characterization          109.959 s
test_mrlfe_public_contract_characterization   107.654 s
```

The three assertion failures were recorded without modification or retry:

```text
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
test_lightweight_numerical_regression
test_mrlfe_fit_fast_options_quality
```

## MATLAB validation completed

- inventory regeneration: 137 rows, 149 edges;
- `checkcode` for `measureTestRuntime`: no issues;
- two-repeat harness self-test: passed;
- moved renderer contract: passed;
- both moved Fit import unit-test files: passed;
- `run_fit_data_import_tests`: passed;
- `run_acoustoelastic_smoke_tests`: passed;
- `test_startup_path_policy`: passed;
- `test_repository_root_utilities`: passed;
- all nine wrapper and target paths: verified independently of path ordering.

The prohibited all-smoke, 36-case matrix, obsolete benchmark contract, and
execution-profile diagnostics runner were not executed.

## Next phase boundaries

- Diagnose the three recorded assertion failures separately.
- Do not infer registration or runner ownership from runtime alone.
- Keep quick/extended membership changes in a future dedicated branch.
- Preserve historical public commands through wrappers where required.
- Redesign the mapped-to-Fast benchmark separately; do not patch its assertions
  as part of runner separation.
- Keep any removal proposal isolated and evidence-backed.

## Working rules

- Refresh `origin/main` and create a new branch for each later phase.
- Preserve solver physics, GUI/fitting/sweep behavior, and public APIs.
- Use the inventory CSVs for static registration evidence and the runtime CSV
  only for measured-duration evidence.
- Do not open a PR or merge unless explicitly requested.

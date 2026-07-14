# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: `repo-hygiene-phase1-audit`

## Completed

Repository hygiene phase 1 completed a full tracked-tree audit and a
conservative implementation batch. The detailed evidence and classifications
are in:

```text
docs/repository/repository_cleanup_phase1_report.md
```

The branch removes:

```text
app/fitting/guiEvaluateFitFullCurve.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_opt_in_contract.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_s0_guard_contract.m
analysis/execution_profiles/execution_profile_inventory.csv
analysis/performance/execution_profile_benchmark_results.csv
```

The FitTool helper had no code, callback, registry, dynamic, or test caller and
was superseded by `guiBuildFitDisplayCurve` plus the explicit-action
`guiEvaluateRequestedFitCurve`. The removed tests were unregistered, failed on
the base commit, and asserted deleted route behavior. The CSV files were
generated outputs with no consumer; the inventory contained 35 missing paths.

Generated FIG/PNG sweep outputs are local, ignored, and untracked. They were
left untouched. No solver, GUI, fitting, sweep, startup, runner, or numerical
behavior was changed.

## Validation

Passed:

```matlab
run_mrlfe_fit_public_solver_tests
run_gui_smoke_tests
run_mrlfe_smoke_tests
```

Static diff checks and exact stale-reference searches passed. Intentional
historical/audit references and generator output-path references remain.

Known baseline or runtime limitations:

- `run_mrlfe_public_contract_tests` stops because its defaults test expects
  `balanced` to be invalid while the current implementation supports it.
- The first two legacy-cleanup absence tests pass; the characterization test
  fails an exact FitTool/direct Cp equality assertion unrelated to this diff.
- `run_mrlfe_neutral_production_helper_tests` timed out at five minutes.
- A combined focused plus `run_all_smoke_tests` command timed out at twenty
  minutes before buffered suite results were available.
- The two-day extended grid matrix was intentionally not run.

## Next cleanup phase

Use a documentation-focused branch to classify or consolidate:

1. stale generic execution-profile audit and benchmark documents/scripts;
2. historical mRLFE atlas/grid/route documents and their exact-path tests;
3. the fitting phase-log archive.

After that, use separate model-focused branches for diagnostic runtime review,
the orphan-looking `aeCopyLegacyResultFolder`, shared Rayleigh-Lamb mRLFE
compatibility fields, and the old `solveMRLFEBranch` implementation. Do not
combine those high-risk items with documentation cleanup.

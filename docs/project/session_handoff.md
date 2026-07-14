# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: `main`
Last known good merge: `ca0ccfc3ea636ae2e77f1a672d9d4e8d3304e7ba` (PR #110)
Latest documentation closeout commit: `f4bab4eed87c89640976201a79c859782fa36565`

## Completed

PR #110, **Repository hygiene phase 1 cleanup**, was merged into `main`.

The phase completed a full tracked-tree audit and a conservative cleanup batch.
Detailed evidence and classifications are recorded in:

```text
docs/repository/repository_cleanup_phase1_report.md
```

Merged removals:

```text
app/fitting/guiEvaluateFitFullCurve.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_opt_in_contract.m
tests/models/mrlfe/test_mrlfe_a0_delayed_direct_visco_s0_guard_contract.m
analysis/execution_profiles/execution_profile_inventory.csv
analysis/performance/execution_profile_benchmark_results.csv
```

The FitTool helper had no maintained static or dynamic caller and was superseded
by `guiBuildFitDisplayCurve` plus the explicit-action
`guiEvaluateRequestedFitCurve`. The removed tests were unregistered, failed on
the base commit, and asserted deleted route behavior. The CSV files were
generated snapshots with no consumer.

No solver mathematics, GUI behavior, fitting behavior, sweep behavior, startup,
runner architecture, model parameters, or numerical policies were changed.

## Validation actually executed

Passed:

```matlab
run_mrlfe_fit_public_solver_tests
run_gui_smoke_tests
run_mrlfe_smoke_tests
```

Static validation also passed:

```text
git diff --check
exact removed symbol/filename/path searches
tracked binary and empty-file checks
CSV consumer searches
```

Known baseline or runtime limitations:

- `run_mrlfe_public_contract_tests` stops because a stale defaults test expects
  `balanced` to be invalid while the maintained implementation supports it.
- The first two legacy-cleanup absence tests pass; the characterization test
  fails a pre-existing exact FitTool/direct Cp equality assertion.
- `run_mrlfe_neutral_production_helper_tests` timed out at five minutes.
- A broader focused plus `run_all_smoke_tests` batch timed out at twenty minutes
  before buffered results were available.
- The two-day extended mRLFE grid matrix was intentionally not run.

No additional manual GUI validation was recorded for the cleanup branch because
the changed helper was already covered by FitTool/public-solver and GUI smoke
contracts.

## Open issues

1. Stale Balanced-preset expectation in the mRLFE public-contract defaults test.
2. Pre-existing exact FitTool/direct Cp equality failure in
   `test_mrlfe_legacy_cleanup_characterization`.
3. Historical and duplicated documentation identified for a later consolidation
   phase.
4. Diagnostic scripts that need individual purpose/runtime review.
5. Higher-risk compatibility candidates:
   - `aeCopyLegacyResultFolder`;
   - shared Rayleigh-Lamb mRLFE compatibility fields;
   - old `solveMRLFEBranch` implementation;
   - possible future runner consolidation.

## Provisional next objectives

No next objective has been selected. The next chat should compare no more than
three focused options, likely among:

1. documentation consolidation;
2. stale test-contract diagnosis and repair;
3. diagnostic/compatibility audit.

Do not create a branch or modify files until the user selects the objective.

## One next action

Start a new chat, update and inspect `main`, read the persistent project context,
summarize the current state and open issues, then recommend a maximum of three
next objectives ordered by priority.

## Required reading for the next chat

1. `docs/project/README.md`
2. `docs/project/active_context.md`
3. `docs/project/session_handoff.md`
4. `docs/repository/repository_structure.md`
5. `docs/repository/naming_strategy.md`
6. Task-specific contracts only after the initial state summary.

## Working rules

- One new branch per selected task.
- Branch from updated `origin/main`.
- Never work directly on `main` for implementation work.
- Keep changes small and localized.
- Preserve architecture, naming, paths, and maintained contracts.
- Validate before opening a PR.
- The user performs merges manually.

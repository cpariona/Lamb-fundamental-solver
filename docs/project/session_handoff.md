# Session handoff

Updated: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Current branch: `test/mrlfe-contract-baseline`
Base: `origin/main` at `c590d8b6b60654d8581177de85f6134d3361ae91`

## Completed

This branch restores the maintained mRLFE test-contract baseline after repository
hygiene phase 1 exposed several stale expectations.

The branch changes tests and project documentation only. It does not modify:

- solver mathematics;
- public APIs;
- numerical presets or internal grid construction;
- GUI, fitting, or sweep behavior;
- startup/path configuration;
- runner names or runner architecture.

Test updates:

```text
tests/models/mrlfe/test_mrlfe_public_contract_defaults.m
tests/models/mrlfe/test_mrlfe_public_contract_validation.m
tests/models/mrlfe/test_mrlfe_legacy_cleanup_characterization.m
tests/app/gui/test_mrlfe_main_gui_consumer_equivalence.m
tests/app/gui/test_mrlfe_main_gui_result_contract.m
```

The updates establish that:

- `balanced` is a valid maintained preset in both defaults and request validation;
- unsupported names still raise `mrlfe:InvalidNumericalPreset`;
- the legacy-cleanup runner does not duplicate FitTool solver characterization;
- exact Main GUI/FitTool Cp equivalence is tested only when both use
  `gridPolicy = "numericalPreset"`;
- Main GUI applies Balanced directly and reports status consistently with the
  returned public quality state instead of relying on one fixed case remaining
  marginal.

## Audit performed

Before editing, the session reviewed:

- the public preset resolver and preset-grid tests;
- public-contract defaults and validation runners;
- legacy-cleanup runner ownership;
- Main GUI and FitTool consumer tests;
- `mrlfeEvaluateFitModel` grid-policy behavior;
- maintained entrypoints and test-layout contracts;
- historical commits that introduced direct Fast/Balanced/Robust support.

The audit found that FitTool same-grid equivalence already has dedicated coverage
in `test_mrlfe_fit_public_solver_characterization`, while the legacy-cleanup test
was repeating solver work with a different grid policy.

## Validation executed by the user

Passed:

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

The directly modified defaults and consumer-equivalence tests were also exercised
while progressing through the focused runners.

No extended grid matrix, broad fitting-recovery suite, or `run_all_smoke_tests`
was required. This branch changes no production numerical behavior, and the
focused runners provide direct coverage without introducing unnecessarily heavy
validation.

## Remaining limitations

- Synthetic and route-contract tests are not external physical validation.
- Grid-quality classifications near marginal branch tails can depend on the
  internal grid.
- Some long mRLFE suites have exceeded available execution time in previous
  sessions; no pass is claimed for runners not executed here.
- A complete test-suite audit remains useful but should be performed in a
  separate branch. It should map tests to runners, identify unregistered or
  duplicated coverage, classify lightweight versus heavy tests, and record
  practical runtime budgets.

## Next action

1. Pull the latest branch commits locally.
2. Run static Git checks over `origin/main...HEAD`.
3. Confirm a clean working tree.
4. Open a PR into `main`.
5. The user reviews and merges manually.

## Suggested later objectives

After this PR is merged, compare these focused options:

1. documentation consolidation;
2. dedicated test-suite audit and runtime classification;
3. diagnostic and compatibility audit.

Do not combine high-risk compatibility or solver-layer changes with documentation
or test-suite cleanup.

## Working rules

- One new branch per selected task.
- Branch from updated `origin/main`.
- Never work directly on `main` for implementation work.
- Keep changes small and localized.
- Preserve architecture, naming, paths, and maintained contracts.
- Validate before opening a PR.
- The user performs merges manually.

# MATLAB test-suite runtime evidence

## Scope and methodology

This document records cleanup phase-1 runtime evidence. It does not change
runner membership or establish hardware-dependent pass/fail thresholds.

- Test content was measured at commit
  `efe9026b6fabc556f4b439e64b9440c7e2630a41`.
- The three repaired baseline entries were remeasured at commit
  `14501278d15b5185f37074651eb4a048c32e2504`; all unrelated rows retain the
  original measurement commit.
- Measurements used MATLAB R2024b on `PCWIN64`.
- `measureTestRuntime` resolved tracked paths through `buildTestInventory`, ran
  each entry independently inside the MATLAB process, restored the path/current
  folder, closed figures, and captured failures.
- Three quick contracts used two repetitions. Numerical, fitting,
  characterization, and performance entries used one repetition.
- The harness has no hard in-process interrupt. Every row therefore records
  `HardTimeoutAvailable=false`; `TimeoutSeconds` is empty/`NaN`.
- The outer MATLAB batch command had a process ceiling only as an operational
  safeguard. It was not reached and is not represented as per-test timeout
  support.
- Durations include each test's own `startup` work when the test invokes it.
  They describe this machine and session only.

The complete machine-readable evidence is
`analysis/test_inventory/test_runtime_measurements.csv`.

## Measured entries

All durations below are measured seconds, not static estimates.

| Entrypoint | Status | Median | Minimum | Maximum | Repeats completed |
| --- | --- | ---: | ---: | ---: | ---: |
| `test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy` | passed | 4.297 | 4.297 | 4.297 | 1 |
| `test_acoustoelastic_iop_hgo_short_entrypoints` | passed | 0.066 | 0.066 | 0.066 | 1 |
| `test_ae_fit_synthetic_atlasA0` | passed | 20.612 | 20.612 | 20.612 | 1 |
| `test_execution_profile_current_contract` | passed | 7.920 | 7.692 | 8.149 | 2 |
| `test_execution_profile_fit_curve_metadata` | passed | 18.839 | 18.839 | 18.839 | 1 |
| `test_execution_profile_surface_integration` | passed | 9.134 | 9.134 | 9.134 | 1 |
| `test_gui_execution_profile_normalization` | passed | 7.509 | 7.457 | 7.560 | 2 |
| `test_lightweight_numerical_regression` | passed | 2.655 | 2.655 | 2.655 | 1 |
| `test_model_execution_profile_resolvers` | passed | 7.478 | 7.469 | 7.487 | 2 |
| `test_mrlfe_etaS_fit_forward_cache` | passed | 14.780 | 14.780 | 14.780 | 1 |
| `test_mrlfe_fit_fast_options_quality` | passed | 11.397 | 11.397 | 11.397 | 1 |
| `test_mrlfe_fit_grid_policy_performance` | passed | 10.306 | 10.306 | 10.306 | 1 |
| `test_mrlfe_fit_synthetic_A0Like` | passed | 11.974 | 11.974 | 11.974 | 1 |
| `test_mrlfe_main_gui_characterization` | passed | 109.959 | 109.959 | 109.959 | 1 |
| `test_mrlfe_production_core_characterization` | passed | 271.182 | 271.182 | 271.182 | 1 |
| `test_mrlfe_production_core_performance` | passed | 29.629 | 29.629 | 29.629 | 1 |
| `test_mrlfe_public_contract_characterization` | passed | 107.654 | 107.654 | 107.654 | 1 |
| `test_mrlfe_sweep_point_characterization` | passed | 264.119 | 264.119 | 264.119 | 1 |
| `test_rl_fit_evaluator_branch_consistency` | passed | 19.742 | 19.742 | 19.742 | 1 |
| `test_rl_fit_synthetic_A0` | passed | 23.506 | 23.506 | 23.506 | 1 |

All 20 current rows pass. No timeout occurred. The current median distribution
is: 1 below 2 seconds, 6 from 2 to below 10 seconds, 9 from 10 to below 30
seconds, and 4 at or above 30 seconds.

## Historical failures and repaired evidence

The phase-1 harness did not suppress or retry these failures. Their original
evidence remains part of the diagnosis history:

| Entrypoint | Recorded assertion message |
| --- | --- |
| `test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy` | `identityA0 CpCandidate length must match result.Cp length.` |
| `test_lightweight_numerical_regression` | `mRLFE A0Like Cp snapshot changed.` |
| `test_mrlfe_fit_fast_options_quality` | `Public fast fitting Cp RMSE differs from direct solver.` |

These assertion failures had empty MATLAB identifiers. Their old durations
describe time to failure and are not passing-runtime samples. The current CSV
rows replace only those three entries with passing measurements at `14501278`.
Root causes and before/after numerical evidence are in
`docs/repository/test_baseline_failure_diagnosis.md`.

## Pre-ownership unregistered-test evidence

At the time of the initial measurement, all six audit candidates lacked an
executable maintained-runner edge. This table preserves that historical state;
their current owners are recorded later in this document.

| Entrypoint | Static registration | Measured status | Median seconds |
| --- | --- | --- | ---: |
| `test_mrlfe_fit_grid_policy_performance` | no maintained runner | passed | 10.306 |
| `test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy` | no maintained runner | passed | 4.297 |
| `test_acoustoelastic_iop_hgo_short_entrypoints` | no maintained runner | passed | 0.066 |
| `test_mrlfe_etaS_fit_forward_cache` | no maintained runner | passed | 14.780 |
| `test_mrlfe_fit_fast_options_quality` | no maintained runner | passed | 11.397 |
| `test_rl_fit_evaluator_branch_consistency` | no maintained runner | passed | 19.742 |

No registration decision followed from duration or repaired status alone; the
later ownership phase also reviewed purpose and compatibility.

## Provisional planning classification from phase 1

The bullets below preserve the pre-ownership planning record and are
superseded by the final decisions at the end of this document.

- `test_gui_execution_profile_normalization`,
  `test_model_execution_profile_resolvers`, and
  `test_execution_profile_current_contract` remain provisional quick contract
  candidates. Their measured medians were below 10 seconds but above the
  aspirational 2-second contract target, including startup overhead.
- `test_acoustoelastic_iop_hgo_short_entrypoints` is a strong standalone quick
  contract candidate by measured runtime and passing behavior.
- `test_execution_profile_surface_integration` measured below 10 seconds, but
  remains integration coverage because it crosses maintained surfaces.
- Fit metadata, cache, branch-consistency, synthetic recovery, and fit-grid
  performance cases measured from roughly 10 to 24 seconds and should remain
  focused or extended pending runner design.
- The production performance check measured 29.629 seconds and remains
  benchmark/performance evidence rather than a quick contract.
- The four mRLFE characterizations measured 107.654 to 271.182 seconds. They are
  clear extended-validation candidates and explain much of the mixed-runner
  runtime risk.
- The repaired identityA0 contract measured below 10 seconds, but remains
  standalone pending an explicit registration decision. The repaired fitting
  regression measured above 10 seconds and remains focused/extended evidence.
- The repaired lightweight regression measured 2.655 seconds, but its direct
  core-runner ownership remains unchanged.

## Explicitly unmeasured tests

There are 84 tracked tests without a phase-1 harness row. Reason codes:

- **P**: outside the 20-entry priority set; measuring all 104 tests was not
  justified without proven hard timeout isolation.
- **E**: existing externally supplied evidence retained; automatic rerun was
  prohibited.
- **D**: deferred because the asserted contract is obsolete.

Some P entries were executed through focused layout validation, but they were
not timed individually and therefore remain unmeasured here.

- P `test_acoustoelastic_iop_hgo_atlasA0_smoke`
- P `test_acoustoelastic_iop_hgo_branch_persistence_refinement`
- P `test_acoustoelastic_iop_hgo_branch_policy_validation`
- P `test_acoustoelastic_iop_hgo_constitutive_identity`
- P `test_acoustoelastic_iop_hgo_fallback_invalidation`
- P `test_acoustoelastic_iop_hgo_internal_tracking_grid`
- P `test_ae_analyze_truncation_recovery`
- P `test_ae_physical_sweep_examples_contract`
- P `test_execution_profile_cleanup_contract`
- P `test_execution_profile_diagnostics_format`
- P `test_execution_profile_state_transition_contract`
- P `test_execution_profile_surface_metadata`
- E `test_execution_profile_validation_matrix`
- P `test_fit_display_curve_no_solver_contract`
- P `test_fit_parameter_execution_contract`
- P `test_fit_parameter_state_contract`
- P `test_fit_physical_qc_flat_rl`
- P `test_fit_physical_qc_synthetic_pass`
- P `test_fit_tool_interaction_helpers`
- P `test_fit_tool_model_registry_contract`
- P `test_fit_tool_requested_curve_models`
- P `test_fit_validation_ae_iop_hgo`
- P `test_fit_validation_ae_iop_hgo_hidden_params`
- P `test_fit_validation_mrlfe`
- P `test_fit_validation_mrlfe_hidden_params`
- P `test_fit_validation_rayleigh_lamb`
- P `test_fitting_helpers_smoke`
- P `test_gui_acoustoelastic_iop_hgo_main_adapter_smoke`
- P `test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke`
- P `test_gui_fit_registry_contract`
- P `test_gui_mrlfe_fit_full_curve_fast_contract`
- P `test_gui_mrlfe_fit_route_policy_contract`
- P `test_gui_mrlfe_fixed_etaS_fit_contract`
- P `test_gui_normalized_adapters_smoke`
- P `test_gui_prepare_experimental_fit_data`
- P `test_gui_read_experimental_fit_file`
- P `test_gui_struct_helpers_contract`
- P `test_gui_sweep_adapters_smoke`
- P `test_gui_sweep_registry_smoke`
- P `test_main_gui_export_contract`
- P `test_model_output_folder_helpers`
- P `test_mrlfe_diagnostic_material_sweep_contract`
- P `test_mrlfe_elastic_reference_buffer`
- P `test_mrlfe_etaS_zero_diagnostic_selection`
- P `test_mrlfe_etaS_zero_limit`
- D `test_mrlfe_execution_profile_benchmark_contract`
- P `test_mrlfe_fit_frequency_grid_contract`
- P `test_mrlfe_fit_public_solver_characterization`
- P `test_mrlfe_fit_public_solver_parameter_regression`
- P `test_mrlfe_fit_uses_public_solver`
- P `test_mrlfe_internal_grid_quality_guard`
- P `test_mrlfe_internal_tracking_grid`
- P `test_mrlfe_internal_tracking_grid_with_buffer`
- P `test_mrlfe_legacy_cleanup_characterization`
- P `test_mrlfe_main_gui_consumer_equivalence`
- P `test_mrlfe_main_gui_result_contract`
- P `test_mrlfe_main_gui_uses_public_solver`
- P `test_mrlfe_maintained_entrypoints_naming`
- P `test_mrlfe_model_candidate_names`
- P `test_mrlfe_neutral_seed_contract`
- P `test_mrlfe_neutral_tracker_termination_contract`
- P `test_mrlfe_no_historical_production_dependencies`
- P `test_mrlfe_no_legacy_route_flags`
- P `test_mrlfe_no_legacy_routes`
- P `test_mrlfe_numerical_preset_grids`
- P `test_mrlfe_production_core_contract`
- P `test_mrlfe_production_core_presets`
- P `test_mrlfe_public_contract_defaults`
- P `test_mrlfe_public_contract_result_schema`
- P `test_mrlfe_public_contract_validation`
- P `test_mrlfe_residual_objective_contract`
- P `test_mrlfe_robust_start_contract`
- P `test_mrlfe_smoke`
- P `test_mrlfe_solve_frequency_override`
- P `test_mrlfe_sweep_metadata_and_mapping`
- P `test_mrlfe_sweep_uses_public_solver`
- P `test_mrlfe_termination_policy`
- P `test_mrlfe_tracking_quality_summary`
- P `test_mrlfe_tracking_strategy_comparison`
- P `test_mrlfe_viscous_default_internal_tracking_grid`
- P `test_repository_root_utilities`
- P `test_rl_fit_rejects_prediction_fallback`
- P `test_startup_path_policy`
- P `test_sweep_plot_renderer_contract`

The E entry retains the user-supplied result: 36 combinations passed in
approximately 178.7 seconds on the user's MATLAB machine. It was not rerun in
this task. The D entry remains manual/deferred because its mapped-to-Fast
assertions describe the former policy and would not provide useful current
contract evidence.

## Focused runner validation

The repair task executed three focused runners after their individual tests
passed. These are process wall times from the validation commands, not harness
rows and not duration thresholds:

| Runner | Result | Process wall time |
| --- | --- | ---: |
| `run_acoustoelastic_smoke_tests` | passed | 105.5 s |
| `run_core_smoke_tests` | passed | 71.9 s |
| `run_mrlfe_fit_public_solver_tests` | passed | 108.0 s |

Other aggregate runners remain unmeasured by the harness. In particular,
`run_gui_smoke_tests`, `run_mrlfe_production_core_tests`, and
`run_fit_validation_tests` were not executed in the repair task.

## Ownership-tier runner measurements

The ownership reorganization measured the new tiers from the final working
tree on MATLAB R2024b/PCWIN64. `measureTestRuntime` ran each runner once in the
current MATLAB process; hard timeout enforcement remains unavailable.

| Runner | Static test reach | Status | Elapsed seconds |
| --- | ---: | --- | ---: |
| `run_quick_contract_tests` | 14 | passed | 134.42 |
| `run_quick_smoke_tests` | 47 | passed | 352.14 |
| `run_numerical_regression_tests` | 17 | passed | 256.08 |
| `run_fit_tool_requested_curve_tests` | 1 | passed | 27.961 |
| `run_gui_execution_profile_tests` | 2 | passed | 23.583 |
| `run_gui_extended_tests` | 3 | passed | 50.810 |
| `run_performance_and_benchmark_tests` | 2 | passed | 46.794 |

Additional focused timing used while refining the tier boundary:

| Runner | Status | Elapsed seconds | Decision supported |
| --- | --- | ---: | --- |
| `run_core_contract_tests` | passed | 22.185 | retain in quick contracts |
| `run_execution_profile_contract_tests` | passed | 61.275 | retain measured sub-10-second child contracts as one owner |
| `run_fit_data_import_tests` | passed | 4.539 | retain in quick contracts |
| former mixed `run_fit_tool_interaction_tests` | passed | 37.535 | split helper from requested-curve solving |
| former three-test `run_mrlfe_public_api_contract_tests` | passed | 31.464 | split solver-backed result schema from defaults/validation |

The two “former” rows were measured before the final focused split and are
historical design evidence, not current-runner timing claims. One earlier
`run_quick_contract_tests` run also passed all contained tests in 164.38 s
before those splits. Its outer shell command failed only when the runner's
script-side `clear` removed an ad hoc caller timer; this was not a test failure.

One machine's elapsed time is descriptive. No duration is asserted in test
code, and no pass/fail result depends on speed.

## Final ownership decisions

The six formerly unregistered tests now have explicit owners. The fit-grid
timing characterization belongs to `run_performance_and_benchmark_tests`; the
two AE contracts belong to `run_ae_quick_tests`; the two mRLFE fitting tests
belong to `run_mrlfe_fitting_regression_tests`; and RL branch consistency is
owned directly by `run_numerical_regression_tests`.

The obsolete mapped-to-Fast benchmark is the only manual-only test. It remains
deferred and was not executed. The 36-case validation matrix retains the
externally supplied approximately 178.7-second evidence and was not rerun.

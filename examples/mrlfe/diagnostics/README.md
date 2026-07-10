# mRLFE diagnostics

This folder contains optional diagnostic scripts for inspecting the maintained
public mRLFE real-k route. These scripts are not production entrypoints and are
not lightweight unit tests.

For automated validation of maintained behavior, use the focused runners:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_legacy_cleanup_tests
```

The obsolete atlas/direct-visco diagnostics that called removed route files were
deleted during the legacy-route cleanup. Historical conclusions remain in
`docs/validation/` and `docs/validation/mrlfe_legacy_route_inventory.md`.

## Current Diagnostics

Retained diagnostics:

```matlab
compare_mrlfe_tracker_vs_condition_peaks
diagnose_etaS_forward_cache
diagnose_fit_timing
diagnose_fit_option_sensitivity
diagnose_mrlfe_atlas_primary_policy_matrix
diagnose_mrlfe_gui_performance_32kHz
diagnose_mrlfe_visco_residual_landscape
diagnose_mrlfe_visco_validity_breakdown
stress_test_mrlfe_real_k_range
```

These scripts should use maintained public or neutral model-layer APIs. Do not
restore deleted route entrypoints solely for diagnostics.

## Generated Outputs

Diagnostic scripts may write outputs under:

```text
outputs/mrlfe
```

Generated `.mat`, `.csv`, `.fig`, and `.png` diagnostic artifacts are not source
files and should not be committed unless a task explicitly asks for an audited
report artifact.

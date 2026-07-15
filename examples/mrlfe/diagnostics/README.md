# mRLFE diagnostics

These optional scripts inspect the maintained public `mrlfeSolve` route. They
are not production entrypoints or lightweight unit tests.

| Command | Purpose | Runtime | Output | Validation |
| --- | --- | --- | --- | --- |
| `diagnose_mrlfe_fit_performance` | Compare fit profiles and etaS cache parity/cost | extended | base workspace only | `diagnose_mrlfe_fit_performance` |
| `diagnose_mrlfe_atlas_primary_policy_matrix` | Preserved public diagnostic command pending product-level replacement | extended | base workspace only | manual command |
| `run_mrlfe_targeted_grid_validation` | Repeatable targeted public-grid validation | extended | documented script outputs | manual command |
| `validate_grid_presets` | Compare public preset grids with a dense reference | extended | base workspace only | manual command |
| `validate_grid_presets_full` | Wider preset-grid characterization | long | base workspace only | manual command |

Historical numerical investigations are under `archive/`. That folder is
excluded from `startup`, and its scripts are not active contracts.

Automated maintained behavior is owned by:

```matlab
run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_fit_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_legacy_cleanup_tests
```

Generated `.mat`, `.csv`, `.fig`, and `.png` outputs are not source artifacts
and must not be committed without an explicit audited-output requirement.

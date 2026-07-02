# Tests layout

This document defines the target organization for the repository test suite. It is a migration contract: new tests should follow this structure, and existing tests should be moved gradually in small PRs.

## Current policy

The `startup` function adds `tests/` recursively to the MATLAB path. Therefore, internal test folders can be reorganized as long as maintained runner names remain available and test function/script names remain unique.

Do not move large groups of tests without updating the relevant runners and documentation in the same PR.

## Current compatibility wrappers

Some root-level and legacy-folder runner wrappers are intentionally preserved while the layout is migrated. These wrappers keep older public commands working and delegate to maintained runner implementations under `tests/runners/`.

Current compatibility wrappers include:

```text
tests/run_acoustoelastic_smoke_tests.m
tests/run_all_smoke_tests.m
tests/run_core_smoke_tests.m
tests/run_gui_smoke_tests.m
tests/run_mrlfe_atlas_tests.m
tests/run_mrlfe_fit_atlas_tests.m
tests/run_mrlfe_smoke_tests.m
tests/fitting/run_fit_validation_tests.m
```

## Final layout audit

The test-layout migration has reached its intended steady state. All non-wrapper test files now live under one of the layout-owned folders:

```text
tests/app/
tests/models/
tests/runners/
tests/shared/
```

The only MATLAB files intentionally left outside those folders are the compatibility wrappers listed above. Do not add new test implementations at the root of `tests/` or under legacy folders such as `tests/fitting/`; add new tests to the appropriate layout-owned folder instead.

## Migration status

Runner implementations live under `tests/runners/`, with public runner commands preserved through wrappers or direct runner files.

Model-family Rayleigh-Lamb tests have been moved under:

```text
tests/models/rayleigh_lamb/
```

Current Rayleigh-Lamb model tests:

```text
tests/models/rayleigh_lamb/test_rl_fit_evaluator_branch_consistency.m
tests/models/rayleigh_lamb/test_rl_fit_synthetic_A0.m
```

Model-family mRLFE tests have been moved under:

```text
tests/models/mrlfe/
```

Model-family AE IOP/HGO tests have been moved under:

```text
tests/models/acoustoelastic_iop_hgo/
```

Current AE IOP/HGO model tests:

```text
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_atlasA0_smoke.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_branch_persistence_refinement.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_branch_policy_validation.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_constitutive_identity.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_fallback_invalidation.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_internal_tracking_grid.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_short_entrypoints.m
tests/models/acoustoelastic_iop_hgo/test_ae_analyze_truncation_recovery.m
tests/models/acoustoelastic_iop_hgo/test_ae_fit_synthetic_atlasA0.m
```

GUI/app-layer smoke tests have started moving under:

```text
tests/app/gui/
```

Current app-gui tests:

```text
tests/app/gui/test_gui_acoustoelastic_iop_hgo_main_adapter_smoke.m
tests/app/gui/test_gui_normalized_adapters_smoke.m
```

SweepTool/app-layer contracts have started moving under:

```text
tests/app/sweeps/
```

Current app-sweeps tests:

```text
tests/app/sweeps/test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke.m
tests/app/sweeps/test_gui_sweep_adapters_smoke.m
tests/app/sweeps/test_gui_sweep_registry_smoke.m
```

FitTool/app-layer contracts have started moving under:

```text
tests/app/fitting/
```

Current app-fitting tests:

```text
tests/app/fitting/test_fit_tool_model_registry_contract.m
tests/app/fitting/test_gui_fit_registry_contract.m
tests/app/fitting/test_gui_mrlfe_elastic_atlas_guard_contract.m
tests/app/fitting/test_gui_mrlfe_fit_full_curve_fast_contract.m
tests/app/fitting/test_gui_mrlfe_fit_route_policy_contract.m
tests/app/fitting/test_gui_mrlfe_fit_zero_eta_atlas_contract.m
tests/app/fitting/test_gui_mrlfe_fixed_etaS_fit_contract.m
tests/app/fitting/test_gui_mrlfe_unified_atlas_policy_contract.m
```

Shared fitting validation, fitting-QC, and fitting-helper tests have started moving under:

```text
tests/shared/fitting/
```

Current shared-fitting tests and helpers:

```text
tests/shared/fitting/assertFitRecovery.m
tests/shared/fitting/test_fit_physical_qc_flat_rl.m
tests/shared/fitting/test_fit_physical_qc_synthetic_pass.m
tests/shared/fitting/test_fit_validation_ae_iop_hgo.m
tests/shared/fitting/test_fit_validation_ae_iop_hgo_hidden_params.m
tests/shared/fitting/test_fit_validation_mrlfe.m
tests/shared/fitting/test_fit_validation_mrlfe_hidden_params.m
tests/shared/fitting/test_fit_validation_rayleigh_lamb.m
tests/shared/fitting/test_fitting_helpers_smoke.m
tests/shared/utilities/test_startup_path_policy.m
tests/shared/fitting/test_rl_fit_rejects_prediction_fallback.m
```

## Target structure

```text
tests/
├─ README.md
├─ runners/
├─ shared/
│  ├─ fitting/
│  ├─ sweeps/
│  └─ utilities/
├─ models/
│  ├─ rayleigh_lamb/
│  ├─ mrlfe/
│  └─ acoustoelastic_iop_hgo/
└─ app/
   ├─ gui/
   ├─ fitting/
   └─ sweeps/
```

## Folder responsibilities

### `tests/runners/`

Contains maintained runner entrypoints that orchestrate groups of tests.

Examples:

```matlab
run_all_smoke_tests
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
run_mrlfe_atlas_tests
run_mrlfe_fit_atlas_tests
run_fit_validation_tests
```

During migration, root-level wrappers may remain under `tests/` so existing commands keep working. Wrappers should be thin and should delegate to the implementation under `tests/runners/`.

### `tests/shared/`

Contains tests for reusable infrastructure that is not owned by one model family or one app surface.

Use this folder for tests of:

```text
shared fitting helpers
shared sweep helpers
shared plotting or utility contracts
path-independent helper behavior
```

Subfolders:

```text
tests/shared/fitting/     shared fitting contracts and quality-control tests
tests/shared/sweeps/      shared parametric sweep tests
tests/shared/utilities/   path, naming, and general utility tests
```

### `tests/models/`

Contains model-family tests. A test belongs here when it validates a physical model, numerical solver, model-specific residual, model-specific fitting adapter, or model-specific diagnostic policy.

Subfolders:

```text
tests/models/rayleigh_lamb/           Rayleigh-Lamb solver, residual, branch, and fitting tests
tests/models/mrlfe/                   mRLFE real-k, atlas, policy, and model-family tests
tests/models/acoustoelastic_iop_hgo/  AE IOP/HGO solver, atlasA0, sweep, fitting, and diagnostic-policy tests
```

Model-family tests should not depend on GUI state. If a test requires GUI request/normalization code, place it under `tests/app/` instead.

### `tests/app/`

Contains tests for GUI and app-layer behavior. A test belongs here when it validates request building, registries, adapters, normalization, plotting contracts, FitTool, SweepTool, or main GUI integration.

Subfolders:

```text
tests/app/gui/      main GUI and GUI-surface contracts
tests/app/fitting/  FitTool and app-level fitting dispatch contracts
tests/app/sweeps/   SweepTool and app-level sweep dispatch contracts
```

App tests may call model adapters, but they should focus on app-layer contracts rather than solver physics.

## Migration rules

1. Keep public runner commands stable unless there is a deliberate deprecation plan.
2. Prefer moving one coherent test family at a time.
3. Update runner files in the same commit as each move.
4. Update `docs/repository/maintained_entrypoints.md` when runner names or maintained test groups change.
5. Use wrappers temporarily when preserving old runner commands reduces disruption.
6. Avoid mixing test moves with solver behavior changes.
7. Run the relevant focused runner after each move, then run the full smoke suite before merging.

## Validation after test-layout changes

For runner or path changes, run:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
run_fit_validation_tests
run_mrlfe_fit_atlas_tests
```

For app/GUI moves, run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_all_smoke_tests
```

For app/SweepTool moves, run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_all_smoke_tests
```

For app/FitTool moves, run:

```matlab
clear; clc; close all;
startup
run_gui_smoke_tests
run_all_smoke_tests
```

For app/FitTool mRLFE moves, run:

```matlab
clear; clc; close all;
startup
run_mrlfe_fit_atlas_tests
run_gui_smoke_tests
run_all_smoke_tests
```

For shared fitting moves, run:

```matlab
clear; clc; close all;
startup
test_fitting_helpers_smoke
run_fit_validation_tests
run_all_smoke_tests
```

For Rayleigh-Lamb model-family moves, run:

```matlab
clear; clc; close all;
startup
test_rl_fit_synthetic_A0
test_rl_fit_evaluator_branch_consistency
run_fit_validation_tests
run_all_smoke_tests
```

For AE IOP/HGO model-family moves, run:

```matlab
clear; clc; close all;
startup
run_acoustoelastic_smoke_tests
run_all_smoke_tests
```

For a focused model-family move, also run the corresponding focused runner when available.

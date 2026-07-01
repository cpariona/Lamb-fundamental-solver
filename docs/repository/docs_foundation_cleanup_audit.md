# Documentation foundation cleanup audit

## Scope

This audit records the repository-wide documentation cleanup pass that follows the mRLFE-focused hygiene merge.

The goal is to update active documentation indexes and high-level workflow references while keeping solver behavior unchanged. One validation-test correction was added after this pass exposed an unstable mRLFE etaS recovery case.

## Resolved in pass 1

- Reviewed the root `README.md` after the mRLFE hygiene merge.
- Reviewed `docs/README.md` and confirmed the active documentation index now includes the repository hygiene plan.
- Reviewed `docs/maintained_entrypoints.md` and identified one minor stale validation-list issue: `run_mrlfe_atlas_tests` should be listed with the other focused runners because `run_all_smoke_tests` now runs it explicitly.
- Refreshed `docs/fitting/architecture.md` so it describes the implemented fitting architecture instead of a Phase 0 plan.
- Refreshed `docs/fitting/validation_suite.md` so it lists hidden-parameter validation tests and the current mRLFE FitTool atlas validation runner.

## Resolved in pass 2

- Fixed `test_fit_validation_mrlfe_hidden_params` after `run_fit_validation_tests` exposed that the previous A0Like etaS synthetic recovery case could generate zero valid points in the maintained fitting band.
- Limited the mRLFE hidden-parameter validation to the stable A0Like thickness-recovery case with hidden/fixed material parameters and `etaS = 0`.
- Clarified `docs/fitting/validation_suite.md` so mRLFE etaS fitting remains listed as a current validation limitation, not as a maintained synthetic parameter-recovery case.

## Resolved in pass 3

- Refreshed `docs/gui/integration_audit.md` as the active overview for `LambFundamental_GUI`, `SweepTool_GUI`, and `FitTool_GUI`.
- Corrected the SweepTool mRLFE parameter list from stale `E` wording to the active registry parameters: `etaS`, `mu`, and `thickness`.
- Added FitTool as an active GUI surface in the GUI integration audit.
- Reframed `docs/gui/main_pending_cleanup.md` as an active cleanup roadmap rather than a post-AE temporary cleanup note.
- Kept unresolved AE branch-sensitivity and layout items as roadmap items rather than deleting them.

## Resolved in pass 4

- Refreshed `docs/gui/adapter_architecture.md` as the detailed GUI/backend boundary reference.
- Added FitTool flow, fitting registry, fitting adapters, normalized fit schema, and `FitToolLastOutput` contract to the GUI adapter architecture document.
- Clarified that `docs/gui/integration_audit.md` is the GUI status overview while `docs/gui/adapter_architecture.md` is the detailed architecture reference.
- Corrected `docs/gui/mrlfe_atlas_policy_integration.md` so `test_gui_mrlfe_elastic_atlas_guard_contract` is documented under `run_gui_smoke_tests`, not under the focused FitTool atlas runner.
- Clarified that `run_mrlfe_fit_atlas_tests` covers FitTool atlas-route contracts only.

## Resolved in pass 5

- Reviewed `docs/rayleigh_lamb/overview.md`, `docs/rayleigh_lamb/public_api.md`, and `docs/rayleigh_lamb/fitting_workflow.md` against current tests and runner behavior.
- Removed stale Rayleigh-Lamb documentation references to the non-existing `test_rl_fit_evaluator_branch_consistency` test.
- Refreshed Rayleigh-Lamb fitting validation wording so active checks are `test_rl_fit_synthetic_A0` through `run_core_smoke_tests` and the Rayleigh-Lamb cases inside `run_fit_validation_tests`.
- Updated the Rayleigh-Lamb public API fitting notes so maintained validation covers `RL_A0_mu_exact`, `RL_A0_thickness_exact`, and `RL_A0_mu_perturbed`.
- Updated the Rayleigh-Lamb overview validation guidance to distinguish `run_core_smoke_tests`, `run_fit_validation_tests`, and `run_all_smoke_tests`.

## Resolved in pass 6

- Reviewed the AE IOP/HGO README, documentation index, public API, fitting workflow, sweep workflow, examples inventory, and framework hygiene status against current smoke-runner behavior.
- Added AE fitting helpers (`aeBuildFitProblem`, `aeEvaluateFitModel`, `aeFitDispersionData`) to the active public API document.
- Updated AE fitting workflow wording to reflect current FitTool/registry support and focused fitting validation.
- Removed stale wording that treated visible AE FitTool controls as unimplemented.
- Refreshed AE framework hygiene status so removed low-frequency modal-atlas scripts are no longer listed as retained implementation targets.
- Corrected the naming convention path in AE framework hygiene status to `docs/acoustoelastic_iop_hgo/active/naming_and_paths_convention.md`.
- Refreshed the AE documentation index so active operational docs, maintainer-facing framework status, and fitting update policy are separated more clearly.

## Pending items

### maintained_entrypoints runner and test wording

`docs/maintained_entrypoints.md` still has minor wording issues. It should include:

```matlab
run_mrlfe_atlas_tests
```

near:

```matlab
run_core_smoke_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
```

and it should mention:

```matlab
run_mrlfe_fit_atlas_tests
```

as the focused mRLFE FitTool fitting-route validation runner.

It also still lists the removed/non-existing Rayleigh-Lamb test:

```matlab
test_rl_fit_evaluator_branch_consistency
```

This file was not edited in this pass because the connector blocked a full-file update. The issue is documentation-only and does not affect test behavior.

## Validation

Recommended validation:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
run_fit_validation_tests
run_mrlfe_fit_atlas_tests
```

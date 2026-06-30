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

## Pending items

### maintained_entrypoints runner wording

`docs/maintained_entrypoints.md` still has a minor wording issue in the focused runner list. It should include:

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

This was not edited in this pass because the connector blocked a full-file update. It is documentation-only and does not affect test behavior.

### GUI docs

Review next:

```text
docs/gui/adapter_architecture.md
docs/gui/mrlfe_atlas_policy_integration.md
```

Likely updates:

- decide whether `adapter_architecture.md` should be the detailed GUI architecture doc while `integration_audit.md` remains the status overview;
- ensure the mRLFE atlas policy document still matches the active tests and route metadata after the mRLFE hygiene merge.

### Model-family docs

After GUI and fitting docs are coherent, review:

```text
docs/rayleigh_lamb/
docs/acoustoelastic_iop_hgo/
```

Do not delete model-family docs until their active entrypoints and validation references are checked.

## Validation

Recommended validation:

```matlab
clear; clc; close all;
startup
run_all_smoke_tests
run_fit_validation_tests
run_mrlfe_fit_atlas_tests
```

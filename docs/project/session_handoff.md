# Session handoff

Updated: 2026-07-06
Repository: cpariona/Lamb-fundamental-solver
Current branch: ae-add-physical-parameter-sweeps
Base branch: main
Last known good commit: branch HEAD after final validation

## Current task

Close the cross-model sweep unification branch and prepare it for user-owned
pull-request review. Do not merge into `main` from this branch.

## Completed

- Preserved Alternative B sweep plotting architecture:
  - AE: `aeRunSweep` output -> `aeBuildSweepPlotData` -> `plotSweepCpFigure`.
  - mRLFE/Rayleigh-Lamb: `runParametricSweep` output -> `buildParametricSweepPlotData` -> `plotSweepCpFigure`.
- Updated `plotSweepCpFigure` to use one standard MATLAB axes, a compact fixed-parameter subtitle, and a native lower-right legend for sweep values.
- Kept model-specific result extraction out of the shared renderer.
- Renamed maintained sweep entrypoints directly:
  - AE IOP/HGO: `ae_sweep_iop_A0Like`, `ae_sweep_mu_A0Like`, `ae_sweep_thickness_A0Like`, `ae_sweep_k1_A0Like`, `ae_sweep_k2_A0Like`, `ae_sweep_radius_A0Like`, `ae_sweep_mu_iop_A0Like`.
  - mRLFE: `mrlfe_sweep_mu_A0Like`, `mrlfe_sweep_mu_S0Like`, `mrlfe_sweep_etaS_A0Like`, `mrlfe_sweep_etaS_S0Like`, `mrlfe_sweep_thickness_A0Like`, `mrlfe_sweep_thickness_S0Like`.
  - Rayleigh-Lamb: `rl_sweep_thickness_A0`, `rl_sweep_thickness_S0`.
- Removed old maintained sweep entrypoint names without compatibility wrappers.
- Updated active docs, tests, runners, and validation commands to canonical names.

## Validation performed

MATLAB validation was run locally from the repository root after:

```matlab
restoredefaultpath
clear functions
rehash toolboxcache
startup
```

Focused tests:

```matlab
startup
startup
startup
test_startup_path_policy
test_mrlfe_maintained_entrypoints_naming
test_acoustoelastic_iop_hgo_short_entrypoints
test_ae_physical_sweep_examples_contract
test_sweep_plot_renderer_contract
```

Focused suites:

```matlab
run_core_smoke_tests
run_mrlfe_smoke_tests
run_acoustoelastic_smoke_tests
```

Complete maintained suite:

```matlab
run_all_smoke_tests
```

Result: `Complete smoke-test suite passed.`

## Manual validation

Representative renamed sweeps were executed:

```matlab
ae_sweep_iop_A0Like
ae_sweep_k2_A0Like
mrlfe_sweep_mu_A0Like
mrlfe_sweep_etaS_A0Like
rl_sweep_thickness_A0
rl_sweep_thickness_S0
```

The earlier external-panel layout was fully validated but was replaced after
manual review. The current native subtitle/legend layout still requires final
local visual validation and a rerun of the focused and complete smoke suites.

## Open issues

- Final validation is pending for the native subtitle/legend layout.
- The previously identified solver-route consistency audit remains a separate future task and is not part of this branch.
- Generated Results and example figure artifacts from manual sweep validation are ignored artifacts and should not be committed.

## Next action

Run the focused renderer test, representative AE/mRLFE/RL sweeps, and
`run_all_smoke_tests`. After visual approval, commit any local documentation
patch, push `ae-add-physical-parameter-sweeps`, and prepare it for user-owned
pull-request review. Do not merge into `main`.

## Do not change

- Do not work on `main`.
- Do not merge this branch.
- Do not open a pull request unless explicitly requested.
- Do not reintroduce old sweep wrappers or aliases.
- Do not modify numerical solver, AE branch-selection, mRLFE branch-selection, Rayleigh-Lamb numerical behavior, fitting behavior, GUI behavior, or SweepTool behavior unless a future task explicitly requires it.
- Do not treat archived audits as current contracts.

## Relevant files

- `docs/project/README.md`
- `docs/project/active_context.md`
- `docs/project/session_handoff.md`
- `analysis/plotSweepCpFigure.m`
- `analysis/buildParametricSweepPlotData.m`
- `analysis/acoustoelastic_iop_hgo/aeBuildSweepPlotData.m`
- `analysis/acoustoelastic_iop_hgo/aePlotSweepCp.m`
- `analysis/mrlfe/mrlfeRunSweepExample.m`
- `analysis/rayleigh_lamb/rlRunSweepExample.m`
- `docs/workflows/sweeps/parametric_sweeps.md`
- `docs/repository/maintained_entrypoints.md`
- `docs/repository/naming_strategy.md`
- `docs/models/acoustoelastic_iop_hgo/active/sweep_workflow.md`
- `docs/models/mrlfe/current_sweeps.md`
- `docs/models/rayleigh_lamb/overview.md`
- `tests/analysis/test_sweep_plot_renderer_contract.m`
- `tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_short_entrypoints.m`
- `tests/models/acoustoelastic_iop_hgo/test_ae_physical_sweep_examples_contract.m`
- `tests/models/mrlfe/test_mrlfe_maintained_entrypoints_naming.m`
- `tests/runners/run_core_smoke_tests.m`
- `tests/runners/run_mrlfe_smoke_tests.m`
- `tests/runners/run_acoustoelastic_smoke_tests.m`

## Commands to resume

```bash
git fetch origin
git switch ae-add-physical-parameter-sweeps
git pull --ff-only origin ae-add-physical-parameter-sweeps
git status -sb
git log --oneline --decorate -10
```

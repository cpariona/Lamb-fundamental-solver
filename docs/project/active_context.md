# Active project context

Last reviewed: 2026-07-06
Repository: cpariona/Lamb-fundamental-solver
Default branch: main

## Current development focus

Branch `ae-add-physical-parameter-sweeps` contains the current cross-model sweep
unification work. The maintained sweep plotting architecture is Alternative B:
model-specific adapters produce neutral plot data, and `plotSweepCpFigure`
renders the shared figure layout.

The active sweep plotting layout uses a main Cp(f) data axes on the left and a
separate right-side information panel for fixed parameters and sweep values. The
fixed-parameter block excludes the swept parameter.

Maintained public sweep entrypoints use the canonical
`<model>_sweep_<parameter>_<branch>` convention across AE IOP/HGO, mRLFE, and
Rayleigh-Lamb. Old sweep entrypoints were removed directly without wrappers.

## Recently completed capabilities

- Execution-profile infrastructure and diagnostics.
- End-to-end validation across Main GUI, SweepTool, and FitTool.
- FitTool experimental data import.
- Manual experimental table editing.
- Persistent axis controls.
- Explicit requested fitted-curve solver evaluation.
- Separated parameter and fit-quality summaries.
- Persistent project context, session handoff, reusable task templates, and initial ADRs.
- Cross-model sweep figure layout unification with external information panel.
- Canonical maintained sweep entrypoint names across AE IOP/HGO, mRLFE, and Rayleigh-Lamb.

## Active architectural contracts

- GUI surfaces delegate to adapters and backends. See `docs/workflows/gui/adapter_architecture.md`.
- Model physics remains in model layers. See `docs/repository/repository_structure.md`.
- Fitting uses request -> dispatcher -> adapter -> maintained model API. See `docs/workflows/fitting/architecture.md`.
- `executionProfile` is distinct from route policy and optimizer options. See `docs/architecture/execution_profiles_surface_integration.md`.
- Naming follows the repository naming strategy. See `docs/repository/naming_strategy.md`.
- Use one feature branch per task. See `docs/repository/repository_hygiene_plan.md`.
- The user performs merges manually.

## Known cross-cutting limitations

- Execution-profile presentation is unified, but internal model execution structures are not fully unified.
- mRLFE still maps non-Fast requests to validated fast atlas behavior in maintained FitTool routes.
- Model-specific execution architecture may require a future dedicated audit or refactor.
- Solver-physics refactors should not be mixed with documentation or GUI-only work.

## Planned development phases

This list is provisional:

1. Finish validation, commit, and push `ae-add-physical-parameter-sweeps`.
2. Prepare the branch for user-owned pull-request review.
3. Keep solver-physics refactors separate from sweep plotting and naming work.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/validation_status.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
- `docs/workflows/sweeps/parametric_sweeps.md`
- `docs/models/acoustoelastic_iop_hgo/active/sweep_workflow.md`
- `docs/models/mrlfe/current_sweeps.md`
- `docs/models/rayleigh_lamb/overview.md`
- `docs/architecture/execution_profiles_surface_integration.md`

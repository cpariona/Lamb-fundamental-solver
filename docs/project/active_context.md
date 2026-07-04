# Active project context

Last reviewed: 2026-07-04
Repository: cpariona/Lamb-fundamental-solver
Default branch: main

## Current development focus

Persistent project context and session handoff are now available on `main`.

The next technical objective has not yet been selected. The next session should
recover the current state from these documents, compare the remaining options,
and define one focused engineering task before creating a feature branch.

## Recently completed capabilities

- Execution-profile infrastructure and diagnostics.
- End-to-end validation across Main GUI, SweepTool, and FitTool.
- FitTool experimental data import.
- Manual experimental table editing.
- Persistent axis controls.
- Explicit requested fitted-curve solver evaluation.
- Separated parameter and fit-quality summaries.
- Persistent project context, session handoff, reusable task templates, and initial ADRs.

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

1. Select the next engineering objective in a new chat.
2. Create one focused feature branch from updated `origin/main`.
3. Audit model execution architecture before designing real mRLFE profiles, if that objective is selected.
4. Keep solver refactors separate from GUI and documentation tasks.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/validation_status.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
- `docs/architecture/execution_profiles_surface_integration.md`

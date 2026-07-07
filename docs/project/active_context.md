# Active project context

Last reviewed: 2026-07-06
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Current main commit: b544b70e8df518db8bd7402aa9d3868a9e280a74

## Current development focus

The cross-model sweep unification work was merged into `main` through PR #107.
The next technical phase is a reproducible audit of mRLFE route consistency across:

- `LambFundamental_GUI`;
- `SweepTool_GUI`;
- `FitTool_GUI`;
- maintained mRLFE examples;
- solver and branch-selection policies.

The audit must establish current behavior before any solver-route change or
refactor is proposed. No implementation branch for the mRLFE audit has been
created yet.

## Recently completed capabilities

- Execution-profile infrastructure and diagnostics.
- End-to-end execution-profile integration across Main GUI, SweepTool, and FitTool.
- FitTool experimental data import and manual table editing.
- Persistent axis controls.
- Explicit requested fitted-curve solver evaluation.
- Separated parameter and fit-quality summaries.
- Persistent project context, session handoff, reusable task templates, and initial ADRs.
- Cross-model sweep figure unification through the maintained Alternative B architecture.
- Canonical maintained sweep entrypoint names across AE IOP/HGO, mRLFE, and Rayleigh-Lamb.
- Maintained AE physical-parameter sweeps for IOP, mu, thickness, k1, k2, radius, and mu-IOP.
- Deterministic and idempotent project-path configuration.

## Active architectural contracts

- GUI surfaces delegate to adapters and backends. See `docs/workflows/gui/adapter_architecture.md`.
- Model physics remains in model layers. See `docs/repository/repository_structure.md`.
- Fitting uses request -> dispatcher -> adapter -> maintained model API. See `docs/workflows/fitting/architecture.md`.
- `executionProfile` is distinct from route policy and optimizer options. See `docs/architecture/execution_profiles_surface_integration.md`.
- Maintained sweep plotting uses model-specific adapters and `plotSweepCpFigure` as the shared renderer.
- Naming follows `docs/repository/naming_strategy.md`.
- Use one feature branch per task, created from updated `origin/main`.
- Audit before modification; keep changes small and localized.
- Do not mix solver-physics changes with documentation, GUI-only, or plotting work.
- The user performs merges manually.

## Known cross-cutting limitations

- Execution-profile presentation is unified, but internal model execution structures are not fully unified.
- mRLFE maps non-Fast requests to validated Fast behavior on maintained GUI, SweepTool, and FitTool routes.
- Main GUI and SweepTool share `guiRunMRLFEModel`, while FitTool and maintained examples use separate evaluation paths.
- Maintained mRLFE examples currently use defaults that differ from the interactive surfaces, including `delayedCut` and a non-unified atlas default.
- Main GUI and SweepTool can apply a zero-viscosity adaptive fallback; FitTool records route quality but does not apply the same fallback policy.
- Sweep-level mRLFE metadata can summarize one route even when individual sweep points use different routes.
- Existing route and synthetic-contract tests do not constitute external physical validation.

## Planned development phases

This sequence is provisional:

1. Complete and merge the project-state documentation refresh.
2. Create a new branch from updated `origin/main` for the mRLFE route-consistency audit.
3. Build a reproducible comparison matrix across Main GUI, SweepTool, FitTool, and maintained examples.
4. Classify each difference as intentional, defective, or requiring physical validation.
5. Select one localized technical correction, define its scope, and validate it before opening a PR.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/validation_status.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/gui/mrlfe_atlas_policy_integration.md`
- `docs/workflows/fitting/architecture.md`
- `docs/workflows/sweeps/parametric_sweeps.md`
- `docs/models/mrlfe/README.md`
- `docs/models/mrlfe/fitting_workflow.md`
- `docs/models/mrlfe/atlas_policy_notes.md`
- `docs/architecture/execution_profiles_surface_integration.md`

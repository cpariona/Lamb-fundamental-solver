# Active project context

Last reviewed: 2026-07-10
Repository: cpariona/Lamb-fundamental-solver
Default branch: main
Current main commit: b544b70e8df518db8bd7402aa9d3868a9e280a74

## Current development focus

The mRLFE production architecture migration is complete on the validation branch
stack. Main GUI, SweepTool, and FitTool now use the public model API:

```text
Main GUI  -+
SweepTool -+-> mrlfeSolve
FitTool   -+
```

The active task is final validation and integration reporting before the user
manually merges the branch stack.

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
- Main GUI, SweepTool, and FitTool all reach `mrlfeSolve`; SweepTool no longer delegates solving through the Main GUI adapter.
- Maintained mRLFE production routes use `physicalTail` for A0Like, `none` for S0Like, and `fallback.policy = "none"`.
- Historical route audits describe pre-migration behavior and are not maintained entrypoint contracts.
- Existing route and synthetic-contract tests do not constitute external physical validation.

## Planned development phases

This sequence is provisional:

1. Complete final mRLFE architecture validation on `mrlfe-final-validation`.
2. User reviews and manually merges the mRLFE migration branch stack.
3. After merge, update `main` locally and run the maintained smoke/validation suite.

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

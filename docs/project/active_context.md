# Active project context

Last reviewed: 2026-07-14
Repository: cpariona/Lamb-fundamental-solver
Default branch: main

## Current development focus

The mRLFE production architecture migration has been merged into `main` through PR #109. Main GUI, SweepTool, and FitTool use the public model API:

```text
Main GUI  -+
SweepTool -+-> mrlfeSolve
FitTool   -+
```

The current focus is post-merge maintenance: keep documentation, tests, and consumer contracts aligned with the public solver architecture without reintroducing legacy atlas routes.

## Recently completed capabilities

- Public mRLFE API and production-core organization.
- Removal of legacy mRLFE atlas/direct-visco production routes.
- End-to-end execution-profile integration across Main GUI, SweepTool, and FitTool.
- Fast, Balanced, Robust, and dense/reference numerical presets.
- Direct SweepTool use of `mrlfeSolve` per sweep point.
- FitTool objective evaluations on a bounded fit-optimized internal grid.
- Fit-result normalization without automatic solver reevaluation.
- Explicit user-requested fitted-curve solver evaluation.
- Fit-versus-requested-curve consistency diagnostics.
- Separated parameter and fit-quality summaries.
- Deterministic and idempotent project-path configuration.

## Active architectural contracts

- GUI surfaces delegate to adapters and backends. See `docs/workflows/gui/adapter_architecture.md`.
- Model physics remains in model layers. See `docs/repository/repository_structure.md`.
- Fitting uses request -> dispatcher -> adapter -> maintained model API. See `docs/workflows/fitting/architecture.md`.
- `executionProfile` is distinct from route policy and optimizer options.
- Main GUI, SweepTool, and FitTool resolve Fast, Balanced, or Robust into the corresponding public mRLFE numerical preset.
- A0Like uses `physicalTail`; S0Like uses `none`; fallback remains disabled.
- FitTool optimization uses `gridPolicy = "fitOptimized"`.
- A complete fitted curve is evaluated only after the explicit **Evaluate fitted curve** action and uses `gridPolicy = "numericalPreset"`.
- The user performs merges manually unless explicitly requesting another workflow.

## Validation status

The following groups passed before PR #109 was merged:

- mRLFE public-solver FitTool migration tests;
- execution-profile surface tests;
- GUI smoke tests;
- lightweight fit-grid performance characterization;
- full grid validation;
- targeted validation of the marginal full-matrix cases.

The fit-optimized grid produced approximately 3.0x to 4.3x speedup against the Fast preset grid in the tested cases, with a worst relative phase-speed difference of 0.121% and no valid-mask differences.

The extended grid matrix found aggregate failures only where the dense reference was itself marginal (`low_valid_fraction` or `large_relative_jump`). Targeted follow-up found no accepted reference solution that degraded under the candidate grids.

## Known limitations

- Existing synthetic and route-contract tests are not external physical validation.
- Grid-quality classifications near marginal branch tails can depend on the internal grid.
- Dense full-matrix validation is expensive and should not be repeated unless solver or grid-policy changes affect the relevant cases.
- Historical route audits may mention removed mRLFE atlas names as pre-migration evidence; those names are not maintained production contracts.

## Next development guidance

1. Start new code work from updated `main` on a dedicated feature branch.
2. Keep documentation-only corrections separate from solver behavior changes.
3. Run focused contract tests before broad smoke suites.
4. Use targeted grid diagnostics before considering another extended matrix.
5. Do not rename maintained files or runners without first checking repository naming and cleanup-contract tests.

## Primary references

- `docs/project/README.md`
- `docs/project/session_handoff.md`
- `docs/repository/repository_structure.md`
- `docs/repository/naming_strategy.md`
- `docs/repository/validation_status.md`
- `docs/workflows/gui/adapter_architecture.md`
- `docs/workflows/fitting/architecture.md`
- `docs/workflows/sweeps/parametric_sweeps.md`
- `docs/models/mrlfe/README.md`
- `docs/models/mrlfe/public_api.md`
- `docs/models/mrlfe/production_core.md`
- `docs/models/mrlfe/fitting_workflow.md`
- `docs/validation/mrlfe_grid_presets.md`

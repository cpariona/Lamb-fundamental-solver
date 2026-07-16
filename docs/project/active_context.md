# Active project context

Last reviewed: 2026-07-16
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Last merged AE architecture change: PR #122, commit
`9c862bd7e217defc9a580bb0a41ea9fd5cd0e8bb`

## Current architecture

The maintained source layers are `models/`, `analysis/`, `app/`, and
`examples/`, with dependency direction defined by
`docs/repository/repository_structure.md`. Public and maintained MATLAB
surfaces are inventoried in `docs/repository/maintained_entrypoints.md`.

Repository naming is owned by `docs/repository/naming_strategy.md`. Test layout
and ownership are owned by the two test contracts under `docs/repository/`.
Repository-wide static hygiene is checked by:

```matlab
run_repository_hygiene_tests
```

## Current product state

- Rayleigh-Lamb, mRLFE, and AE IOP/HGO use their maintained public model APIs.
- Main GUI, SweepTool, and FitTool route through app adapters.
- mRLFE production consumers route through `mrlfeSolve`.
- AE production output remains the conservative `atlasA0` branch.
- AE request validation, effective configuration, numerical presets, and
  internal tracking-grid construction now have canonical model-layer owners.
- Current fitting and sweep behavior is documented under `docs/workflows/`.
- Repository structure, naming, documentation ownership, and test ownership
  were consolidated and guarded by PR #119.
- Main GUI, SweepTool, and FitTool were manually reviewed after that cleanup;
  no broken route was observed.

## Current technical constraints

- Preserve solver physics, numerical presets, grids, policies, and tolerances.
- Preserve fitting, sweep, and GUI behavior unless a focused task authorizes change.
- Use Git history for completed migrations, audits, and task reports.
- Do not add compatibility aliases without an explicit public-use contract and removal condition.
- Start each implementation task from an updated `origin/main` on a new branch.
- Do not open a PR until focused validation and manual review are complete.

## Current objective

Phase 2 centralizes AE configuration ownership on
`refactor/ae-configuration-ownership`. It preserves flat public signatures and
numerical behavior while migrating model wrappers, physical workflows, Main
GUI, SweepTool, and FitTool to `aeResolveConfiguration`,
`aeGetNumericalPreset`, `aeValidateRequest`, and
`aeBuildInternalTrackingGrid`.

Phase 3 is not authorized. After Phase 2 review and manual merge, the next
candidate is the bounded result/quality/diagnostic boundary described by the
AE architecture audit.

## Open technical areas

1. **AE architecture alignment** - Phase 2 configuration ownership is complete
   on its review branch; later result/quality and tracking/policy phases require
   separate approval and branches.
2. **AE solver refinement** — residual high-frequency waviness in `Cp(f)` is
   documented in
   `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`.
   This numerical issue is separate from the architecture audit and must not be
   modified during it.
3. **mRLFE runtime characterization** — a manual post-cleanup review suggested
   that mRLFE may feel slower, but static comparison found no change to presets,
   frequency-grid construction, scan-point counts, candidates, adaptive windows,
   profile mapping, or maintained solver/tracking code. A controlled benchmark
   is required before treating this as a regression.
4. **Bounded compatibility debt** — retained aliases and wrappers, their owners,
   consumers, and removal conditions are listed in
   `docs/repository/validation_status.md`.

No work beyond Phase 2 is currently authorized.

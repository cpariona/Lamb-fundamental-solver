# Active project context

Last reviewed: 2026-07-16
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Last merged repository-wide change: PR #119, merge commit
`749feb159795f7fe0e0a4eecaecf8696b4369dad`

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

## Open technical areas

1. **AE solver refinement** — residual high-frequency waviness in `Cp(f)` is
   documented in
   `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`.
   Any change must be solver-side, diagnostic-backed, and must not rely on
   display-only smoothing.
2. **mRLFE runtime characterization** — a manual post-cleanup review suggested
   that mRLFE may feel slower, but static comparison found no change to presets,
   frequency-grid construction, scan-point counts, candidates, adaptive windows,
   profile mapping, or maintained solver/tracking code. A controlled benchmark
   is required before treating this as a regression.
3. **Bounded compatibility debt** — retained aliases and wrappers, their owners,
   consumers, and removal conditions are listed in
   `docs/repository/validation_status.md`.

No implementation objective or provisional phase is currently active.

# Active project context

Last reviewed: 2026-07-15
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`

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

## Product state

- Rayleigh-Lamb, mRLFE, and AE IOP/HGO use their maintained public model APIs.
- Main GUI, SweepTool, and FitTool route through app adapters.
- mRLFE production consumers route through `mrlfeSolve`.
- AE production output remains the conservative `atlasA0` branch.
- Current fitting and sweep behavior is documented under `docs/workflows/`.

## Constraints

- Preserve solver physics, numerical presets, grids, policies, and tolerances.
- Preserve fitting, sweep, and GUI behavior unless a focused task authorizes change.
- Use Git history for completed migrations, audits, and task reports.
- Do not add compatibility aliases without an explicit public-use contract and removal condition.

Known compatibility debt is bounded in
`docs/repository/validation_status.md`.

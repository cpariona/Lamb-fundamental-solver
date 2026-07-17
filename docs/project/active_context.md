# Active project context

Last reviewed: 2026-07-17
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Last merged AE architecture change: PR #126, commit
`816e74e2190a159063838517c39e2c98c60674a3`

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
- AE production consumers route through `solveAcoustoelasticIOPHGOBranch`.
- AE production output remains the conservative `atlasA0` branch.
- AE configuration, atlas construction, production tracking, policies, quality,
  result construction, workflows, and app adapters have canonical owners.
- The AE architecture alignment is complete. Its final contract is
  `docs/models/acoustoelastic_iop_hgo/active/architecture.md`.
- Current fitting and sweep behavior is documented under `docs/workflows/`.

## Current technical constraints

- Preserve solver physics, numerical presets, grids, policies, and tolerances.
- Preserve fitting, sweep, GUI, output, and result-schema behavior unless a
  focused task authorizes change.
- Use Git history for completed migrations, audits, and task reports.
- Do not add compatibility aliases without an explicit public-use contract and
  removal condition.
- Start each implementation task from updated `origin/main` on a new branch.
- Do not open a PR until focused validation and manual review are complete.

## Current objective

The AE architecture migration is closed. New work must be selected as an
independent technical task and preserve the final ownership contract.

## Open technical areas

1. **AE solver refinement** — residual high-frequency waviness in `Cp(f)` is
   documented in
   `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`.
   This is numerical work, not architecture cleanup.
2. **mRLFE runtime characterization** — a controlled benchmark is required
   before treating perceived runtime changes as a regression.
3. **Bounded compatibility debt** — retained aliases, wrappers, and
   canonical-first legacy reads are listed in
   `docs/repository/validation_status.md`.

Architecture finalization does not authorize numerical AE refinement.

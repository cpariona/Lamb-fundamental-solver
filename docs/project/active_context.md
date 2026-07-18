# Active project context

Last reviewed: 2026-07-18
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Last merged architecture change: PR #127, merge commit
`13b00c4e6142988c0ac0d3e3b4c0fc76ddfae586`

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
- Prefer deletion or direct moves over new wrappers and path exceptions.
- Do not reorganize small model families merely for visual symmetry.

## Current repository state

The bounded repository simplification is complete. Its maintained final state is
defined in `docs/repository/repository_simplification.md`:

1. AE analysis is owned by `diagnostics/`, `fitting/`, `io/`, and `sweeps/`;
2. identity-A0 model algorithms live under explicit diagnostic ownership;
3. `tests/fitting/` is absent;
4. five delegation-only public test wrappers remain;
5. specialized commands resolve from `tests/runners/`;
6. runtime measurements are ignored local evidence under `Results/test_runtime/`;
7. deterministic inventories contain ownership and graph evidence only.

Local ignored `Results/` workspaces and example figures are generated user
outputs and remain outside source ownership.

## Open technical areas

1. **AE solver refinement** — residual high-frequency waviness in `Cp(f)` is
   documented in
   `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`.
   This is numerical work, not repository cleanup.
2. **mRLFE runtime characterization** — controlled measurements may be generated
   locally, but environment-dependent measurements are not canonical inventory.
3. **Bounded compatibility debt** — retained aliases and canonical-first legacy
   reads remain governed by `docs/repository/validation_status.md`.

Repository simplification does not authorize numerical solver refinement.

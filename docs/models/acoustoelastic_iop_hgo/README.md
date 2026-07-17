# Acoustoelastic IOP/HGO model

This is the entrypoint for the maintained AE IOP/HGO API, workflows, branch
policy, and repeatable diagnostic evidence.

## Current status

The current official production policy is:

```text
atlasA0 = conservative official output
```

The official solver output remains:

```matlab
result.Cp
result.validCp
```

The following branches and diagnostics are not production outputs:

```text
identityA0Diagnostic
raw_branch1
branch_families
```

The authoritative API and branch-policy contracts are
[`active/public_api.md`](active/public_api.md) and
[`active/branch_policy.md`](active/branch_policy.md).

Effective numerical configuration is model-owned by
`aeResolveConfiguration`. Fast/Balanced/Robust and the separate Main GUI
bundle are owned by `aeGetNumericalPreset`; app and analysis layers only
select the applicable profile or surface and supply explicit overrides.

Atlas result construction is model-owned by `aeBuildResult`, and requested-grid
quality/reliability is owned by `aeEvaluateAtlasA0Quality`. The stable summary
remains `result.diagnostics`; existing atlas evidence remains at its
characterized top-level fields as a compatibility surface. No new
`result.debug` nesting was introduced because that would change the public
schema.

Production atlas construction, minima detection, branch linking/splitting,
official selection, and fallback rejection are model-owned respectively by
`aeBuildAtlas`, `aeFindAtlasLocalMinima`, `aeLinkAtlasBranches`,
`aeSplitAtlasBranches`, `aeSelectAtlasA0Branch`, and
`aeApplyAtlasA0FallbackPolicy`. These are internal ownership boundaries; the
public solver entrypoints and exact `atlasA0` behavior are unchanged.

## Recommended user-facing commands

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup
```

Basic execution:

```matlab
run_atlas_branch
```

Sweeps:

```matlab
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
```

Maintained diagnostics:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
diagnose_modal_atlas
validate_idA0_score_grid
validate_idA0_grid
```

Focused smoke runner:

```matlab
run_acoustoelastic_smoke_tests
```

## Current documentation

| Document | Purpose |
|---|---|
| `active/public_api.md` | Public API list. |
| `active/branch_policy.md` | Branch policy summary and official atlas-A0 selection rule. |
| `active/sweep_workflow.md` | Sweep workflow documentation. |
| `active/fitting_workflow.md` | Fitting workflow documentation. |
| `active/solver_pending_work.md` | Pending solver-side numerical work. |
| `active/architecture.md` | Final production routes, responsibility ownership, advanced APIs, diagnostic separation, and bounded compatibility debt. |
| `diagnostics/README.md` | Inventory and purpose of repeatable diagnostics. |

## Structure convention

Use this structure for new work:

```text
analysis/acoustoelastic_iop_hgo/              reusable helpers
models/acoustoelastic_iop_hgo/                model and solver implementation
examples/acoustoelastic_iop_hgo/basic/        simple executable examples
examples/acoustoelastic_iop_hgo/sweeps/       sweep entrypoints
examples/acoustoelastic_iop_hgo/diagnostics/  diagnostics and validations
tests/models/acoustoelastic_iop_hgo/          model tests
tests/app/                                    app-layer integration tests
docs/models/acoustoelastic_iop_hgo/active/      API, policy, and workflows
docs/models/acoustoelastic_iop_hgo/diagnostics/ repeatable scientific evidence
Results/ae_iop_hgo/<task>                     generated outputs
```

New generated outputs use `Results/ae_iop_hgo/<task>`. `aeOutputFolder` owns
that convention. `aeResolveResultFile` may read the explicitly documented
legacy result locations required by maintained diagnostics; it does not define
a second output convention.

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

## Selected next objective

After the current mRLFE compatibility-consumer migration is merged, the next
selected task is an **AE IOP/HGO architecture audit and alignment plan**.

The task is analytical and documentation-first. It must:

- inventory the maintained AE executable surface across model, analysis, app,
  examples, tests, and documentation;
- reconstruct the Main GUI, SweepTool, FitTool, basic-example, sweep, and
  diagnostic call paths;
- classify each maintained AE file by responsibility and public/internal status;
- compare those responsibilities with the established mRLFE organization;
- identify safe structural alignment opportunities without forcing identical
  physics-specific APIs;
- produce a phased migration plan with risks, dependencies, and validation
  requirements.

The audit must not move or rename files, create aliases, change result schemas,
or alter physics, presets, grids, policies, tolerances, fitting, sweeps, or GUI
behavior. No AE implementation phase is authorized by this objective.

## Open technical areas

1. **AE architecture alignment audit** — selected next planning task. The audit
   should determine whether configuration, presets, tracking, policies, quality,
   and result construction can be assigned clearer model-layer ownership similar
   to mRLFE while preserving AE-specific scientific APIs and diagnostics.
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

No AE implementation phase is currently active.
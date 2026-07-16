# Session handoff

Updated: 2026-07-16

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Phase 2 base: `9c862bd7e217defc9a580bb0a41ea9fd5cd0e8bb`
- Current branch: `refactor/ae-configuration-ownership`
- Current task: AE architecture alignment Phase 2
- Merge status: pending repository-owner review; do not open a PR or merge
- Next phase: not authorized

## Implemented ownership

Phase 2 establishes these canonical model-layer owners:

```text
aeValidateRequest             maintained flat-request checks
aeResolveConfiguration        complete effective options and precedence
aeGetNumericalPreset          Fast/Balanced/Robust and Main GUI bundle
aeBuildInternalTrackingGrid   unchanged requested/internal grid algorithm
```

Public signatures remain:

```matlab
solveAcoustoelasticIOPHGOBranch(params, options)
solveAcoustoelasticIOPHGOAtlasBranch(params, options)
defaultAcoustoelasticIOPHGOOptions()
```

The model owns solver numerical values. Analysis retains physical campaigns,
fitting bounds, optimizer configuration, plotting, and output writing. App
code retains UI state, units, profile/surface selection, orchestration, and
result formatting.

## Preserved contracts

- Fast/Balanced/Robust atlas presets remain `300/12`, `600/16`, and `900/20`.
- The separate Main GUI bundle remains `420/8`, refinement off, 25
  initialization points, predictive continuation, global-scan fallback,
  window `0.22`, and weights `8.0/4.0`.
- Explicit caller options retain established precedence.
- Requested and internal grids retain sorting, uniqueness, lower-frequency,
  and projection behavior.
- Physics, constitutive equations, objectives, tracking, `atlasA0`, fallback,
  reliability, fitting, sweeps, GUI presentation, and result schemas are not
  changed.

## Review boundary

Read the implemented-state contract in
`docs/models/acoustoelastic_iop_hgo/active/architecture_audit.md` and the
public/configuration inventory in
`docs/models/acoustoelastic_iop_hgo/active/public_api.md`.

Do not begin Phase 3 from this branch. After repository-owner review and manual
merge, create the separately approved branch from updated `origin/main`.

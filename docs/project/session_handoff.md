# Session handoff

Updated: 2026-07-16

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Phase 5 base: `9eabe110d586fe78cbf9692806b8f26233249bcf`
- Current branch: `refactor/ae-workflow-adapter-alignment`
- Current task: AE architecture alignment Phase 5
- Merge status: pending repository-owner review; do not open a PR or merge
- Next phase: not authorized

## Implemented ownership

Phases 2-4 establish canonical configuration, result/quality, tracking, and
policy owners. Phase 5 aligns production consumers:

```text
aeValidateRequest             maintained flat-request checks
aeResolveConfiguration        complete effective options and precedence
aeGetNumericalPreset          Fast/Balanced/Robust and Main GUI bundle
aeBuildInternalTrackingGrid   unchanged requested/internal grid algorithm
aeEvaluateAtlasA0Quality      requested-grid quality/reliability summary
aeBuildResult                 characterized atlas result schema
aeFindAtlasLocalMinima        production atlas minima
aeLinkAtlasBranches           production branch linking
aeSplitAtlasBranches          production branch splitting
aeSelectAtlasA0Branch         official atlasA0 selection
aeApplyAtlasA0FallbackPolicy  fallback invalidation decision
```

Maintained production routes now use:

```text
Main GUI -> guiRunAcoustoelasticIOPHGOModel
         -> solveAcoustoelasticIOPHGOBranch
SweepTool -> guiRunAcoustoelasticIOPHGOSweep
          -> aeRunSweep -> solveAcoustoelasticIOPHGOBranch per point
FitTool -> guiFitAcoustoelasticIOPHGOSolver
        -> aeFitDispersionData -> aeEvaluateFitModel
        -> solveAcoustoelasticIOPHGOBranch
basic example -> solveAcoustoelasticIOPHGOBranch
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
  fitting, sweeps, GUI presentation, and result schemas are not changed.
- Full direct/IOP/public/internal/identity/fallback outputs compare exactly
  equal to the pre-refactor commit with `isequaln`.
- `result.diagnostics` remains the stable summary. Existing internal evidence
  remains at characterized top-level fields; no new `result.debug` field was
  added.
- Identity-A0 remains diagnostic-only and does not alter official output.

## Review boundary

Read the implemented-state contract in
`docs/models/acoustoelastic_iop_hgo/active/architecture_audit.md` and the
public/configuration inventory in
`docs/models/acoustoelastic_iop_hgo/active/public_api.md`.

Do not begin Phase 6 from this branch. After repository-owner review and manual
merge, create the separately approved finalization branch from updated
`origin/main`.

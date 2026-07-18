# Session handoff

Updated: 2026-07-18

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Last merged architecture change: PR #127, merge commit
  `13b00c4e6142988c0ac0d3e3b4c0fc76ddfae586`
- AE architecture status: complete
- AE final contract:
  `docs/models/acoustoelastic_iop_hgo/active/architecture.md`
- Repository-simplification final-state contract:
  `docs/repository/repository_simplification.md`

The multi-phase AE architecture alignment and the bounded repository
simplification are closed. Do not reopen migration phases or create a Phase 7.
New work must start from updated `origin/main` on a separate branch.

## Stable production ownership

```text
aeValidateRequest             maintained flat-request checks
aeResolveConfiguration        complete effective options and precedence
aeGetNumericalPreset          numerical presets and Main GUI bundle
aeBuildInternalTrackingGrid   requested/internal grid algorithm
aeBuildAtlas                  configured atlas and objective landscape
aeFindAtlasLocalMinima        production atlas minima
aeLinkAtlasBranches           production branch linking
aeSplitAtlasBranches          production branch splitting
aeSelectAtlasA0Branch         official atlasA0 selection
aeApplyAtlasA0FallbackPolicy  fallback invalidation decision
aeEvaluateAtlasA0Quality      requested-grid quality/reliability
aeBuildResult                 characterized atlas result schema
```

Maintained production routes use:

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

The longer solver entrypoints remain advanced supported scientific APIs.
Production consumers do not call tracking or policy internals.

## Implemented repository simplification

- `analysis/acoustoelastic_iop_hgo/` is organized into `diagnostics/`,
  `fitting/`, `io/`, and `sweeps/`.
- Identity-A0 model diagnostics are owned by
  `models/acoustoelastic_iop_hgo/diagnostics/`.
- `models/acoustoelastic_iop_hgo/results/` owns result construction only.
- `tests/fitting/` and its structural exception are absent.
- Five public wrappers remain; specialized commands resolve from canonical
  implementations under `tests/runners/`.
- Runtime measurement output is local ignored evidence under
  `Results/test_runtime/` and is not imported into deterministic inventories.
- Rayleigh-Lamb and mRLFE analysis remain flat based on their small cohesive
  call graphs.

The final structure and enforcement rules are recorded in
`docs/repository/repository_simplification.md`,
`docs/repository/repository_structure.md`, and the test-runner contracts.

## Preserved contracts

- Official AE production output remains conservative `atlasA0`.
- Physics, constitutive equations, matrices, roots, objectives, presets, grids,
  thresholds, tracking, policy, fitting, sweeps, GUI behavior, and result
  schemas must remain unchanged.
- Fast/Balanced/Robust and the separate Main GUI numerical bundle retain their
  characterized values and precedence.
- `result.diagnostics` remains the stable summary; characterized internal
  evidence remains in place for schema compatibility.
- Identity-A0, raw branch 1, modal atlases, and branch families remain
  diagnostic-only.
- `aeResolveResultFile` retains canonical-first legacy read fallback unless a
  separate task proves all external and scientific workspace consumers migrated.
- Local ignored `Results/` workspaces and example figures are outside the
  simplification task.

## Work remaining after repository simplification

1. AE high-frequency `Cp(f)` numerical refinement, governed by
   `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`.
2. Controlled mRLFE runtime characterization using locally generated evidence.
3. Explicitly authorized compatibility-debt retirement after complete consumer
   and fixture evidence.

None of these is part of the repository simplification task.

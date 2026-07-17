# Session handoff

Updated: 2026-07-17

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Last merged AE architecture base: `816e74e2190a159063838517c39e2c98c60674a3`
- Architecture status: complete
- Final contract:
  `docs/models/acoustoelastic_iop_hgo/active/architecture.md`

The multi-phase AE architecture alignment is closed. Do not reopen migration
phases or create a Phase 7. Future tasks must start from updated `origin/main`
on a separate branch.

## Final ownership

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

## Preserved contracts

- Official production output remains conservative `atlasA0`.
- Physics, constitutive equations, matrices, roots, objectives, presets, grids,
  thresholds, tracking, policy, fitting, sweeps, GUI behavior, and result
  schemas are unchanged by architecture finalization.
- Fast/Balanced/Robust and the separate Main GUI numerical bundle retain their
  characterized values and precedence.
- `result.diagnostics` remains the stable summary; characterized internal
  evidence remains in place for schema compatibility.
- Identity-A0, raw branch 1, modal atlases, and branch families remain
  diagnostic-only.
- `aeResolveResultFile` retains canonical-first legacy read fallback as bounded
  compatibility debt until scientific workspaces and external inputs are
  proven migrated.

## Next independent technical areas

1. AE high-frequency `Cp(f)` numerical refinement, governed by
   `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md`.
2. mRLFE controlled runtime characterization.
3. Explicitly authorized, bounded compatibility-debt retirement after complete
   consumer and fixture evidence.

None of these is part of the completed architecture migration.

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
- Active repository-maintenance contract:
  `docs/repository/simplification_plan.md`

The multi-phase AE architecture alignment is closed. Do not reopen migration
phases or create a Phase 7. The next task is an independent repository
simplification effort and must start from updated `origin/main` on a separate
branch.

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

## Approved repository simplification

The next task must implement the decisions in
`docs/repository/simplification_plan.md`:

1. characterize and reorganize `analysis/acoustoelastic_iop_hgo/` by fitting,
   sweeps, diagnostics, and justified IO/output ownership;
2. move `aeBuildIdentityA0DiagnosticBranch` and
   `aeScoreBranchIdentityCandidates` to
   `models/acoustoelastic_iop_hgo/diagnostics/` without algorithm changes;
3. remove `tests/fitting/run_fit_validation_tests.m` and its structural
   exception;
4. characterize the nine root-level test wrappers and retain only a minimal,
   explicitly public convenience surface;
5. keep `measureTestRuntime.m`, but move generated runtime measurements to an
   ignored `Results/test_runtime/` location and remove the tracked runtime CSV;
6. update entrypoint, structure, validation, runner-ownership, test, project,
   and inventory documentation.

Use direct moves and caller migration. Do not create forwarding wrappers, path
aliases, empty directories, or new exceptions.

Rayleigh-Lamb should remain flat unless real dependency evidence justifies added
structure. mRLFE must be audited for similar analysis-layer mixing, but should be
subdivided only when the resulting structure is simpler than the current one.

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

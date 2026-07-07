# Session handoff

Updated: 2026-07-06
Repository: cpariona/Lamb-fundamental-solver
Current branch: docs-refresh-project-state-after-pr107
Base branch: main
Base commit: b544b70e8df518db8bd7402aa9d3868a9e280a74

## Current task

Refresh the operational project-state documents after the merge of PR #107.
This branch is documentation-only and must not change solver, GUI, sweep, fitting,
or branch-selection behavior.

## Current repository state

- PR #107, `Add and unify maintained physical-parameter sweeps`, is merged into `main`.
- The maintained sweep plotting architecture is Alternative B:
  - AE: `aeRunSweep` -> `aeBuildSweepPlotData` -> `plotSweepCpFigure`.
  - mRLFE/Rayleigh-Lamb: `runParametricSweep` -> `buildParametricSweepPlotData` -> `plotSweepCpFigure`.
- Maintained sweep entrypoints use the canonical `<model>_sweep_<parameter>_<branch>` naming convention.
- Old maintained sweep aliases were removed without compatibility wrappers.
- `startup` delegates to deterministic, idempotent project-path configuration.
- The complete maintained smoke suite passed during PR #107 validation.

## Active next technical task

Perform a reproducible mRLFE route-consistency audit before proposing changes.
The audit must compare:

- Main GUI;
- SweepTool;
- FitTool;
- maintained examples;
- execution-profile mapping;
- solver routes;
- A0 branch-selection policies;
- fallback and route metadata.

The first audit should cover at least A0Like and S0Like, zero and nonzero `etaS`,
and the `adaptivePhysicalTail` and `delayedCut` policies where applicable.

## Confirmed open issues

- Main GUI and SweepTool route through `guiRunMRLFEModel`; FitTool and maintained examples use separate evaluation paths.
- Maintained examples default to `delayedCut` and `UseUnifiedAtlasRoute = false`, unlike the interactive surfaces.
- Main GUI and SweepTool can fall back from a zero-viscosity adaptive atlas result to an elastic reference result; FitTool does not apply the same fallback.
- Main GUI, SweepTool, and FitTool preserve Fast internal mRLFE presets even when Balanced or Robust is requested.
- Sweep-level route metadata may not represent every point in a mixed-route sweep.
- Current tests validate routing and synthetic contracts, not external physical correctness.

## Next action

1. Review and merge this documentation-only branch manually.
2. Update local `main` from `origin/main` after the merge.
3. Create a new branch dedicated to the mRLFE route-consistency audit.
4. Add comparison evidence and tests before selecting any corrective implementation.

## Do not change in this branch

- Numerical solver behavior.
- mRLFE branch-selection or fallback policies.
- Main GUI, SweepTool, or FitTool behavior.
- Execution-profile mapping.
- Maintained examples or sweep defaults.
- Public API names, folder structure, or naming contracts.
- Do not open a pull request unless explicitly requested.
- Do not merge this branch; the user performs merges manually.

## Relevant files for the next task

- `app/adapters/guiRunMRLFEModel.m`
- `app/adapters/guiRunMRLFESweep.m`
- `app/adapters/guiFitMRLFESolver.m`
- `analysis/mrlfe/mrlfeEvaluateFitModel.m`
- `analysis/mrlfe/mrlfeEvaluateAtlasFitModel.m`
- `analysis/mrlfe/mrlfeDefaultSweepOptions.m`
- `analysis/mrlfe/mrlfeRunSweepExample.m`
- `analysis/runParametricSweep.m`
- `models/mrlfe/`
- `examples/mrlfe/`
- `tests/models/mrlfe/`
- `tests/app/gui/`
- `tests/app/fitting/`
- `tests/app/sweeps/`
- `docs/models/mrlfe/README.md`
- `docs/models/mrlfe/fitting_workflow.md`
- `docs/models/mrlfe/atlas_policy_notes.md`
- `docs/workflows/gui/mrlfe_atlas_policy_integration.md`
- `docs/architecture/execution_profiles_surface_integration.md`

## Commands to resume after this branch is merged

```bash
git fetch origin
git switch main
git pull --ff-only origin main
git status -sb
git log --oneline --decorate -10
```

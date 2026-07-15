# mRLFE architecture and repository cleanup closeout

Last reviewed: 2026-07-15
Branch: `refactor/mrlfe-line-and-repository-cleanup`
Audit head: `2cfe264625ab3f7485a06389d315190fe9a7b67e`

## Implemented architecture

- `mrlfeSolve` remains the only maintained public physical solver.
- `mrlfeBuildPublicSolveRequest` owns generic branch/frequency/scalar
  validation, aliases, physical mappings, preset selection, and solver policy.
- GUI, SweepTool, and FitTool request builders are thin surface translators.
- `guiBuildMRLFECompatibilityResult` is the single app-owned legacy-shape
  adapter, and `mrlfeBuildSurfaceExecutionMetadata` merges surface-owned facts
  with solver-owned execution facts.
- Maintained code reads stable public fields or `debug.rawInternalResult` at an
  explicit compatibility boundary. `diagnostics.rawInternalResult` remains a
  compatibility alias only.
- mRLFE owns its narrow internal configuration. Rayleigh-Lamb remains the
  intentional physical seed provider.

## Quantitative result

The audit baseline was 583 tracked files and 63,270 physical lines. The final
generated composition inventory records 528 tracked files and 53,235 physical
lines: reductions of 55 files (9.43%) and 10,035 lines (15.86%). The audit
forecast was approximately 59 files and 10,100 lines; the final differences
are four fewer removed files and 65 fewer removed lines than forecast.

Final composition is 230 main-line files / 23,088 lines (43.31% of lines),
274 supporting files / 26,028 lines (48.89%), and 24 historical/secondary
files / 4,119 lines (7.73%).

The three request wrappers fell from 448 physical lines to 237. The generic
duplication matrix fell from 11 duplicated responsibilities to zero; the three
surface-specific responsibilities remain local. Adapter measurements:

| Adapter | Before | After | Raw accesses before/after |
| --- | ---: | ---: | ---: |
| Main GUI | 190 | 130 | 2 / 0 |
| SweepTool | 250 | 159 | 2 / 0 |
| FitTool | 164 | 108 | compatibility accesses normalized |

## Deletion and retention decisions

The verified orphan `solveMRLFEBranch` and obsolete route-audit launcher were
deleted. Fifty-six Markdown files were deleted or consolidated into current
contracts. Five exploratory diagnostics were moved under the startup-excluded
diagnostic archive, three fitting diagnostics were consolidated into
`diagnose_mrlfe_fit_performance`, and three obsolete diagnostics were deleted.

Two preliminary audit deletions were rejected after stronger maintained-surface
evidence: `compareMRLFETrackingStrategies` and
`diagnose_mrlfe_atlas_primary_policy_matrix` remain because active tests and the
maintained-entrypoint contract still own them. No maintained public command was
removed.

## Validation result

Characterization fixtures reported zero phase-velocity difference and zero
valid-mask difference across representative Main GUI, SweepTool, and FitTool
cases. Public contracts, production core, fitting, execution-profile, smoke,
numerical-regression, startup-path, inventory, and static link/path checks were
run without relaxing tolerances. The consolidated fit diagnostic reported
zero cached/uncached Cp RMSE.

No solver equation, constitutive behavior, root search, branch tracking,
numerical preset, grid policy, quality threshold, physical default, fallback,
termination policy, execution-profile mapping, or visible surface default was
changed.

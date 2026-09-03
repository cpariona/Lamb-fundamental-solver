# Active project context

Last reviewed: 2026-09-02
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Planning branch: `planning/full-repository-restructure`
Active implementation branch: `restructure/phase-05-physical-architecture`
Starting main checkpoint:
`026994f86a2d1dfe5a740034d7a5fd81d4f08235`

## Current product state

- Rayleigh-Lamb, mRLFE, and AE IOP/HGO have maintained scientific APIs.
- Canonical public APIs are intentionally small: four for RL, three for mRLFE,
  and two for AE.
- Main GUI, SweepTool, and FitTool are the principal human-facing surfaces.
- mRLFE production consumers route through `mrlfeSolve`.
- Phase 1 establishes a one-way model dependency: `mrlfeBuildSeed` may call the
  RL public solver to obtain a seed; RL contains no mRLFE flags or execution.
- AE production consumers route through the maintained AE public route and
  conservative `atlasA0` policy.
- AE app surfaces translate Fast/Balanced/Robust requests in
  `aeResolveExecutionProfile`; model configuration does not know Main GUI,
  FitTool, or SweepTool.
- The AE high-frequency refinement issue is resolved in `main`: production now
  uses discrete atlas candidates followed by bounded continuous refinement of
  the selected branch on the true SVD objective.
- The former three-point parabolic sub-grid candidate refinement is no longer a
  production strategy.
- The last confirmed AE smoke and extended suites passed, including synthetic
  recovery of `mu = 50 kPa` with relative error `5.06201e-08`.

## Active repository objective

The next campaign is a full repository restructuring. The existing physical
layout is not protected merely because it is current.

The required qualities are:

```text
order
structure
organization
versatility
adaptability
human comprehension
simplicity
scientific correctness
controlled performance
```

Broad moves, renames, merges, splits, deletions, API cleanup, ownership changes,
test reorganization, and documentation cleanup are authorized when they improve
the final maintained architecture.

Temporary breakage on implementation branches is acceptable. The final state
must restore intended maintained functionality and pass the approved scientific,
contract, GUI, and integration gates.

## Governing planning contracts

The full campaign is defined by:

```text
docs/project/full_repository_restructure_handoff.md
docs/repository/maintainability_policy.md
docs/repository/refactor_policy.md
docs/repository/human_interface_contract.md
docs/repository/restructure_target_architecture.md
```

These documents supersede the assumption that repository changes must remain a
bounded cosmetic simplification. Previous final-state documents remain useful
as historical/current-state evidence but do not constrain the new target
architecture.

## Core architectural rules for the next campaign

- one canonical owner per responsibility;
- reuse before creation;
- replace obsolete strategies instead of stacking old/new implementations;
- GUI coordinates and presents; models calculate;
- Main GUI, FitTool, SweepTool, examples, and scripts should converge on
  canonical model APIs;
- limit conceptual call depth and forwarding-only helpers;
- extract by responsibility, not line count;
- keep physical, numerical, execution-profile, and UI configuration concepts
  distinct;
- keep official results, diagnostics, quality, and effective configuration
  explicit;
- production must not depend on examples or exploratory diagnostics;
- new investigation-only MATLAB files use `% TEMPORARY_DIAGNOSTIC` and are
  removed before final integration unless intentionally promoted;
- tests protect the final maintained architecture, not obsolete migration
  behavior;
- numerical baselines are not updated merely to make structural refactors pass;
- performance is characterized for meaningful algorithmic changes.

## Current phase

Phase 5 preserves the canonical APIs and workflows from Phases 1-4 while making
their physical ownership explicit. `analysis/` is organized by scientific
workflow:

```text
analysis/fitting/{shared,rayleigh_lamb,mrlfe,acoustoelastic_iop_hgo}
analysis/sweeps/{shared,rayleigh_lamb,mrlfe,acoustoelastic_iop_hgo}
analysis/diagnostics/{mrlfe,acoustoelastic_iop_hgo}
analysis/plotting/sweeps/{shared,acoustoelastic_iop_hgo}
analysis/io/{shared,rayleigh_lamb,mrlfe,acoustoelastic_iop_hgo}
analysis/requests/mrlfe
```

`app/` is surface-first: its root contains only `LambFundamental_GUI`,
`FitTool_GUI`, and `SweepTool_GUI`; implementation lives in `main/`, `fitting/`,
and `sweep/`, with only cross-surface execution-profile and struct/result
translation in `shared/`. The former mixed `app/adapters/` folder is absent.

The declarative UI tables are named `guiGetFitModelConfiguration` and
`guiGetSweepModelConfiguration`; their historical `Registry` names were removed
without aliases. No solver equations, tracking policies, optimizer defaults,
sweep numerical options, golden data, or tolerances changed in this phase.

## Next planning step

After Phase 5 validation and review, proceed only to a separately authorized
Phase 6. Remaining cleanup belongs to examples/diagnostics, test runners,
startup/path finalization, and final documentation consolidation.

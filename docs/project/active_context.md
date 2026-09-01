# Active project context

Last reviewed: 2026-08-31
Repository: `cpariona/Lamb-fundamental-solver`
Default branch: `main`
Planning branch: `planning/full-repository-restructure`
Starting main checkpoint:
`026994f86a2d1dfe5a740034d7a5fd81d4f08235`

## Current product state

- Rayleigh-Lamb, mRLFE, and AE IOP/HGO have maintained scientific APIs.
- Main GUI, SweepTool, and FitTool are the principal human-facing surfaces.
- mRLFE production consumers route through `mrlfeSolve`.
- AE production consumers route through the maintained AE public route and
  conservative `atlasA0` policy.
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

## Required next step

Before moving production code, perform a repository-wide audit and propose the
final target architecture.

The audit must cover:

```text
top-level structure and dependency direction
GUI and adapter routes
Rayleigh-Lamb, mRLFE, and AE ownership
analysis/fitting/sweeps
configuration/default/profile ownership
result/quality schemas
plotting/export
examples/diagnostics
tests/runners
compatibility/dead code
documentation
startup/path behavior
tracked/generated artifacts
```

The audit should produce a concrete final folder tree, dependency graph,
ownership map, phased migration plan, and validation matrix before broad code
movement begins.

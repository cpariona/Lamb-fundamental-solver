# Session handoff

Updated: 2026-08-31

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Planning branch: `planning/full-repository-restructure`
- Starting main checkpoint:
  `026994f86a2d1dfe5a740034d7a5fd81d4f08235`
- Starting checkpoint message:
  `Replace AE parabolic refinement with bounded continuous refinement`

## Immediate context

The AE high-frequency refinement work is complete and merged to `main`.
Production AE candidate discovery is discrete on the atlas `cGrid`; branch
identity is selected before bounded continuous refinement of the selected
branch using the true SVD objective. The old three-point parabolic candidate
refinement is not part of the maintained production pipeline.

Last confirmed validation:

```text
AE IOP/HGO synthetic atlasA0 fitting test passed.
True mu: 50.000 kPa
Fit  mu: 50.000 kPa
Relative mu error: 5.06201e-08

Extended acoustoelastic IOP/HGO tests passed.
Acoustoelastic IOP/HGO smoke tests passed.
```

## New active campaign

The next task is a full repository restructuring. It is intentionally broader
than the previous bounded simplification and may reconsider the entire physical
organization and ownership graph.

Primary goals:

```text
order
structure
organization
versatility
adaptability
human comprehension
simplicity
```

Do not preserve a file, wrapper, route, helper, folder, or historical strategy
solely because changing it is inconvenient. Likewise, do not reorganize already
clear code merely for visual symmetry.

## Read first in the next session

```text
docs/project/full_repository_restructure_handoff.md
docs/project/active_context.md
docs/repository/maintainability_policy.md
docs/repository/refactor_policy.md
docs/repository/human_interface_contract.md
docs/repository/restructure_target_architecture.md
```

These files define the authorized scope, principles, target qualities,
human-interface contract, validation expectations, and first required audit.

## Core rules

1. One canonical owner per maintained responsibility.
2. Search/reuse existing owners before creating new ones.
3. Replace obsolete strategies and delete the superseded implementation.
4. Preserve stable scientific stage boundaries where they remain useful.
5. Main GUI, FitTool, SweepTool, examples, and scripts should converge on
   canonical model APIs.
6. GUI code owns interaction/request/display, not solver physics.
7. Keep scientific calculation, interaction, plotting, and persistence separate.
8. Limit conceptual call depth; remove forwarding-only helper chains.
9. Keep physical parameters, numerical options, execution profiles, and UI state
   conceptually distinct.
10. Keep official output, diagnostics, quality, and effective configuration
    explicit in result contracts.
11. Production must not depend on examples or exploratory diagnostics.
12. New investigation-only MATLAB files use `% TEMPORARY_DIAGNOSTIC` exactly and
    are removed before final integration unless promoted intentionally.
13. Tests must protect final architecture and numerical behavior, not obsolete
    migration paths.
14. Do not update deterministic baselines merely to make structural changes
    pass.
15. Characterize performance for meaningful solver changes without brittle
    hardware-specific thresholds.

## Required first deliverable in the next session

Do not begin by moving files.

First audit the entire maintained repository and produce:

```text
current ownership/call map
current GUI/FitTool/SweepTool route map
public/internal API inventory
dependency map
configuration/result ownership inventory
compatibility/dead-code inventory
test/runner inventory
proposed final physical folder tree
proposed final dependency graph
phased migration sequence
validation matrix by phase
```

Classify files/owners using:

```text
KEEP
REUSE
EXTEND
SIMPLIFY
MOVE
RENAME
MERGE
SPLIT
INLINE
REMOVE
REMOVE_REDUNDANT_VALIDATION
REPLACE_STRATEGY
```

## Git startup for the next session

```bash
git fetch origin
git switch planning/full-repository-restructure
git pull --ff-only origin planning/full-repository-restructure
git status -sb
```

The planning branch contains the authoritative handoff documents. After the
repository-wide audit and target architecture are approved, implementation may
continue on this campaign branch or on dedicated implementation branches based
on it.

Do not merge partially broken restructuring into `main`.

## Completion standard

The campaign is complete only when a human researcher can quickly understand
where each model, workflow, configuration, result, GUI route, plot/export path,
and test is owned; obsolete routes are gone; the active documentation describes
one final architecture; and the intended scientific functionality has been
validated.

# Full repository restructuring handoff

Updated: 2026-08-31
Repository: `cpariona/Lamb-fundamental-solver`
Planning branch: `planning/full-repository-restructure`
Starting `main` checkpoint:

```text
026994f86a2d1dfe5a740034d7a5fd81d4f08235
Replace AE parabolic refinement with bounded continuous refinement
```

## User authorization

The next repository campaign is intentionally broad. The objective is to
restructure the entire repository without treating the existing architecture as
untouchable.

The required qualities are:

```text
order
structure
organization
versatility
adaptability
human comprehension
simplicity
```

The campaign may move, rename, merge, split, delete, and reorganize maintained
code when that improves the final architecture. Temporary breakage on a working
branch is acceptable. The final accepted repository must restore the intended
maintained functionality and pass the approved scientific, contract, GUI, and
integration validation.

## Why this campaign exists

The current repository already has substantial architectural discipline:

```text
models/
analysis/
app/
examples/
tests/
docs/
```

It also has naming, ownership, dependency, entrypoint, and repository-hygiene
contracts.

However, comparison with `cpariona/OCE_Workflow` identified maintainability
principles worth adopting more explicitly:

```text
one canonical owner per responsibility
reuse before creation
replace obsolete strategies rather than stacking them
human traceability as an architectural requirement
limited conceptual call depth
extract by responsibility, not line count
strong separation of science, interaction, rendering, and persistence
clear result/configuration boundaries
no hidden alternate scientific pipelines
active documentation describes only maintained architecture
```

The goal is not to copy OCE_Workflow's folder/package structure. Lamb is a
multimodel, GUI-driven solver repository and needs a structure appropriate to
Rayleigh-Lamb, mRLFE, AE IOP/HGO, fitting, sweeps, and interactive surfaces.

## Newly established planning contracts

Read these before implementation:

```text
docs/repository/maintainability_policy.md
docs/repository/refactor_policy.md
docs/repository/human_interface_contract.md
docs/repository/restructure_target_architecture.md
```

They define the target values, allowed restructuring scope, human-interface
rules, strategy-replacement policy, validation expectations, and acceptance
criteria.

## Important current scientific baseline

Immediately before this planning branch, AE high-frequency refinement was
changed and merged to `main`.

The maintained AE production pipeline is now conceptually:

```text
SVD atlas on discrete cGrid
-> discrete local minima
-> branch linking
-> atlasA0 selection
-> bounded continuous refinement of the selected branch using the true SVD objective
-> result construction
```

The old three-point parabolic sub-grid refinement was removed from production.
Do not accidentally reintroduce it during repository restructuring.

The last confirmed AE validation was:

```text
AE IOP/HGO synthetic atlasA0 fitting test passed.
True mu: 50.000 kPa
Fit  mu: 50.000 kPa
Relative mu error: 5.06201e-08

Extended acoustoelastic IOP/HGO tests passed.
Acoustoelastic IOP/HGO smoke tests passed.
```

## Repository philosophy for the next campaign

### One responsibility, one owner

Every maintained concept should have one obvious owner. Duplicate historical
implementations should be merged or removed.

### Replace, do not layer

When a stage changes algorithm, the old strategy should be deleted once the new
one is validated. Do not keep permanent old/new pipelines merely to preserve
historical tests or reduce short-term refactor effort.

### GUI remains a human interface, not a scientific owner

The principal surfaces are:

```text
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
```

They should coordinate requests, interaction, display, and export while
scientific calculation remains in canonical model/analysis owners.

### Common surfaces converge on canonical model APIs

Desired conceptual routing:

```text
Main GUI  --+
FitTool   --+
SweepTool --+--> canonical model API --> scientific implementation
examples  --+
scripts   --+
```

Do not maintain separate scientific solvers for GUI, fitting, sweeps, and
examples.

### Simplicity over speculative abstraction

Do not introduce generic managers, stage engines, registries, services, or
helper chains merely for architectural symmetry. Adaptability should come from
clear interfaces and stable ownership boundaries.

### Human comprehension is a completion criterion

A researcher should be able to trace:

```text
user action
-> request/adapter
-> public model API
-> relevant scientific stage(s)
-> result
-> plot/export
```

with a small number of meaningful file jumps.

## Full audit scope

The next chat should audit the entire maintained repository, including:

```text
top-level folders and dependency direction
Main GUI / FitTool / SweepTool
app adapters and request normalization
Rayleigh-Lamb model
mRLFE model
AE IOP/HGO model
analysis and shared fitting/sweep infrastructure
configuration/default/profile ownership
result/quality schemas
plotting and export
examples and diagnostics
test structure and runner ownership
compatibility aliases/fallback readers
documentation
startup/path configuration
generated/tracked artifacts
naming and terminology
```

Nothing should be kept solely because moving it is inconvenient. Conversely,
nothing should be reorganized merely for visual symmetry when the existing
owner is already simple and semantically correct.

## Required first step in the next chat

Do not start by moving files.

First perform a repository-wide audit and produce:

1. a current call/ownership map;
2. a current human-interface route map;
3. a public/internal API inventory;
4. a dependency map;
5. a compatibility/dead-code inventory;
6. a test/runner inventory;
7. a proposed final physical folder tree;
8. a proposed final dependency graph;
9. a migration sequence divided into coherent implementation phases;
10. a validation matrix mapping each phase to tests and scientific baselines.

The audit must be concrete enough that the target architecture can be approved
before broad code movement begins.

## Classification vocabulary

During the audit classify files/owners using:

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

## Temporary diagnostic rule

Any new investigation-only MATLAB file created during this campaign must start
with exactly:

```matlab
% TEMPORARY_DIAGNOSTIC
```

Delete it before final integration unless it is explicitly promoted to a
maintained diagnostic with a stable purpose.

## Validation philosophy

The repository is multimodel and GUI-driven, so retain tiered validation rather
than copying OCE_Workflow's single-runner architecture mechanically.

Expected gates include, as appropriate:

```matlab
run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_acoustoelastic_smoke_tests
run_mrlfe_smoke_tests
run_numerical_regression_tests
run_extended_integration_tests
run_performance_and_benchmark_tests
```

The restructuring campaign should strengthen deterministic synthetic baselines
where they materially protect scientific behavior, preferably per model family.

Do not update a numerical baseline merely to make a structural refactor pass.

## Git workflow

The current planning material lives on:

```text
planning/full-repository-restructure
```

Recommended next-chat startup:

```bash
git fetch origin
git switch planning/full-repository-restructure
git pull --ff-only origin planning/full-repository-restructure
git status -sb
```

After the audit/target architecture is approved, implementation may continue on
this campaign branch or on dedicated implementation branches created from it.
Do not merge a partially broken restructuring into `main`.

## Completion definition

The campaign is complete only when:

```text
the repository has one obvious architecture
major responsibilities have one canonical owner
obsolete routes/strategies are gone
GUI surfaces converge on canonical model APIs
configuration and result ownership are explicit
scientific calculation is separated from interaction/rendering/persistence
tests protect the final architecture rather than migration history
active documentation contains no competing architecture
the code is easier for a human researcher to trace and modify
the maintained scientific functionality is validated
```

The objective is not minimal change. The objective is a cleaner final
repository.

# Full repository refactor policy

## Scope

This policy governs the upcoming full restructuring of
`cpariona/Lamb-fundamental-solver`.

Unlike the previous bounded simplification work, this campaign is explicitly
authorized to restructure the repository broadly. Existing file placement,
module boundaries, helper ownership, naming, adapters, public/internal splits,
and test organization may all be reconsidered when doing so improves:

```text
order
structure
organization
versatility
adaptability
human comprehension
simplicity
```

The current layout is evidence, not a constraint.

## What "full restructuring" authorizes

The campaign may:

```text
move files
rename files/functions
merge redundant owners
split conceptually overloaded owners
delete obsolete code
remove wrappers/aliases that have no justified external contract
change package/folder organization
simplify call graphs
consolidate duplicate scientific/workflow routes
redefine public/internal ownership
reorganize tests and documentation
strengthen result/request/configuration boundaries
replace internal strategies when separately validated
```

Temporary breakage during an implementation branch is acceptable. The final
accepted state must restore the intended maintained functionality and pass the
approved validation gates.

## What is not automatically authorized

Repository restructuring alone does not authorize an unreviewed change to:

```text
physical equations
constitutive models
scientific interpretation
numerical defaults/tolerances
official branch-selection policies
public result meaning
fitting objective meaning
user-visible units
```

If a structural audit reveals a scientific/numerical defect, it may be fixed,
but that change must be identified explicitly and validated as a scientific
change rather than hidden inside file movement.

## Baseline before major implementation

Before broad code movement begins, record the current `main` baseline:

```text
Git SHA
repository status
public/maintained entrypoints
current GUI routes
result schemas
execution-profile behavior
representative numerical outputs
current test results
representative runtime evidence where relevant
```

The current starting checkpoint for this campaign is:

```text
main commit: 026994f86a2d1dfe5a740034d7a5fd81d4f08235
message: Replace AE parabolic refinement with bounded continuous refinement
```

At that checkpoint the maintained AE smoke and extended tests passed, including
the synthetic atlasA0 fitting recovery with approximately zero relative error.

## Required restructuring sequence

The full repository may be transformed substantially, but implementation should
proceed in controlled domains rather than one unreviewable mechanical rewrite.

### Phase 0 — Baseline and inventory

Inventory:

```text
all top-level source layers
all public entrypoints
all maintained internal owners
GUI routes
analysis/fitting/sweep routes
model dependencies
result builders/schemas
configuration/default/profile owners
plot/export owners
examples and diagnostics
tests and runner ownership
compatibility aliases/fallbacks
tracked/generated artifacts
```

Classify each relevant owner as:

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

### Phase 1 — Approve target architecture

Before moving production code, define the intended conceptual dependency graph.
The final physical folder tree may differ from the current one, but it must make
these ownership classes obvious:

```text
human interfaces
application/request translation
reusable analysis/workflows
public model APIs
model numerical/scientific internals
results/quality/configuration
examples/diagnostics
tests
documentation
generated outputs
```

No implementation phase begins without a concrete target shape for the domain
being modified.

### Phase 2 — Structural ownership cleanup

Prioritize removal of:

```text
duplicate owners
forwarding-only helpers
unnecessary path exceptions
ambiguous generic names
scientific logic in GUI callbacks
workflow logic in model internals
analysis code duplicated across surfaces
plot/save scientific duplication
obsolete compatibility layers
retired strategy remnants
```

### Phase 3 — Canonical route consolidation

Ensure each human/programmatic route reaches one canonical scientific API:

```text
Main GUI  --+
FitTool   --+
SweepTool --+--> canonical model API --> canonical scientific owners
examples  --+
scripts   --+
```

Model-specific differences remain model-specific; routing duplication does not.

### Phase 4 — Contracts and schemas

Make request, configuration, result, quality, and persistence contracts explicit
and minimal. Separate official output from diagnostics and metadata.

### Phase 5 — Test architecture alignment

Tests must match final ownership rather than historical migration structure.
Remove tests whose only purpose is to preserve deleted architecture. Add or
update tests for:

```text
canonical routes
naming
structure/dependencies
schemas
retired-route absence
numerical regression
synthetic fitting recovery
GUI integration
performance characterization
```

### Phase 6 — Documentation finalization

Documentation should describe only the maintained final architecture. Completed
migration reports belong in Git history or a compact historical note, not as a
second active architecture.

### Phase 7 — Final deletion and simplification pass

Before final merge:

```text
remove temporary diagnostics
remove obsolete aliases and dead files
remove old/new duplicated terminology
remove stale docs
remove migration-only tests/helpers
confirm one canonical owner per responsibility
review conceptual call depth
review public API size
```

## Working-branch rules

- Start from current `origin/main` or from the dedicated planning branch when
  carrying these planning documents into implementation.
- Use focused implementation branches or a clearly staged campaign branch.
- Do not merge partially broken restructuring into `main`.
- Use `% TEMPORARY_DIAGNOSTIC` as the exact marker for newly created
  investigation-only MATLAB files.
- Remove temporary diagnostics before the final merge unless explicitly
  promoted to maintained assets.
- Do not open or merge a PR before the affected validation gate passes and the
  diff is manually reviewed.
- Squash exploratory histories when the final change is conceptually one
  architectural transformation.

## Compatibility policy

Compatibility is a design decision, not an automatic requirement.

Default rule:

```text
No forwarding alias solely to preserve an old internal name.
```

Retain compatibility only when there is credible external public usage or a
persisted-data contract that cannot reasonably be cut over in the same
campaign. Every retained exception must have:

```text
owner
reason
scope
consumer evidence
removal condition, when applicable
```

## Scientific strategy replacement rule

When a scientific/numerical stage changes strategy:

1. characterize the old behavior;
2. validate the replacement independently;
3. replace the stage through its existing or improved boundary;
4. remove the superseded implementation and flags;
5. update tests to protect the new contract;
6. update documentation to describe only the maintained strategy.

Do not maintain a permanent hybrid pipeline merely to avoid touching tests.

## Validation gates

Use the repository's tiered validation architecture. During restructuring,
expected gates include, as applicable:

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

A phase should run the smallest sufficient gate while being developed, then a
broader gate before integration.

Final acceptance requires the maintained repository-wide gates appropriate to
the resulting architecture.

## Diff review requirements

Before each major merge, inspect:

```bash
git status -sb
git diff --stat origin/main...HEAD
git diff origin/main...HEAD
```

Review for:

```text
unexpected comment/document churn
new duplicate owners
new wrappers with no clear responsibility
scientific code moved into GUI or plotting
obsolete files still present
new generic framework layers
retired terminology
unintended defaults/schema changes
```

## Completion criteria

The campaign is complete when:

1. a human can explain the top-level repository architecture quickly;
2. every major responsibility has one canonical owner;
3. the GUI routes visibly converge on canonical model APIs;
4. model internals do not depend on GUI/examples;
5. obsolete routes and strategies are deleted;
6. configuration/result boundaries are explicit;
7. tests reflect final architecture rather than migration history;
8. active documentation contains no competing architectures;
9. representative scientific/numerical behavior is preserved or intentionally
   changed and validated;
10. the final repository is simpler to navigate and safer to extend than the
    starting checkpoint.

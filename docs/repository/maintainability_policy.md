# Maintainability policy

## Purpose

The repository must remain scientifically trustworthy while also being easy to
understand, modify, extend, debug, and operate through its human-facing GUI.
Passing tests is necessary but not sufficient. A maintainer should be able to
trace a user action from Main GUI, FitTool, SweepTool, or a programmatic API to
the scientific owner that performs the calculation without traversing an opaque
framework or duplicated pipeline.

The governing qualities are:

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

When these goals conflict, prefer the simplest architecture that preserves a
clear scientific owner, stable interfaces, and reproducible behavior.

## Core rules

### 1. One canonical owner per responsibility

Every maintained responsibility must have one obvious owner. Examples include:

```text
physical equations
constitutive laws
residual/objective evaluation
branch tracking
selection policies
local refinement
result construction
quality evaluation
fitting
sweeps
GUI request translation
plotting
export/persistence
```

Do not keep two maintained implementations of the same responsibility merely
because one is older, was used by a different surface, or is easier to leave in
place.

### 2. Reuse before creation

Before creating a new public function, internal helper, adapter, renderer,
resolver, tracker, policy, result builder, or utility:

1. search the maintained repository for an existing owner with the same
   semantic responsibility;
2. reuse it directly when possible;
3. extend it only while the responsibility remains coherent and easy to explain;
4. create a new owner only when the capability is genuinely distinct and
   independently meaningful.

A new caller is not sufficient justification for a new function.

### 3. Replace obsolete strategies instead of stacking them

When the numerical or scientific strategy of one pipeline stage changes, the
new strategy replaces the old one.

Preferred transition:

```text
OLD STAGE
   -> validated replacement
NEW STAGE
   -> remove old implementation, old flags, old tests, old documentation
```

Do not leave active `old/new`, `legacy/current`, `_v2`, `_new`, `_mod`, or
parallel scientific routes unless they represent intentionally different
scientific models.

Git history preserves superseded implementations.

### 4. Preserve stable stage boundaries

A stage should expose a clear input and output contract. Its internal algorithm
may be replaced without forcing unrelated callers to understand that change.

The recent AE refinement change is the reference pattern:

```text
atlas
-> discrete candidate discovery
-> branch linking
-> A0 selection policy
-> bounded continuous refinement of the selected branch
-> result construction
```

The refinement strategy changed without requiring a second complete AE
pipeline.

### 5. Human traceability is an architectural requirement

A maintainer should normally understand one scientific operation by reading its
public/canonical owner and at most one or two meaningful helper levels.

Avoid chains such as:

```text
A -> B -> C -> D -> E
```

when intermediate functions only rename, forward, dispatch, or wrap an already
clear operation.

### 6. Extract by responsibility, not by line count

A long function is not automatically a defect. Extraction is justified when it:

- separates a distinct scientific or domain responsibility;
- isolates substantial UI construction from calculation;
- removes genuine duplication;
- creates a stable debugging boundary;
- restores one clear abstraction level in the caller.

Do not create microfunctions solely to shorten files.

### 7. Keep one abstraction level per block

A block should either coordinate domain owners or implement one domain task. Do
not mix high-level workflow decisions with unrelated low-level matrix algebra,
GUI construction, file persistence, plotting primitives, or optimization logic.

### 8. Keep the public API small and intentional

Public model APIs should expose complete scientific operations. Tracking,
policies, matrix assembly, result builders, quality evaluators, and similar
internals remain internal unless there is a concrete reusable scientific reason
to expose them.

Compatibility wrappers are not added by default. An exception requires a real
external-use contract, a documented reason, and a removal condition when
appropriate.

### 9. GUI coordinates; models calculate

Human-facing surfaces may:

```text
collect inputs
validate surface state
translate requests
choose an explicit model/mode/profile
call canonical APIs
normalize results for display
graph/export results
report warnings and quality information
```

They must not own:

```text
physical equations
constitutive laws
residuals
branch tracking
scientific fitting algorithms
hidden alternate solvers
model-specific numerical decisions that belong to the model
```

Main GUI, FitTool, SweepTool, examples, and programmatic scripts should converge
on the same canonical model APIs.

### 10. Separate science, interaction, presentation, and persistence

The conceptual ownership rule is:

```text
scientific owner -> calculates
adapter          -> translates
GUI/workflow     -> coordinates
plot*            -> renders
export/save*     -> persists existing results
```

Plotting and export code must not silently recompute scientific results using a
second algorithm.

### 11. Configuration ownership must remain explicit

Do not collapse distinct concepts merely to reduce the number of fields.
Maintain visible separation between:

```text
physical parameters
numerical options
execution profiles
surface/UI state
surface-specific policy overrides
```

Fast/Balanced/Robust may control numerical effort but must not silently change
physical meaning.

### 12. Result contracts are first-class interfaces

Each model family should have explicit request, result, and quality contracts.
A result structure should be built by a canonical owner and should separate:

```text
official scientific output
diagnostic evidence
quality/reliability metadata
requested/effective configuration metadata
```

Changing an internal solver strategy should not casually change a public result
schema.

### 13. Diagnostics must not become production dependencies

Maintained repeatable diagnostics may live under maintained diagnostic/example
locations and call production APIs.

Production code must never depend on example or exploratory diagnostic files.

A newly created investigation-only MATLAB file must begin with exactly:

```matlab
% TEMPORARY_DIAGNOSTIC
```

Such files must be deleted before the implementation branch is merged unless
they are explicitly promoted to a maintained diagnostic with a documented
purpose and tests/ownership where appropriate.

### 14. Tests protect architecture as well as numbers

Tests should protect:

```text
canonical owners
public routes
dependency direction
result/request schemas
naming contracts
absence of retired routes
representative numerical behavior
fitting recovery
GUI/adapter integration
```

When a strategy is intentionally retired, tests that encode the obsolete
behavior should be rewritten or removed and replacement contracts added. Tests
must not be weakened merely to hide a regression.

### 15. Scientific baselines must not be updated to hide refactor drift

Deterministic synthetic baselines or numerical regression references may be
introduced per model family. A baseline changes only when an intentional
scientific change has been reviewed.

A structural refactor is expected to preserve the approved scientific result
within the defined tolerance.

### 16. Performance is part of solver behavior

For algorithmic changes, correctness and runtime should both be characterized.
Use hardware-independent relative evidence where possible:

```text
baseline median runtime
new median runtime
relative runtime change
quality/error improvement
valid-point/branch-identity changes
```

Do not impose brittle machine-specific pass/fail timing thresholds.

### 17. Comments explain why; structure explains what

Names and file ownership should communicate the operational narrative. Comments
should explain non-obvious scientific intent, provenance, constraints, or
invariants rather than restating individual lines.

Long architecture contracts belong in `docs/`; source headers should remain
focused.

### 18. No opportunistic architecture growth

A task may be broad, including the full repository restructuring campaign, but
each implementation phase must still have an explicit target. Do not create
frameworks, managers, registries, generic stage engines, or abstractions merely
because they might be useful later.

Versatility and adaptability come from clear boundaries and reusable owners,
not from speculative indirection.

## Human-readability acceptance test

Before accepting a reorganized or extended owner, a reviewer should be able to
answer:

1. What does this function/module receive?
2. What does it produce or change?
3. What are its major steps, in order?
4. Which owner performs the scientific calculation?
5. Which configuration controls numerical effort versus physical meaning?
6. Which helper files are genuinely necessary?
7. Was an existing owner reused where possible?
8. Did the change remove or add conceptual layers?
9. Can a GUI user action be traced to the same canonical API used by scripts?
10. Are diagnostics, output, and production responsibilities clearly separated?

A change that passes tests but makes these questions materially harder to
answer is not a successful maintainability change.

## Review checklist

Before merging a structural/API change, verify that:

1. one canonical owner remains for each affected responsibility;
2. superseded implementations and flags are removed;
3. no hidden alternate scientific route was introduced;
4. GUI, analysis, and model ownership remain separated;
5. conceptual call depth did not increase without justification;
6. result/request/configuration contracts remain explicit;
7. temporary diagnostics are removed or intentionally promoted;
8. documentation and maintained entrypoint inventories are current;
9. affected contract, smoke, numerical, integration, and performance tests pass;
10. no baseline/golden was changed merely to make a refactor pass;
11. the final diff is easier for a human to reason about than the starting
    implementation.

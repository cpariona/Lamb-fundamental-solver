# Full repository restructuring target

## Objective

Restructure the entire repository into a final maintained architecture that is
ordered, easy to navigate, adaptable to new models/workflows, simple to reason
about, and safe for scientific development through both MATLAB APIs and human
GUI surfaces.

This is not a cosmetic folder cleanup. The campaign must review ownership,
dependency direction, public/internal APIs, call depth, duplicated routes,
configuration, results, tests, documentation, and human-facing workflows.

## Governing qualities

The target architecture must optimize for:

```text
ORDER
  every responsibility has an obvious place and owner

STRUCTURE
  dependencies and stage boundaries are explicit

ORGANIZATION
  files that change for the same reason live together

VERSATILITY
  common workflows can support multiple model families without duplicating
  science

ADAPTABILITY
  one stage or model can evolve without forcing unrelated layers to change

HUMAN COMPREHENSION
  a researcher can trace GUI -> calculation -> result with few file jumps

SIMPLICITY
  fewer concepts, fewer duplicate routes, fewer wrappers, fewer exceptions
```

## Starting conceptual layers

The current top-level layout is a useful starting point but is not protected.
The final physical tree may be changed after audit. The conceptual ownership
classes that must remain visible are:

```text
human-facing application surfaces
request/configuration translation
reusable analysis/workflows
public scientific model APIs
model scientific/numerical internals
result/quality construction
examples and maintained diagnostics
tests
documentation
generated outputs
```

## Target dependency direction

The intended dependency direction is conceptually:

```text
Human interfaces / examples
        |
        v
Application translation / reusable workflows
        |
        v
Canonical public model APIs
        |
        v
Model scientific/numerical internals
```

Result normalization, plotting, and export consume completed scientific results
and must not become alternate solver routes.

Lower scientific layers must not depend on GUI or examples.

## Human-facing architecture

The three principal human surfaces are:

```text
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
```

They should converge on canonical model APIs:

```text
                         +--> Rayleigh-Lamb API --> RL internals
Main GUI  --+            |
FitTool   --+--> adapters/workflows
SweepTool --+            |
examples  --+            +--> mRLFE API ---------> mRLFE internals
scripts   --+            |
                         +--> AE IOP/HGO API -----> AE internals
```

Model-specific translation may remain explicit when that is easier to
understand than a generic dispatch framework.

## Scientific stage architecture

Within each model, major numerical/scientific stages should be individually
replaceable through stable boundaries.

The recent AE implementation is the reference example:

```text
atlas build
-> discrete minima
-> branch linking
-> branch selection policy
-> continuous local refinement
-> result construction/quality
```

Changing the implementation of one stage should not require parallel complete
pipelines or GUI-specific solver variants.

## Model-family target

### Rayleigh-Lamb

Audit for:

```text
public API size
parameter/default ownership
residual/equation ownership
branch solver ownership
analytical approximation ownership
fitting/sweep route reuse
result schema consistency
```

Do not force unnecessary symmetry with larger model families; simplify where
the model is genuinely small.

### mRLFE

Audit for:

```text
canonical mrlfeSolve route
request/configuration/preset separation
elastic versus viscoelastic strategy ownership
branch tracking and termination policy ownership
quality/result construction
surface-specific request building
fitting and sweep route reuse
legacy route/flag absence
```

The final design should expose one obvious production route per scientifically
meaningful solve operation.

### AE IOP/HGO

Audit the now-stable stages:

```text
validation/configuration
constitutive calculation
atlas construction
discrete candidate discovery
branch linking/splitting
A0 policy
continuous selected-branch refinement
quality
result building
fitting/sweeps
diagnostic-only identity branches
```

The recently merged bounded continuous refinement is the current production
baseline and must not be accidentally reverted during structural work.

## Analysis/workflow target

Reusable analysis should own operations such as:

```text
fitting orchestration
parameter sweeps
summaries
model-neutral metrics
output-path logic
repeatable analysis workflows
```

Analysis must not duplicate model equations or tracking.

Audit whether existing shared infrastructure is genuinely reusable or merely a
generic abstraction around model-specific code. Retain shared code only when it
reduces duplication without hiding scientific ownership.

## Adapter target

Adapters are allowed and useful when they explicitly translate a human surface
request into a model API request. They should remain thin and should not own
scientific algorithms.

Audit each adapter for:

```text
request translation only
surface-specific defaults/profile mapping
result normalization only
no solver equations
no hidden scientific fallback
no duplicated fitting/sweep physics
```

Do not remove adapters merely to imitate OCE_Workflow; remove or merge them only
when a clearer direct boundary exists.

## Configuration target

The architecture must keep these concepts distinct:

```text
physical model parameters
model numerical options
execution profiles/presets
surface state
surface-specific effective configuration
```

Each option should have one owner and one documented precedence path.

A full audit should identify:

```text
duplicate defaults
unused options
historical flags
ambiguous option names
surface overrides not represented in metadata
options that mix physical and numerical meaning
```

## Result architecture target

Each model should have an explicit result contract with a canonical builder or
well-defined construction path.

A result should make clear:

```text
official output
validity/quality
diagnostics
requested configuration
effective configuration
model identity
axes/units
```

Public schemas should be stable enough that GUI, fitting, sweeps, export, and
examples consume the same scientific result semantics.

## Plot/export target

The target rule is:

```text
calculate once
normalize once where needed
render many times
persist existing results
```

Audit for scientific recomputation inside:

```text
plotting
save functions
export functions
GUI callbacks
summary figures
```

Remove duplicated calculation paths.

## Example and diagnostic target

Examples must demonstrate maintained APIs, not act as hidden production owners.

Classify examples as:

```text
basic
fitting
sweep
validation
maintained diagnostic
```

Exploratory diagnostics created during this campaign use:

```matlab
% TEMPORARY_DIAGNOSTIC
```

and are deleted before final integration unless deliberately promoted.

## Test architecture target

Retain tiered validation because the repository is multimodel and GUI-driven.
The final suite should have clear ownership for:

```text
repository hygiene
public contract
model numerical regression
synthetic truth/fitting recovery
GUI/adapters
sweeps/fitting
integration
performance characterization
```

Each test should protect a continuing invariant, not a completed migration
step.

Tests that exist only to support obsolete architecture should be removed or
rewritten after the final route is established.

## Synthetic scientific baselines

Introduce or strengthen deterministic baselines per model where they provide
real protection:

```text
Rayleigh-Lamb: known analytical/limiting behavior and representative Cp(f)
mRLFE: deterministic representative branch results
AE IOP/HGO: representative atlasA0 Cp(f) plus synthetic fitting recovery
```

Baseline updates require explicit scientific justification. Structural
refactors should not update baselines to erase numerical drift.

## Documentation target

At completion, active documentation should be compact and authoritative.
Expected core repository documents:

```text
repository_structure.md
naming_strategy.md
maintainability_policy.md
refactor_policy.md
human_interface_contract.md
maintained_entrypoints.md
validation_status.md
```

Model-specific active docs should describe current APIs and algorithms only.
Completed restructuring phases and obsolete architecture belong in Git history,
not in competing active documents.

## What should disappear

The campaign should aggressively identify and remove:

```text
dead code
unused options
unjustified aliases
forwarding-only wrappers
obsolete routes
migration-only helpers
old/new duplicate strategies
stale documentation
uncatalogued tests
scientific calculations duplicated in surfaces
unnecessary helper chains
ambiguous generic utilities
folder symmetry with no semantic benefit
```

## What should remain explicit

Do not simplify away important distinctions:

```text
different physical models
different scientifically meaningful solver modes
physical versus numerical configuration
official versus diagnostic outputs
GUI state versus model request
analysis versus model science
rendering versus calculation
```

Simplicity means fewer unnecessary concepts, not fewer scientifically meaningful
ones.

## Final acceptance criteria

The final repository should allow a new maintainer to answer quickly:

```text
Where is each model's public API?
Where is each model's physics?
Where is branch tracking/selection owned?
How does the GUI reach the model?
How does FitTool evaluate a model?
How does SweepTool evaluate a model?
Where are defaults and profiles resolved?
Who constructs the result?
Where are plots generated?
Which tests protect each route?
Where do diagnostics live?
```

If those answers require searching through multiple competing owners, the
restructuring is not complete.

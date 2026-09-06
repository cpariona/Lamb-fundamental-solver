# Human interface contract

## Purpose

`Lamb-fundamental-solver` is not only a scientific codebase; it is also operated
through human-facing MATLAB interfaces. Repository restructuring must therefore
improve internal architecture without making Main GUI, FitTool, or SweepTool
harder to understand, debug, or trust.

The human-facing surfaces are:

```text
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
```

Executable examples and programmatic APIs are secondary human interfaces and
must remain consistent with the same canonical scientific owners.

## Core route contract

The preferred route is:

```text
human controls/state
      -> surface request builder / model adapter
      -> canonical model API
      -> scientific/numerical owners
      -> canonical result
      -> surface normalization
      -> display / plot / export
```

Main GUI, FitTool, SweepTool, examples, and direct MATLAB scripts must not own
separate scientific implementations of the same model.

## GUI responsibilities

A GUI may:

```text
collect/edit user inputs
show units and parameter meaning
select model, branch/mode, and execution profile
validate human-entered surface state
translate UI state into a canonical request
invoke the maintained public API
show effective configuration and warnings
render normalized results
export already-computed results
manage interaction state
```

A GUI must not own:

```text
physical equations
matrix assembly
constitutive laws
residual/objective functions
branch tracking
branch-selection policy
local numerical refinement
scientific fitting objective implementation
hidden alternative solver routes
scientific result reconstruction that bypasses the model result contract
```

## One model, one scientific route

For each model family, all human surfaces should converge on the same maintained
scientific API unless an explicitly different scientific operation is being
requested.

Conceptually:

```text
Main GUI  --+
FitTool   --+
SweepTool --+--> MODEL API --> MODEL IMPLEMENTATION
example   --+
script    --+
```

Do not maintain `GUI solver`, `FitTool solver`, and `SweepTool solver` variants
of the same physics.

## Physical versus numerical controls

The interface must make a visible distinction between:

```text
physical parameters
numerical accuracy/effort controls
execution profile
plot/display controls
workflow controls
```

A user should not need source-code knowledge to determine whether changing a
control changes the physical problem or only numerical effort.

Execution profiles such as:

```text
Fast
Balanced
Robust
```

must control numerical behavior through documented configuration ownership.
They must not silently alter physical meaning.

Where an adapter changes a requested profile to an effective profile, the
result metadata should preserve enough information to explain that decision,
for example:

```text
requestedExecutionProfile
effectiveExecutionProfile
profileOverrideReason
```

## Units and terminology

User-facing parameters must use stable, explicit terminology and units.
Mathematical shorthand may be used in equations or labels when helpful, but
public request/result fields and GUI controls should avoid ambiguous notation.

Existing thickness conventions remain a useful pattern:

```text
request/internal semantic concept: total thickness
mathematical notation where appropriate: 2h
explicit dimensionless quantity: kThickness
```

Renaming during restructuring must improve clarity consistently across GUI,
APIs, exports, documentation, and tests.

## Error and warning behavior

Human-facing errors should identify:

```text
what input or scientific condition is invalid
which model/stage rejected it
what the user can change
```

Do not expose opaque internal exceptions as the normal interaction model when a
surface can report a clear domain-level message.

Warnings that materially affect interpretation should be visible to the user or
retained in result quality metadata. Silent fallback to a scientifically
different route is not acceptable.

## Result transparency

A user-facing result should distinguish:

```text
official output
diagnostic information
quality state
requested versus effective configuration
execution metadata
```

`quality` is the common name for assessment of official model output. A model
may expose its own scientifically meaningful metrics beneath that field. The
AE historical name `reliability` is not a parallel alias.

The GUI should not convert diagnostic candidates into official curves merely
because they are convenient to plot.

## Plotting contract

Plotting functions render existing data. They do not own a second calculation
path.

Preferred ownership:

```text
plot*   -> render existing normalized/scientific result
save*   -> call/reuse plot* and persist
export* -> serialize an existing result/table
```

If a plot requires a derived display quantity, that derivation must be clearly
presentation-level or owned by a reusable analysis/result-normalization layer;
it must not duplicate solver physics.

## FitTool contract

FitTool may own:

```text
experimental data editing/validation
fit parameter selection
fit request construction
optimization workflow display
fit quality presentation
```

The model prediction evaluated during fitting must come from the canonical
model solver/evaluation path. FitTool must not contain its own simplified copy
of the model unless that approximation is an explicit, separately named
scientific model.

## SweepTool contract

SweepTool may own:

```text
parameter selection
range/grid UI
sweep request construction
interactive visualization
```

The sweep computation must call the canonical model API per condition or a
reusable analysis owner that itself calls that API. SweepTool must not own model
physics or tracking logic.

## Main GUI contract

Main GUI is the primary exploratory surface. It should remain understandable to
a researcher reading the callbacks/request flow. Avoid generic dispatch engines
that obscure which model API is called.

Some explicit model-specific adapters are preferable to one highly dynamic
framework when they make ownership and debugging clearer.

## Human debugging contract

A researcher should be able to debug a GUI calculation by following a small,
visible chain:

```text
surface state
-> request/adapter
-> model API
-> relevant scientific owner(s)
-> result
-> renderer
```

A restructuring that introduces many forwarding layers without adding a real
domain boundary fails this contract even if the GUI still launches.

## Adaptability without framework inflation

The repository should be easy to extend with a new model, fitting parameter, or
sweep without editing unrelated model internals. Achieve this through clear
interfaces and responsibility boundaries, not speculative managers, dynamic
stage registries, or generic scientific dispatch graphs.

A new model may require a new explicit adapter. That is acceptable when it
keeps model-specific translation visible and avoids scientific duplication.

## Human-interface acceptance checklist

Before accepting a restructuring phase affecting `app/` or analysis surfaces,
verify:

1. Main GUI, FitTool, and SweepTool still reach canonical model APIs;
2. no scientific equations or tracking logic moved into callbacks;
3. physical and numerical controls remain distinguishable;
4. units and labels remain explicit;
5. effective execution configuration remains inspectable;
6. warnings/fallbacks are scientifically transparent;
7. plotting/export do not duplicate calculation;
8. the route from user action to solver is shorter or clearer, not more opaque;
9. GUI smoke/integration tests pass;
10. representative manual execution remains understandable without opening a
    large helper graph.

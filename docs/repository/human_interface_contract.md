# Human interface contract

The maintained human interfaces are:

```matlab
LambFundamental_GUI
FitTool_GUI
```

The solver GUI owns interactive forward-solver requests, model selection,
result presentation, and export. FitTool owns experimental-data interaction,
fit-parameter controls, fitting requests, and fit presentation.

Both surfaces must call canonical APIs. They must not own equations,
constitutive laws, candidate discovery, tracking, branch selection, residual
definitions, optimization, or alternate solvers.

```text
Solver GUI ----> MODEL API ----> MODEL IMPLEMENTATION
FitTool -------> FITTING API --> MODEL API --> MODEL IMPLEMENTATION
```

App normalization may translate units, execution-profile controls, table state,
and view schemas. Export serializes an existing canonical result and never
recomputes it.

Sensitivity campaigns and solver diagnostics are not GUI products. They are
opt-in studies and may call canonical APIs directly. Production code never
depends on them.

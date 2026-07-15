# Historical mRLFE tracker diagnostic summary

This note preserves the durable conclusions from the former tracker and real-k
range diagnostics. It is historical evidence, not an active solver contract or
a maintained command surface. The source scripts are retained under
`examples/mrlfe/diagnostics/archive/` and do not resolve after `startup`.

## Evidence retained

The comparison covered elastic and viscoelastic A0-like and S0-like branches.
Across those cases, the tracked phase velocity stayed close to the nearest
local residual minimum while a global residual minimum frequently selected a
different, nonphysical low-velocity valley. The evidence supports retaining:

- modal-reference information;
- local-minimum selection;
- continuity and branch-specific windows;
- branch-cut logic for conservative real-k validity.

The diagnostic was intentionally retired because it was an exploratory,
high-cost investigation rather than a regression contract. Its last recorded
cases used 120 frequency points from 500 to 16000 Hz and a 5000-point phase
velocity scan. Exact historical values remain available in Git history.

## Current contracts

Use these maintained references instead:

```text
docs/models/mrlfe/public_api.md
docs/models/mrlfe/production_core.md
docs/models/mrlfe/fitting_workflow.md
examples/mrlfe/diagnostics/README.md
```

Use `diagnose_mrlfe_fit_performance` for the maintained fit performance/cache
diagnostic. Solver tracking changes are validated by the production-core,
public-contract, characterization, and smoke-test runners.

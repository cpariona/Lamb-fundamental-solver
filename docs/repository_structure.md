# Repository structure

This repository follows a model-family layout. Reusable analysis helpers, model implementations, executable examples, tests, and documentation should remain separated.

## Top-level layout

```text
analysis/    reusable analysis helpers and fitting backends
app/         GUI entrypoints, adapters, plotting, and request/result normalization
docs/        documentation and validation notes
examples/    executable examples, sweeps, and diagnostics
models/      model implementations and numerical solvers
tests/       smoke tests, contract tests, and focused validation tests
Results/     generated outputs; not source code
```

## mRLFE layout

Reusable mRLFE helpers live in:

```text
analysis/mrlfe/
```

mRLFE model and solver internals live in:

```text
models/mrlfe/
```

mRLFE examples live in:

```text
examples/mrlfe/
```

mRLFE tests live in:

```text
tests/mrlfe/
```

mRLFE documentation lives in:

```text
docs/mrlfe/
```

## Acoustoelastic IOP/HGO layout

Reusable acoustoelastic IOP/HGO helpers live in:

```text
analysis/acoustoelastic_iop_hgo/
```

Model implementation and solver internals live in:

```text
models/acoustoelastic_iop_hgo/
├─ core/
├─ constitutive/
├─ solvers/
└─ options/
```

Recommended author-neutral entrypoints include:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticIOPHGODispersion
defaultAcoustoelasticIOPHGOOptions
```

GUI code, examples, diagnostics, tests, and analysis scripts should call the author-neutral acoustoelastic IOP/HGO API documented in `docs/acoustoelastic_iop_hgo/active/public_api.md`.

Model-specific analysis helpers for diagnostics and output paths live in:

```text
analysis/acoustoelastic_iop_hgo/
```

Examples:

```matlab
aeOutputFolder
aeRunSweep
aeSummarizeSweep
```

Examples and diagnostics live in:

```text
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/sweeps/
examples/acoustoelastic_iop_hgo/diagnostics/
```

Tests live in:

```text
tests/acoustoelastic_iop_hgo/
```

Documentation lives in:

```text
docs/acoustoelastic_iop_hgo/
├─ active/
├─ diagnostics/
├─ audits/
└─ archive/
```

## Rayleigh-Lamb layout

Rayleigh-Lamb helpers use the `rl*` naming convention and live primarily under:

```text
models/rayleigh_lamb/
analysis/rayleigh_lamb/
examples/rayleigh_lamb/
tests/rayleigh_lamb/
docs/rayleigh_lamb/
```

## GUI layout

The GUI layer should call adapters and backend helpers. It should not implement solver physics directly.

```text
app/
├─ adapters/
├─ fitting/
└─ plotting/helpers as needed
```

GUI documentation lives in:

```text
docs/gui/
```

## Sweeps

Generic sweep documentation lives in:

```text
docs/sweeps/
```

Model-specific sweep documents may remain under the model-family docs folder.

## Output paths

Generated outputs should go under `Results/`, not under source folders. Model-specific helpers should own output-folder construction where possible.

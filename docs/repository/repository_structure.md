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

## Target cross-cutting layout

Long-term organization should distinguish three layers consistently across source, docs, and tests:

```text
models/      physical/numerical model implementations
app/         GUI, FitTool, SweepTool, adapters, and app-layer dispatch
shared/      reusable infrastructure not owned by one model or app surface
```

This target should be reached gradually. Do not combine broad file moves with solver behavior changes.

## Tests layout

The target test layout is documented in:

```text
tests/README.md
```

Target structure:

```text
tests/
├─ README.md
├─ runners/
├─ shared/
│  ├─ fitting/
│  ├─ sweeps/
│  └─ utilities/
├─ models/
│  ├─ rayleigh_lamb/
│  ├─ mrlfe/
│  └─ acoustoelastic_iop_hgo/
└─ app/
   ├─ gui/
   ├─ fitting/
   └─ sweeps/
```

Folder responsibilities:

```text
tests/runners/                 maintained runner entrypoints
tests/shared/                  reusable helper and infrastructure tests
tests/models/<model_family>/   physical/numerical model-family tests
tests/app/                     GUI, FitTool, SweepTool, adapter, and app-layer tests
```

Migration policy:

```text
1. Preserve existing runner commands while moving implementations.
2. Move one coherent test family at a time.
3. Update runners and docs in the same PR as each move.
4. Keep wrappers temporarily if they reduce disruption.
5. Run focused tests plus the full smoke suite before merge.
```

The current `startup.m` adds `tests/` recursively to the MATLAB path, so internal test folder moves are path-safe as long as test names remain unique and runner names remain available.

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

mRLFE model tests now live in:

```text
tests/models/mrlfe/
```

mRLFE app/FitTool tests remain outside the model-test folder until the app-layer test migration is performed.

mRLFE documentation lives in:

```text
docs/models/mrlfe/
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

GUI code, examples, diagnostics, tests, and analysis scripts should call the author-neutral acoustoelastic IOP/HGO API documented in `docs/models/acoustoelastic_iop_hgo/active/public_api.md`.

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

Current tests live in:

```text
tests/acoustoelastic_iop_hgo/
```

Target AE IOP/HGO tests should move gradually to:

```text
tests/models/acoustoelastic_iop_hgo/
```

Documentation lives in:

```text
docs/models/acoustoelastic_iop_hgo/
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
docs/models/rayleigh_lamb/
```

Target Rayleigh-Lamb tests should move gradually to:

```text
tests/models/rayleigh_lamb/
```

## GUI layout

The GUI layer should call adapters and backend helpers. It should not implement solver physics directly.

```text
app/
├─ adapters/
├─ fitting/
└─ plotting/helpers as needed
```

Current GUI/app tests are mixed under `tests/` and `tests/fitting/`. Target GUI/app tests should move gradually to:

```text
tests/app/gui/
tests/app/fitting/
tests/app/sweeps/
```

GUI documentation lives in:

```text
docs/workflows/gui/
```

## Sweeps

Generic sweep documentation lives in:

```text
docs/workflows/sweeps/
```

Model-specific sweep documents may remain under the model-family docs folder.

Shared sweep tests should move gradually to:

```text
tests/shared/sweeps/
```

## Fitting

Shared fitting helper tests should move gradually to:

```text
tests/shared/fitting/
```

App-level fitting tests should move gradually to:

```text
tests/app/fitting/
```

Model-specific fitting tests should move gradually to:

```text
tests/models/<model_family>/
```

## Output paths

Generated outputs should go under `Results/`, not under source folders. Model-specific helpers should own output-folder construction where possible.

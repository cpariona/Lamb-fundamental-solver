# Acoustoelastic IOP/HGO overview

The acoustoelastic IOP/HGO model lives under `models/acoustoelastic_iop_hgo/` and exposes an author-neutral public API. The maintained API uses `Acoustoelastic` and `AcoustoelasticIOPHGO` naming for solvers, options, constitutive helpers, matrix construction, root evaluation, objectives, examples, diagnostics, tests, and analysis helpers.

The old author-specific compatibility wrappers have been removed as an intentional cleanup. This keeps the maintained surface area small and avoids carrying duplicate names for the same numerical implementation.

## Active implementation layout

```text
models/acoustoelastic_iop_hgo/
├─ constitutive/
├─ core/
├─ options/
└─ solvers/
```

## Maintained caller layout

```text
examples/acoustoelastic_iop_hgo/
├─ basic/
├─ diagnostics/
└─ sweeps/

tests/acoustoelastic_iop_hgo/
analysis/acoustoelastic_iop_hgo/
```

## Usage guidance

- Use `solveAcoustoelasticIOPHGOBranch` for the high-level branch workflow.
- Use `defaultAcoustoelasticIOPHGOOptions` for solver options.
- Use the author-neutral helper names documented in `docs/acoustoelastic_iop_hgo_public_api.md` for lower-level workflows.
- GUI code and maintained examples should not call removed compatibility names.
- Numerical algorithms, equations, tolerances, root finding, tracking behavior, output structures, and public author-neutral signatures are unchanged by this cleanup.

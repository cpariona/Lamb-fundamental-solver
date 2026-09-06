# AE IOP/HGO architecture

The maintained public solver is
`models/acoustoelastic_iop_hgo/api/solveAcoustoelasticIOPHGOBranch.m`.
It owns public request validation/orchestration and delegates scientific work to
the model layer. `aeResolveConfiguration` and `aeGetNumericalPreset` own
configuration; atlas construction, linking, selection, fallback, quality
assessment, and result construction remain separate model responsibilities.

The common model-family spine is explicit:

```text
models/acoustoelastic_iop_hgo/
  api/             public solver entry point
  configuration/   defaults, validation, policy normalization, presets
  core/            model problem/state construction
  solvers/         maintained atlas solve orchestration
  tracking/        atlas minima linking/splitting/refinement support
  quality/         assessment of already-decided official output
  results/         canonical result construction
```

Scientifically specific AE ownership remains under `constitutive/`,
`diagnostics/`, and `policies/` where those stages are real model
responsibilities.

```text
app consumers -> public API -> atlasA0 solver -> tracking/policy -> quality -> canonical result
analysis fit/sweep -----------------^
diagnostics ------------------------- inspection only
```

The model layer does not depend on `analysis/`, `app/`, `examples/`, or
`tests/`. Analysis owns fitting, sweep orchestration, plotting, persistence,
and diagnostic interpretation. Application code owns surface translation and
presentation. Examples only compose maintained APIs.

The official public curve uses column-oriented
`frequency_Hz`, `phaseVelocity_mps`, `wavenumber_radpm`, and `validMask`.
Quality uses the shared lower-camel core fields and may add AE-specific evidence.
Stable interpreted evidence belongs under `diagnostics`; large/unstable internal
atlas state belongs under `debug`.

No diagnostic branch can replace production selection or result construction.
The numerical regression golden and its tolerance are independent contracts.

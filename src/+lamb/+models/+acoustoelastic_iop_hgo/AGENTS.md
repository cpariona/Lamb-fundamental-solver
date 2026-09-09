# AE IOP/HGO model context

This file governs only `src/+lamb/+models/+acoustoelastic_iop_hgo/`.
Repository-wide and cross-layer rules remain in the root `AGENTS.md`.

## Production identity

`atlasA0` is the only official production branch. The official arrays are the
selected production result and its validity mask. Raw atlas branches,
`identityA0Diagnostic`, direct real-Cp diagnostics, and fallback candidates
never replace or fill official output. There is no maintained complex-C route.

The production order is invariant:

```text
constitutive state
-> discrete atlas evaluation and candidate discovery
-> discrete branch linking and atlasA0 selection
-> bounded refinement of only the selected branch
-> requested-grid projection, validity policy, quality, and result assembly
```

Refinement minimizes the true SVD objective after branch identity has been
selected. It may improve the selected point inside its bounded neighborhood but
must not alter candidate discovery, ranking, linking, branch identity, or the
valid mask established by selection.

## Grid, validity, and diagnostics

Preserve the separation between the internal atlas tracking grid and requested
output frequencies. Do not interpolate across disallowed gaps, smooth missing
segments, or use diagnostic candidates as scientific correction. Fallback
invalidation and its metadata are part of the production contract.

Residual-only tracking can be modally ambiguous near crossings and in the
low-stiffness/high-IOP regime. Treat truncation conservatively unless independent
scientific evidence authorizes a policy change. Diagnostics may expose evidence
for inspection, but they must remain separate from production selection and
result construction.

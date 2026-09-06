# AE IOP/HGO public API

```matlab
params = struct('R',7.8e-3,'thickness',550e-6,'mu',50e3, ...
    'k1',25e3,'k2',100,'rho',1060,'rhoF',1000, ...
    'fluidBulkModulus',2.2e9,'IOP',15*133.322, ...
    'frequency',logspace(log10(300),log10(15e3),35));
opts = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions;
result = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, opts);
```

## Inputs and options

Physical units: R and full thickness in m; mu, k1, IOP, and fluid bulk modulus
in Pa; k2 dimensionless; rho and rhoF in kg/m3; frequency in Hz.
IOP is converted from mmHg by callers, not interpreted as mmHg by the solver.
The constitutive model derives incremental coefficients from the pressure,
geometry, and HGO material parameters.

The default options function owns numerical controls: matrix variant, row
normalization, atlas velocity search window, grid density, candidate count,
branch linking/selection, fallback invalidation, requested/internal frequency
mapping, and bounded selected-branch refinement. Refinement uses fminbnd on
the true SVD objective. See `algorithm.md` for the scientific pipeline.

## Result

Official arrays are `frequency_Hz`, `phaseVelocity_mps`,
`wavenumber_radpm`, and `validMask`; `quality` is the official
assessment. `configuration.requested` and `configuration.effective`
separate caller input from resolved settings; `execution` reports operational
metadata. Atlas tables and diagnostic candidates are not official substitutes.

The production policy is `atlasA0`. The optional
`identityA0Diagnostic` inspection setting adds
`diagnostics.identityA0` while preserving official atlasA0 arrays. It is
not another accepted production branch. See
`../diagnostics/identityA0_diagnostic_policy.md`.

## Workflows and limitations

Reusable operations are `lamb.fitting.acoustoelastic_iop_hgo.aeFitDispersionData`, `aeRunSweep` (1D), and
`aeRunGridSweep` (2D). Application adapters only translate inputs and views.
Examples are opt-in, e.g.:

```matlab
run('examples/acoustoelastic_iop_hgo/basic/run_atlas_branch.m')
```

A finite atlas and conservative branch policy can truncate output in difficult
regimes. Respect validMask, fallback metadata, and quality; do not fill gaps
with diagnostic candidates or smooth plotted curves as scientific correction.
Synthetic recovery and convergence checks validate specified regimes, not
experimental accuracy or universal modal identity.

# mRLFE model context

This file governs only `src/+lamb/+models/+mrlfe/`. Cross-layer rules remain in
the repository root `AGENTS.md`.

## Request and ownership

The public solver consumes a canonical SI request: frequency in Hz, shear
modulus in Pa, shear viscosity in Pa*s, density in kg/m^3, full thickness in m,
and fluid sound speed in m/s. Keep public physical parameters distinct from
internal solver state and workflow aliases. Request resolution, numerical
preset resolution, validation, and requested/effective configuration must
remain explicit.

`tracking/mrlfeBuildSeed` owns the sole intentional cross-family dependency and
must obtain its seed through
`lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes`. Core construction,
solvers, policies, or result builders must not create an alternate RL route.

## Numerical invariants

- Preserve elastic and viscoelastic branch identity, candidate generation,
  prediction, residual scoring, adaptive continuation, and robust-start rules.
- Coarse scanning and rescue scanning have distinct established roles. Do not
  change their densities, windows, candidate counts, or activation semantics
  during structural work.
- Discrete candidate identity is selected before continuous refinement of the
  selected candidate. Refinement improves that candidate; it must not select a
  different branch.
- `trackerEdgeGuardPoints` is `4` on the maintained route. Do not replace it
  with a solver-local fallback or surface-specific value.
- Preserve requested-frequency coverage, internal-grid precedence, numerical
  presets, and diagnostic override reporting.

## Policy and results

`A0Like` uses `physicalTail`; `S0Like` uses `none`. Production fallback remains
`none`. Preserve termination evidence, quality evaluation, neutral engine names,
requested/effective configuration, and the public result schema. Fitting,
studies, and apps must continue to reach this model through the canonical public
solver rather than an internal or historical route.

# mRLFE pending cleanup

## Use `mu` as the primary material parameter

Current status:

- The maintained mRLFE and Rayleigh-Lamb sweep examples expose shear modulus `mu` to the user.
- Internally, the current Rayleigh-Lamb/mRLFE parameter structures still use `E` and `nu`.
- The current transition implements `mu` as `E = 3*mu` for the near-incompressible reference case.

Pending cleanup:

- Add shared elastic-parameter conversion for Rayleigh-Lamb and mRLFE workflows.
- Keep `mu` as the primary user-facing input for soft incompressible materials.
- Derive `E` explicitly as `E = 2*mu*(1 + nu)` when a solver still needs `E` and `nu`.
- Treat Lamé parameters as derived/internal quantities unless a diagnostic specifically validates the Lamé formulation.
- Update GUI/request metadata, examples, and documentation so `mu` is the primary input for soft incompressible materials.
- Preserve backward compatibility for existing scripts that still provide `E`.

Rationale:

Most soft-tissue and OCE literature reports shear modulus rather than Young's modulus. The maintained examples already follow that convention at the user-facing level, but the lower-level solver parameterization should eventually match it through an explicit conversion instead of relying on an implicit incompressible approximation.

## Collapse elastic and viscoelastic mRLFE variants

Current status:

- The code still exposes separate elastic and viscoelastic real-k model labels in some workflows.
- The maintained sweep examples use the viscoelastic real-k branch family and sweep or fix `etaS` explicitly.

Pending cleanup:

- Treat mRLFE as a single model family with `etaS` as the controlling viscous parameter.
- Interpret `etaS = 0` as the elastic limit of the same mRLFE model instead of routing to a separate elastic model label.
- Update examples, GUI/request metadata, normalizers, and documentation after the solver-side parameter contract is clarified.

Rationale:

This would better match the intended physical interpretation: the elastic case should be the zero-viscosity limit of the same model rather than a separate user-facing model variant.

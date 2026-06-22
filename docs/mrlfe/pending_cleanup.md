# mRLFE pending cleanup

## Use `mu` as the primary material parameter

Current status:

- The maintained mRLFE examples expose shear modulus `mu` to the user.
- Internally, the current Rayleigh-Lamb/mRLFE parameter structure still uses `E` and `nu`.
- The `mu` sweep is therefore implemented as `E = 3*mu` for the near-incompressible reference case.

Pending cleanup:

- Add native `mu` support to the mRLFE/Rayleigh-Lamb parameter workflow.
- Keep `E` as a derived quantity when the selected material parameterization is shear-modulus based.
- Update GUI/request metadata, examples, and documentation so `mu` is the primary input for soft incompressible materials.
- Preserve backward compatibility for existing scripts that still provide `E`.

Rationale:

Most soft-tissue and OCE literature reports shear modulus rather than Young's modulus. The maintained mRLFE examples already follow that convention at the user-facing level, but the lower-level solver parameterization should eventually match it directly.

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

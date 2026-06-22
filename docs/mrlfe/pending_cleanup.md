# mRLFE pending cleanup

## Material-parameter cleanup status

Current status:

- Rayleigh-Lamb and mRLFE maintained sweeps now expose `mu` as the primary elastic stiffness parameter.
- The maintained linear-isotropic material contract is `ShearPoisson`: `mu`, `nu`, and `rho` are primary inputs.
- `E`, `lambda_Lame`, `K`, `CT`, and `CL` are derived through shared helpers under `models/materials/`.
- The previous `E = 3*mu` transition approximation has been removed from maintained sweep helpers.

Remaining cleanup:

- Review old diagnostics and archived scripts that may still discuss `E`-based sweeps historically.
- Keep `E` as a displayed/derived quantity, not as a primary soft-material sweep variable.
- Keep `LameParameters` available for explicit formulation diagnostics.

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

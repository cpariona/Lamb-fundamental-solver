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

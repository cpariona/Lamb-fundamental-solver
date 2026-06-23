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

## mRLFE real-k unification status

Current status:

- The maintained GUI and SweepTool surface expose a single `mRLFE real-k` model.
- `etaS = 0` is treated as the elastic fluid-loaded limit.
- `etaS > 0` is treated as the viscous case of the same mRLFE real-k model.
- The maintained normalized model name is `mRLFERealK`.
- The solver keeps the etaS = 0 branch as an internal reference/buffer when computing etaS > 0.
- The main GUI reuses a compatible cached etaS = 0 reference when available.
- `tests/mrlfe/test_mrlfe_etaS_zero_limit.m` protects the etaS = 0 physical contract.
- `tests/mrlfe/test_mrlfe_elastic_reference_buffer.m` protects the etaS > 0 buffer contract.

Remaining cleanup:

- Rename old diagnostic scripts that still contain author-dependent labels in their filenames.
- Update archived diagnostic documentation after those scripts are renamed or retired.
- Remove temporary compatibility aliases after the remaining old diagnostics are migrated.

Rationale:

The elastic and viscous cases are not separate physical models. They are the same fluid-loaded real-k mRLFE model evaluated at different `etaS` values. The two mRLFE contract tests are kept as permanent regression tests because they define the unified model behavior; they are not temporary optimization diagnostics.

## Solver optimization guardrail

Before changing branch tracking, objective functions, or internal grids, the maintained smoke suite must continue to pass:

```matlab
run_all_smoke_tests
```

Any temporary optimization script should either be deleted before merge or promoted to a maintained test/diagnostic with clear naming and documentation. Optimization-only artifacts should not remain in the repository after the selected solver strategy is finalized.

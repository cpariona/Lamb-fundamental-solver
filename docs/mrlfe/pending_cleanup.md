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

## mRLFE residual objective status

Current status:

- `objectiveMRLFEResidual` is the maintained scalar objective helper for the 5-by-5 mRLFE matrix.
- The maintained default objective is `minSingularValueRatio`, defined as `sigma_min(M)/sigma_max(M)`.
- The determinant-based objective remains available only through the explicit `determinant` method for comparison or focused diagnostics.
- `mrlfeResidual` remains as a compatibility wrapper around `objectiveMRLFEResidual`.
- `tests/mrlfe/test_mrlfe_residual_objective_contract.m` protects the objective default and wrapper behavior.

Rationale:

This mirrors the numerical lessons from the acoustoelastic solver: the determinant of a boundary-condition matrix can be poorly scaled, while a singular-value objective is more robust for branch tracking.

## mRLFE internal tracking grid status

Current status:

- `options.mrlfeUseInternalTrackingGrid` enables an optional AE-style internal tracking grid for mRLFE real-k branches.
- The option is disabled by default to preserve current GUI and sweep behavior.
- When enabled, mRLFE tracks on a denser internal frequency grid and resamples the branch back to the requested frequency grid.
- Internal tracking metadata is stored in `mrlfeResults.tracking` and in each branch under `branch.internalTracking`.
- `tests/mrlfe/test_mrlfe_internal_tracking_grid.m` protects the contract that the external branch output remains on the requested grid.
- `tests/mrlfe/test_mrlfe_internal_tracking_grid_with_buffer.m` protects the same contract for the etaS > 0 path using a compatible etaS = 0 reference buffer.

Rationale:

This introduces the main architectural lesson from AE without forcing it as the default strategy. It allows controlled comparison of standard tracking versus internal-grid tracking while keeping the public output shape unchanged. The buffered etaS > 0 contract covers the path that is most relevant for deciding whether the internal grid should later become the default viscous strategy.

## Solver optimization guardrail

Before changing branch tracking, objective functions, or internal grids, the maintained smoke suite must continue to pass:

```matlab
run_all_smoke_tests
```

Any temporary optimization script should either be deleted before merge or promoted to a maintained test/diagnostic with clear naming and documentation. Optimization-only artifacts should not remain in the repository after the selected solver strategy is finalized.

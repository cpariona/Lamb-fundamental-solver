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

- `options.mrlfeUseInternalTrackingGrid` enables the AE-style internal tracking grid explicitly for mRLFE real-k branches.
- `options.mrlfeUseInternalTrackingGridForViscousRealK` enables the internal grid automatically for the viscous `etaS > 0` path by default.
- The direct tracker remains the default for the `etaS = 0` elastic limit unless `mrlfeUseInternalTrackingGrid` is explicitly enabled.
- When enabled, mRLFE tracks on a denser internal frequency grid and resamples the branch back to the requested frequency grid.
- Internal tracking metadata is stored in `mrlfeResults.tracking` and in each branch under `branch.internalTracking`.
- `tests/mrlfe/test_mrlfe_internal_tracking_grid.m` protects the contract that the external branch output remains on the requested grid.
- `tests/mrlfe/test_mrlfe_internal_tracking_grid_with_buffer.m` protects the same contract for the etaS > 0 path using a compatible etaS = 0 reference buffer.
- `tests/mrlfe/test_mrlfe_viscous_default_internal_tracking_grid.m` protects the policy that etaS > 0 uses the internal tracking grid by default.

Rationale:

This introduces the main architectural lesson from AE where it is most useful: the viscous real-k path can have competing residual valleys and benefits from tracking on a denser internal grid while preserving the requested output grid.

## mRLFE tracking quality summary status

Current status:

- `summarizeMRLFETrackingQuality` is the maintained analysis helper for comparing mRLFE branch quality across tracking strategies.
- `compareMRLFETrackingStrategies` is the maintained comparison helper for running direct and internal-grid strategies on the same mRLFE branch setup.
- The helpers accept full mRLFE result structs or individual branch structs and do not create files or figures.
- They report valid fraction, frequency span, Cp range, relative jumps, roughness, residual metrics, internal-grid usage, and a compact quality score.
- `tests/mrlfe/test_mrlfe_tracking_quality_summary.m` protects the summary helper contract.
- `tests/mrlfe/test_mrlfe_tracking_strategy_comparison.m` protects the direct/internal-grid comparison helper contract.

Rationale:

These helpers provide a permanent way to compare direct tracking and internal-grid tracking without keeping temporary optimization scripts in the repository.

## Solver optimization guardrail

Before changing branch tracking, objective functions, or internal grids, the maintained smoke suite must continue to pass:

```matlab
run_all_smoke_tests
```

Any temporary optimization script should either be deleted before merge or promoted to a maintained test/diagnostic with clear naming and documentation. Optimization-only artifacts should not remain in the repository after the selected solver strategy is finalized.

# mRLFE archived cleanup status

This document preserves historical cleanup status for mRLFE. It is not the active route, fitting, or GUI contract. Active references live in:

```text
docs/models/mrlfe/README.md
docs/models/mrlfe/fitting_workflow.md
docs/models/mrlfe/fittool_grid_path_sensitivity.md
docs/models/mrlfe/atlas_policy_notes.md
docs/workflows/gui/mrlfe_atlas_policy_integration.md
```

## Material-parameter cleanup status

Current status:

- Rayleigh-Lamb and mRLFE maintained sweeps expose `mu` as the primary elastic stiffness parameter.
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
- The physical raw model names are `mRLFEElasticRealK` and `mRLFEViscoRealK`.
- Author-dependent mRLFE model names have been removed from the maintained solver, GUI, docs, and smoke-test surface.
- `tests/models/mrlfe/test_mrlfe_etaS_zero_limit.m` protects the etaS = 0 physical contract.
- `tests/models/mrlfe/test_mrlfe_elastic_reference_buffer.m` protects the etaS > 0 buffer contract.
- `tests/models/mrlfe/test_mrlfe_model_candidate_names.m` protects the canonical model-name contract.
- `tests/models/mrlfe/test_mrlfe_maintained_entrypoints_naming.m` guards maintained mRLFE files against reintroducing author-dependent names.

Remaining cleanup:

- No maintained mRLFE real-k naming cleanup remains open.
- Any future archived documentation cleanup should preserve historical context only when needed and must not reintroduce author-dependent names into maintained entrypoints.

Rationale:

The elastic and viscous cases are not separate physical models. They are the same fluid-loaded real-k mRLFE model evaluated at different `etaS` values. The mRLFE contract tests are kept as permanent regression tests because they define the unified model behavior; they are not temporary optimization diagnostics.

## mRLFE residual objective status

Current status:

- `objectiveMRLFEResidual` is the maintained scalar objective helper for the 5-by-5 mRLFE matrix.
- The maintained default objective is `minSingularValueRatio`, defined as `sigma_min(M)/sigma_max(M)`.
- The determinant-based objective remains available only through the explicit `determinant` method for comparison or focused diagnostics.
- `mrlfeResidual` remains as a compatibility wrapper around `objectiveMRLFEResidual`.
- `tests/models/mrlfe/test_mrlfe_residual_objective_contract.m` protects the objective default and wrapper behavior.

Rationale:

This mirrors the numerical lessons from the acoustoelastic solver: the determinant of a boundary-condition matrix can be poorly scaled, while a singular-value objective is more robust for branch tracking.

## mRLFE internal tracking grid status

Historical status:

- `options.mrlfeUseInternalTrackingGrid` enables the AE-style internal tracking grid explicitly for mRLFE real-k branches.
- `options.mrlfeUseInternalTrackingGridForViscousRealK` enables the internal grid automatically for the viscous `etaS > 0` path by default.
- When enabled, mRLFE tracks on a denser internal frequency grid and resamples the branch back to the requested frequency grid.
- Internal tracking metadata is stored in `mrlfeResults.tracking` and in each branch under `branch.internalTracking`.
- Related tests protect the requested-grid output contract and the viscous internal-grid policy.

Current note:

The FitTool route now uses the atlas-first fitting evaluator. FitTool dense solver re-evaluation can still show grid/path sensitivity, so current fitting behavior is documented in:

```text
docs/models/mrlfe/fittool_grid_path_sensitivity.md
```

## mRLFE tracking quality summary status

Current status:

- `summarizeMRLFETrackingQuality` is the maintained analysis helper for comparing mRLFE branch quality across tracking strategies.
- `compareMRLFETrackingStrategies` is the maintained comparison helper for running direct and internal-grid strategies on the same mRLFE branch setup.
- The helpers accept full mRLFE result structs or individual branch structs and do not create files or figures.
- They report valid fraction, frequency span, Cp range, relative jumps, roughness, residual metrics, internal-grid usage, and a compact quality score.
- `tests/models/mrlfe/test_mrlfe_tracking_quality_summary.m` protects the summary helper contract.
- `tests/models/mrlfe/test_mrlfe_tracking_strategy_comparison.m` protects the direct/internal-grid comparison helper contract.
- `tests/models/mrlfe/test_mrlfe_internal_grid_quality_guard.m` protects that the viscous internal-grid policy does not degrade severely relative to direct tracking in a representative A0-like case.

Rationale:

These helpers provide a permanent way to compare direct tracking and internal-grid tracking without keeping temporary optimization scripts in the repository. The quality guard is intentionally tolerant: it is a regression guard against severe degradation, not a claim that internal-grid tracking is always superior.

## Solver optimization guardrail

Before changing branch tracking, objective functions, or internal grids, the maintained smoke suite must continue to pass:

```matlab
run_all_smoke_tests
```

Any temporary optimization script should either be deleted before merge or promoted to a maintained test/diagnostic with clear naming and documentation. Optimization-only artifacts should not remain in the repository after the selected solver strategy is finalized.

# Acoustoelastic IOP/HGO public API

The canonical acoustoelastic IOP/HGO API contains one production solver and
one production-default owner. Maintained consumers use these entrypoints.

The former author-specific compatibility layer and legacy branch-policy aliases have been removed. Do not add new compatibility wrappers or call removed names from active MATLAB code.

## Primary production solver entrypoint

```matlab
solveAcoustoelasticIOPHGOBranch
```

## Options

```matlab
defaultAcoustoelasticIOPHGOOptions
```

## Configuration ownership

```matlab
aeGetNumericalPreset
aeResolveConfiguration
aeValidateRequest
aeBuildInternalTrackingGrid
```

The preset owner, resolver, validator, and grid builder are maintained model
internals. App surface names and UI profile translation are owned by
`app/adapters/aeResolveExecutionProfile`.

## Result and quality ownership

```matlab
aeBuildResult
aeEvaluateAtlasA0Quality
```

These are maintained model internals. `aeBuildResult` is the sole constructor
for the maintained atlas result schema, and `aeEvaluateAtlasA0Quality` is the
sole owner of requested-grid reliability. Neither function performs branch
selection, tracking, interpolation, fallback decisions, or numerical solving.

## Production atlas, tracking, and policy ownership

```matlab
aeBuildAtlas
aeFindAtlasLocalMinima
aeLinkAtlasBranches
aeSplitAtlasBranches
aeSelectAtlasA0Branch
aeApplyAtlasA0FallbackPolicy
```

These are maintained model internals, not additional user-facing solver
routes. `aeBuildAtlas` owns only the configured grid and objective landscape.
The three tracking helpers own production minima, linking, and splitting.
`aeSelectAtlasA0Branch` owns the official low-start filters, score, tie-break,
and selection-fallback metadata. `aeApplyAtlasA0FallbackPolicy` owns only the
existing fallback rejection and diagnostic candidate retention; canonical
result and quality owners rebuild the public surfaces afterward.

Production tracking does not call the separate identity-A0, raw-branch,
modal-atlas, branch-family, or truncation diagnostic algorithms.

The maintained field classification is:

| Classification | Fields |
| --- | --- |
| Stable public result | `frequency`, `Cp`, `validCp`, `pointStatus`, `objective`, `nearestRank`, `nearestBranchID`, `selectedBranchID` |
| Stable public tracking metadata | `branchExistsAtFrequency`, `interpolatedCp`, `selectedBranch`, `selectedBranchPoints`, `requestedFrequency`, `internalAtlasTracking` |
| Stable public quality/reliability summary | `reliability` and all of its characterized fields |
| Stable diagnostics summary | `diagnostics` |
| Unstable internal/debug evidence retained in place | `minimaTable`, `branchTable`, `objectiveMap`, `trackingObjectiveMap`, `trackingFrequency`, `yGrid`, `cGrid`, `cShear`, `options`, `constitutiveState`, `directParams` |
| Diagnostic-only extension | `identityA0`; external `raw_branch1` and `branch_families` diagnostic products |
| Compatibility surface | `fallbackCandidateCp`, `fallbackCandidateValidCp`, `fallbackCandidateBranchExistsAtFrequency`, `fallbackCandidateInterpolatedCp`, `fallbackCandidatePointStatus` |

The unstable evidence remains top-level because moving it under a new
`result.debug` field would break the exact schema contract. Fallback candidate
fields remain until diagnostic and saved-result consumers no longer require
the rejected candidate evidence.

## Constitutive helpers

```matlab
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
solveAcoustoelasticHGOStretch
```

## Matrix, roots, and objectives

```matlab
buildAcoustoelasticMatrix
computeAcoustoelasticSRoots
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
```

## Sweep and analysis helpers

```matlab
aeRunSweep
aeSummarizeSweep
summarizeAcoustoelasticIOPHGOTrackingQuality
aePlotGridSweepCp
aeOutputFolder
aeResolveResultFile
aeDiagnoseAtlasA0TruncationCause
aeAnalyzeBranchPersistenceCandidates
aeAnalyzeFirstUnrecoveredBreak
aeClassifyTruncationRecovery
aeRefineAtlasA0BranchPersistence
aeClassifyAmbiguityRegime
aeExtractRawBranch1Candidate
aeComputeModalAtlasForCase
aeFindTopModalAtlasLocalMinima
aeLinkModalAtlasMinimaIntoBranches
aeDefaultIdentityA0ValidationParams
aeDefaultIdentityA0ValidationOptions
aeDefaultIdentityA0ValidationGrid
```

`aeExtractRawBranch1Candidate` is diagnostic infrastructure. It supports `track_raw_branch1` and `compare_atlasA0_vs_raw_branch1`; it does not promote `raw_branch1` to production output.

## Diagnostic model internals

```matlab
aeScoreBranchIdentityCandidates
aeBuildIdentityA0DiagnosticBranch
```

These functions live under `models/acoustoelastic_iop_hgo/diagnostics/` to
support explicit diagnostic requests without making model code depend on
`analysis/`. They remain diagnostic-only and never alter official `Cp`,
`validCp`, or `atlasA0` selection.

`aeComputeModalAtlasForCase`, `aeFindTopModalAtlasLocalMinima`, and `aeLinkModalAtlasMinimaIntoBranches` centralize modal-atlas diagnostic logic. `diagnose_modal_atlas` starts at low frequency by design.

`aeDefaultIdentityA0ValidationParams`, `aeDefaultIdentityA0ValidationOptions`, and `aeDefaultIdentityA0ValidationGrid` centralize the shared heavy-validation setup used by the two retained long validation implementations.

## Fitting helpers

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
```

The maintained fitting route uses the official `atlasA0` output only. Diagnostic branches such as `identityA0Diagnostic`, `raw_branch1`, and branch-family candidates are not accepted as fitting outputs.

Maintained Main GUI solving, SweepTool points, fitting evaluations, grid
sweeps, and the basic example all enter through
`solveAcoustoelasticIOPHGOBranch`. Direct atlas, real-Cp, and complex-C solvers
are retained internal diagnostics; they are not parallel production routes.

## Maintained public workflows

```matlab
run_atlas_branch
ae_sweep_iop_A0Like
ae_sweep_mu_A0Like
ae_sweep_thickness_A0Like
ae_sweep_k1_A0Like
ae_sweep_k2_A0Like
ae_sweep_radius_A0Like
ae_sweep_mu_iop_A0Like
```

## Maintained diagnostic evidence

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

## Repeatable diagnostics retained for scientific reproducibility

```matlab
diagnose_idA0_score
validate_idA0_grid
validate_idA0_score_grid
diagnose_modal_atlas
diagnose_grid_start_sensitivity
track_raw_branch1
```

## Maintained tests

```matlab
test_acoustoelastic_iop_hgo_branch_policy_validation
test_ae_configuration_characterization
test_ae_configuration_ownership
test_ae_final_architecture_contract
test_ae_result_file_compatibility
test_ae_result_schema_characterization
test_ae_result_ownership
test_ae_tracking_policy_characterization
test_ae_tracking_policy_ownership
test_acoustoelastic_iop_hgo_atlasA0_smoke
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_fallback_invalidation
test_acoustoelastic_iop_hgo_internal_tracking_grid
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
test_acoustoelastic_iop_hgo_short_entrypoints
test_acoustoelastic_iop_hgo_branch_persistence_refinement
test_ae_analyze_truncation_recovery
test_ae_fit_synthetic_atlasA0
test_ae_physical_sweep_examples_contract
```

## Maintained smoke runners

```matlab
run_acoustoelastic_smoke_tests
run_all_smoke_tests
run_fit_validation_tests
```

`run_acoustoelastic_smoke_tests` covers AE API/path contracts, the maintained physical-sweep source contract, and the AE atlasA0 fitting smoke test. `run_fit_validation_tests` covers focused synthetic fitting validation, including AE atlasA0 and AE hidden/fixed parameter cases.

## Policy for callers

- GUI code should call model APIs, not scripts in `examples/`.
- Maintained examples should use short task-oriented script names under `examples/acoustoelastic_iop_hgo/`.
- Active tests should validate author-neutral names only.
- The only maintained production atlas-A0 policy name is `"atlasA0"`.
- Removed compatibility and legacy branch-policy names are not part of the supported API.
- `identityA0Diagnostic`, `raw_branch1`, and `branch_families` are diagnostic-only and should not replace `result.Cp` or `result.validCp`.

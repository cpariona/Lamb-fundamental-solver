# Acoustoelastic IOP/HGO public API

The supported acoustoelastic IOP/HGO API is author-neutral. Maintained code, examples, tests, GUI callbacks, and analysis scripts should call the `Acoustoelastic` / `AcoustoelasticIOPHGO` entrypoints listed below.

The former author-specific compatibility layer and legacy branch-policy aliases have been removed. Do not add new compatibility wrappers or call removed names from active MATLAB code.

## Primary solver entrypoints

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
```

## Options

```matlab
defaultAcoustoelasticIOPHGOOptions
aeNormalizeBranchPolicy
```

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
aeOutputFolder
aeResolveResultFile
aeRunLegacyScript
aeScoreBranchIdentityCandidates
aeBuildIdentityA0DiagnosticBranch
aeDiagnoseAtlasA0TruncationCause
aeAnalyzeBranchPersistenceCandidates
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

`aeComputeModalAtlasForCase`, `aeFindTopModalAtlasLocalMinima`, and `aeLinkModalAtlasMinimaIntoBranches` centralize modal-atlas diagnostic logic. The maintained `diagnose_modal_atlas` entrypoint starts at low frequency by design, so no separate low-frequency modal-atlas entrypoint is maintained.

`aeDefaultIdentityA0ValidationParams`, `aeDefaultIdentityA0ValidationOptions`, and `aeDefaultIdentityA0ValidationGrid` centralize the shared heavy-validation setup used by `validate_idA0_grid` and `validate_idA0_score_grid`.

## Fitting helpers

```matlab
aeBuildFitProblem
aeEvaluateFitModel
aeFitDispersionData
```

The maintained fitting route uses the official `atlasA0` output only. Diagnostic branches such as `identityA0Diagnostic`, `raw_branch1`, and branch-family candidates are not accepted as fitting outputs.

## Maintained public workflows

```matlab
run_atlas_branch
sweep_iop
sweep_mu
sweep_mu_iop
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

## Historical diagnostics retained for traceability

```matlab
diagnose_idA0_score
validate_idA0_grid
validate_idA0_score_grid
diagnose_modal_atlas
diagnose_grid_start_sensitivity
track_raw_branch1
```

## Removed redundant entrypoints

```matlab
diagnose_modal_atlas_lowfreq
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas
```

The separate low-frequency modal-atlas entrypoints were removed because low-frequency initialization is now implicit in `diagnose_modal_atlas`.

## Maintained tests

```matlab
test_acoustoelastic_iop_hgo_branch_policy_validation
test_acoustoelastic_iop_hgo_atlasA0_smoke
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_fallback_invalidation
test_acoustoelastic_iop_hgo_internal_tracking_grid
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
test_acoustoelastic_iop_hgo_short_entrypoints
test_acoustoelastic_iop_hgo_branch_persistence_refinement
test_ae_analyze_truncation_recovery
test_ae_fit_synthetic_atlasA0
```

## Maintained smoke runners

```matlab
run_acoustoelastic_smoke_tests
run_all_smoke_tests
run_fit_validation_tests
```

`run_acoustoelastic_smoke_tests` covers AE API/path contracts and the maintained AE atlasA0 fitting smoke test. `run_fit_validation_tests` covers focused synthetic fitting validation, including AE atlasA0 and AE hidden/fixed parameter cases.

## Policy for callers

- GUI code should call model APIs, not scripts in `examples/`.
- Maintained examples should use short task-oriented script names under `examples/acoustoelastic_iop_hgo/`.
- Active tests should validate author-neutral names only.
- The only maintained production atlas-A0 policy name is `"atlasA0"`.
- Removed compatibility and legacy branch-policy names are not part of the supported API.
- `identityA0Diagnostic`, `raw_branch1`, and `branch_families` are diagnostic-only and should not replace `result.Cp` or `result.validCp`.

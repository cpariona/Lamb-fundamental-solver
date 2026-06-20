# Acoustoelastic IOP/HGO public API

The supported acoustoelastic IOP/HGO API is author-neutral. Maintained code, examples, tests, GUI callbacks, and analysis scripts should call the `Acoustoelastic` / `AcoustoelasticIOPHGO` entrypoints listed below.

The former author-specific compatibility layer has been removed. Do not add new compatibility wrappers or call removed author-specific names from active MATLAB code.

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
```

`aeExtractRawBranch1Candidate` is diagnostic infrastructure. It supports `track_raw_branch1` and `compare_atlasA0_vs_raw_branch1`; it does not promote `raw_branch1` to production output.

## Maintained public workflows

```matlab
run_atlas_branch
sweep_iop
sweep_mu
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
diagnose_modal_atlas_lowfreq
track_raw_branch1
```

## Maintained tests

```matlab
test_acoustoelastic_iop_hgo_branch_policy_aliases
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
test_acoustoelastic_iop_hgo_short_entrypoints
test_acoustoelastic_iop_hgo_branch_persistence_refinement
test_ae_analyze_truncation_recovery
```

## Policy for callers

- GUI code should call model APIs, not scripts in `examples/`.
- Maintained examples should use short task-oriented script names under `examples/acoustoelastic_iop_hgo/`.
- Active tests should validate author-neutral names only.
- The maintained atlas A0 policy name is `"atlasA0"`.
- The legacy policy name `"strictA0"` remains accepted as an alias.
- Removed compatibility names are not part of the supported API.
- `identityA0Diagnostic`, `raw_branch1`, and `branch_families` are diagnostic-only and should not replace `result.Cp` or `result.validCp`.

# Maintained entrypoints

This document lists the current maintained execution surface of the repository. Detailed acoustoelastic documentation is indexed in:

```text
docs/acoustoelastic_iop_hgo/documentation_index.md
```

## Setup

From the repository root:

```matlab
clear functions
rehash toolboxcache
startup
```

## Rayleigh-Lamb base solver

Maintained Rayleigh-Lamb implementation entrypoints use the `rl*` API:

```matlab
rlBuildFrequencyVector
rlComputeFundamentalLambModes
rlComputeGeometry
rlComputeMaterial
rlDefaultOptions
rlDefaultParams
rlMakeBranchSpec
rlValidateOptions
rlValidateParams
rlAResidual
rlSResidual
rlComputeA0ThinPlateApproximation
rlComputeAnalyticalApproximations
rlComputeS0ExtensionalApproximation
rlSolveFundamentalBranch
```

See:

```text
docs/rayleigh_lamb_public_api.md
docs/rayleigh_lamb_overview.md
```

## Acoustoelastic IOP/HGO model

Recommended solver/API entrypoints:

```matlab
solveAcoustoelasticIOPHGOBranch
solveAcoustoelasticIOPHGOAtlasBranch
solveAcoustoelasticAtlasBranch
solveAcoustoelasticIOPHGODispersion
solveAcoustoelasticDispersion
solveAcoustoelasticComplexCDispersion
objectiveAcoustoelasticResidual
objectiveAcoustoelasticComplexDeterminant
buildAcoustoelasticMatrix
defaultAcoustoelasticIOPHGOOptions
aeNormalizeBranchPolicy
computeAcoustoelasticABGFromIOPHGO
computeAcoustoelasticAlphaBetaGamma
computeAcoustoelasticPrestressSigma
computeAcoustoelasticSRoots
solveAcoustoelasticHGOStretch
summarizeAcoustoelasticIOPHGOTrackingQuality
aeRunSweep
aeSummarizeSweep
```

Recommended analysis helpers:

```matlab
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

Maintained public workflows:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
```

Maintained diagnostic evidence:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_idA0_plausibility
```

Historical diagnostics retained for traceability:

```matlab
diagnose_idA0_score
validate_idA0_grid
validate_idA0_score_grid
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
track_raw_branch1
```

Retained long implementation targets:

```matlab
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas
diagnose_acoustoelastic_iop_hgo_modal_atlas
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
validate_acoustoelastic_iop_hgo_branch_identity_score_grid
```

Notes:

```text
- atlasA0 is the only maintained production atlas-A0 branch policy.
- Legacy branch-policy aliases are not part of the maintained API.
- identityA0Diagnostic, raw_branch1, and branch_families are diagnostic-only.
- No exploratory example scripts remain as retained public or semi-public workflows.
- The previous raw-branch long implementation script has been replaced by aeExtractRawBranch1Candidate.
```

See:

```text
docs/acoustoelastic_iop_hgo_public_api.md
docs/acoustoelastic_iop_hgo_branch_policy.md
docs/acoustoelastic_iop_hgo_sweep_workflow.md
docs/acoustoelastic_iop_hgo/README.md
```

## mRLFE model

Main high-level function:

```matlab
computeMRLFE
```

Useful examples and diagnostics:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
sweep_mrlfe_shear_viscosity_phase_velocity
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
test_mrlfe_smoke
```

## Smoke-test scope

`run_all_smoke_tests` verifies maintained Rayleigh-Lamb checks, minimal Rayleigh-Lamb fixtures, author-neutral acoustoelastic IOP/HGO tests, and the mRLFE smoke test.

Recommended validation command:

```matlab
run_all_smoke_tests
```

## Active documentation links

Core repository docs:

```text
docs/repository_structure.md
docs/naming_strategy.md
docs/validation_status.md
docs/maintained_entrypoints.md
```

Rayleigh-Lamb docs:

```text
docs/rayleigh_lamb_overview.md
docs/rayleigh_lamb_public_api.md
```

Acoustoelastic docs:

```text
docs/acoustoelastic_iop_hgo_public_api.md
docs/acoustoelastic_iop_hgo_branch_policy.md
docs/acoustoelastic_iop_hgo_sweep_workflow.md
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
```

Other active docs:

```text
docs/parametric_sweeps.md
docs/mrlfe_tracker_diagnostic_summary.md
```

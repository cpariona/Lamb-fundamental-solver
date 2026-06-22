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

## GUI entrypoints

Maintained GUI launchers:

```matlab
runApp
LambFundamental_GUI
SweepTool_GUI
```

Maintained SweepTool helpers:

```matlab
guiGetSweepRegistry
guiBuildSweepRequest
guiRunSweep
guiPlotSweepResult
guiRunMRLFESweep
guiNormalizeMRLFESweep
guiRunRLSweep
guiNormalizeRLSweep
guiRunAcoustoelasticIOPHGOSweep
guiNormalizeAcoustoelasticIOPHGOSweep
```

See:

```text
docs/sweep_tool_usage.md
docs/gui_adapter_architecture.md
docs/gui_integration_audit.md
```

## Shared sweep helpers

Generic sweep helpers:

```matlab
runParametricSweep
plotParametricSweepCp
summarizeParametricSweepBranch
```

mRLFE sweep helpers:

```matlab
mrlfeDefaultSweepParams
mrlfeDefaultSweepOptions
mrlfeMakeSweepSpec
mrlfeRunSweepExample
```

Rayleigh-Lamb sweep helper:

```matlab
rlRunThicknessSweepExample
```

These helpers support short public examples. They should not change solver equations, branch policies, or numerical tracking behavior.

See:

```text
docs/parametric_sweeps.md
docs/mrlfe/sweep_refactor_status.md
docs/rayleigh_lamb/sweep_helper_status.md
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

Maintained Rayleigh-Lamb public/basic examples live under `examples/rayleigh_lamb/basic/`:

```matlab
run_default_A0
run_default_A0_S0
sweep_thickness_A0_S0
```

Maintained Rayleigh-Lamb validation scripts live under `examples/rayleigh_lamb/validation/`:

```matlab
check_default_outputs
```

See:

```text
docs/rayleigh_lamb/public_api.md
docs/rayleigh_lamb/overview.md
docs/rayleigh_lamb/sweep_helper_status.md
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
docs/acoustoelastic_iop_hgo/public_api.md
docs/acoustoelastic_iop_hgo/branch_policy.md
docs/acoustoelastic_iop_hgo/sweep_workflow.md
docs/acoustoelastic_iop_hgo/README.md
```

## mRLFE model

Main high-level function:

```matlab
computeMRLFE
```

Maintained public sweep wrappers:

```matlab
sweep_viscosity_A0Like_viscoelastic
sweep_viscosity_S0Like_viscoelastic
sweep_stiffness_A0Like_viscoelastic
sweep_stiffness_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Useful examples, diagnostics, and stress tests:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
sweep_mrlfe_shear_viscosity_phase_velocity
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
stress_test_mrlfe_elastic_range
stress_test_mrlfe_han_visco_range
test_mrlfe_smoke
```

See:

```text
docs/mrlfe/tracker_diagnostic_summary.md
docs/mrlfe/sweep_refactor_status.md
```

## Smoke-test scope

`run_all_smoke_tests` verifies maintained GUI adapter checks, Rayleigh-Lamb checks, minimal Rayleigh-Lamb fixtures, author-neutral acoustoelastic IOP/HGO tests, and the mRLFE smoke test.

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
docs/parametric_sweeps.md
docs/sweep_tool_usage.md
docs/gui_adapter_architecture.md
docs/gui_integration_audit.md
```

Rayleigh-Lamb docs:

```text
docs/rayleigh_lamb/overview.md
docs/rayleigh_lamb/public_api.md
docs/rayleigh_lamb/sweep_helper_status.md
```

mRLFE docs:

```text
docs/mrlfe/tracker_diagnostic_summary.md
docs/mrlfe/sweep_refactor_status.md
```

Acoustoelastic docs:

```text
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
docs/acoustoelastic_iop_hgo/public_api.md
docs/acoustoelastic_iop_hgo/branch_policy.md
docs/acoustoelastic_iop_hgo/sweep_workflow.md
```

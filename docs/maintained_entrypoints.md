# Maintained entrypoints

This document lists the current maintained execution surface of the repository.

## Setup

```matlab
clear functions
rehash toolboxcache
startup
```

## GUI entrypoints

```matlab
runApp
LambFundamental_GUI
SweepTool_GUI
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

## Shared sweep helpers

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
mrlfeOutputFolder
mrlfeWriteSweepOutputs
mrlfeSaveExampleFigure
```

Rayleigh-Lamb sweep helper:

```matlab
rlRunThicknessSweepExample
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

Maintained Rayleigh-Lamb examples:

```matlab
run_default_A0
run_default_A0_S0
sweep_thickness_A0_S0
check_default_outputs
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

## mRLFE model

Main high-level function:

```matlab
computeMRLFE
```

Maintained public sweep wrappers:

```matlab
sweep_mu_A0Like_viscoelastic
sweep_mu_S0Like_viscoelastic
sweep_etaS_A0Like_viscoelastic
sweep_etaS_S0Like_viscoelastic
sweep_thickness_A0Like_viscoelastic
sweep_thickness_S0Like_viscoelastic
```

Useful examples, diagnostics, and stress tests:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
stress_test_mrlfe_elastic_range
stress_test_mrlfe_han_visco_range
test_mrlfe_smoke
```

## Smoke-test scope

```matlab
run_all_smoke_tests
```

## Active documentation links

```text
docs/repository_structure.md
docs/naming_strategy.md
docs/validation_status.md
docs/maintained_entrypoints.md
docs/parametric_sweeps.md
docs/sweep_tool_usage.md
docs/gui_adapter_architecture.md
docs/gui_integration_audit.md
docs/rayleigh_lamb/overview.md
docs/rayleigh_lamb/public_api.md
docs/rayleigh_lamb/sweep_helper_status.md
docs/mrlfe/tracker_diagnostic_summary.md
docs/mrlfe/current_sweeps.md
docs/mrlfe/pending_cleanup.md
docs/acoustoelastic_iop_hgo/README.md
docs/acoustoelastic_iop_hgo/documentation_index.md
docs/acoustoelastic_iop_hgo/public_api.md
docs/acoustoelastic_iop_hgo/branch_policy.md
docs/acoustoelastic_iop_hgo/sweep_workflow.md
```

# Maintained entrypoints

This document lists the maintained solver, example, diagnostic, and test entrypoints after the Acoustoelastic IOP/HGO and mRLFE refactors.

## Setup

From the repository root, always run:

```matlab
clear functions
rehash toolboxcache
startup
```

## Acoustoelastic IOP/HGO model

Recommended author-neutral entrypoints for routine use:

```matlab
solveAcoustoelasticIOPHGOBranch
defaultAcoustoelasticIOPHGOOptions
run_acoustoelastic_iop_hgo_atlas_branch
diagnose_acoustoelastic_iop_hgo_branch_policy
test_acoustoelastic_iop_hgo_constitutive_identity
test_acoustoelastic_iop_hgo_strictA0_smoke
```

Compatibility/development entrypoints still available during the naming transition:

```matlab
solveDispersionIOPHGOAtlasBranch_Li2024
defaultLi2024AcoustoelasticOptions
run_li2024_IOP_HGO_A0_atlas_branch
diagnose_li2024_atlas_branch_policy
test_li2024_constitutive_identity
test_li2024_strictA0_smoke
```

Main model folders:

```text
models/acoustoelastic_iop_hgo/core/
models/acoustoelastic_iop_hgo/constitutive/
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
```

Maintained examples:

```text
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/sweeps/
examples/acoustoelastic_iop_hgo/diagnostics/
```

Maintained tests:

```text
tests/acoustoelastic_iop_hgo/
```

## mRLFE model

Main high-level function:

```matlab
computeMRLFE
```

Main model folders:

```text
models/mrlfe/core/
models/mrlfe/solvers/
models/mrlfe/options/
```

Maintained examples:

```text
examples/mrlfe/basic/
examples/mrlfe/sweeps/
examples/mrlfe/diagnostics/
```

Useful examples:

```matlab
run_mrlfe_prototype
compare_mrlfe_elastic_vs_han_visco_cp
sweep_mrlfe_shear_viscosity_phase_velocity
```

Useful diagnostics:

```matlab
diagnose_mrlfe_han_visco_validity_breakdown
diagnose_mrlfe_han_visco_residual_landscape
compare_mrlfe_tracker_vs_condition_peaks
```

Maintained test:

```matlab
test_mrlfe_smoke
```

## Full manual test sequence

```matlab
clear functions
rehash toolboxcache
startup

run_all_smoke_tests
```

## Path check sequence

```matlab
which solveAcoustoelasticIOPHGOBranch
which defaultAcoustoelasticIOPHGOOptions
which run_acoustoelastic_iop_hgo_atlas_branch
which diagnose_acoustoelastic_iop_hgo_branch_policy
which test_acoustoelastic_iop_hgo_constitutive_identity
which test_acoustoelastic_iop_hgo_strictA0_smoke
which computeMRLFE
which defaultMRLFEParams
which diagnose_mrlfe_han_visco_residual_landscape
```

Expected folders:

```text
models/acoustoelastic_iop_hgo/solvers/
models/acoustoelastic_iop_hgo/options/
examples/acoustoelastic_iop_hgo/basic/
examples/acoustoelastic_iop_hgo/diagnostics/
tests/acoustoelastic_iop_hgo/
models/mrlfe/solvers/
models/mrlfe/options/
examples/mrlfe/diagnostics/
```

## Naming transition

The current naming transition is documented in:

```text
docs/naming_transition.md
```

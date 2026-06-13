# Maintained entrypoints

This document lists the maintained solver, example, and test entrypoints after the Acoustoelastic IOP/HGO and mRLFE refactors.

## Setup

From the repository root, always run:

```matlab
clear functions
rehash toolboxcache
startup
```

## Acoustoelastic IOP/HGO model

Main high-level solver:

```matlab
solveDispersionIOPHGOAtlasBranch_Li2024
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

Useful diagnostic:

```matlab
diagnose_li2024_atlas_branch_policy
```

Maintained tests:

```matlab
test_li2024_constitutive_identity
test_li2024_strictA0_smoke
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

test_li2024_constitutive_identity
test_li2024_strictA0_smoke
test_mrlfe_smoke
```

## Path check sequence

```matlab
which solveDispersionIOPHGOAtlasBranch_Li2024
which computeMRLFE
which defaultMRLFEParams
which diagnose_li2024_atlas_branch_policy
which diagnose_mrlfe_han_visco_residual_landscape
```

Expected folders:

```text
models/acoustoelastic_iop_hgo/solvers/
models/mrlfe/solvers/
models/mrlfe/options/
examples/acoustoelastic_iop_hgo/diagnostics/
examples/mrlfe/diagnostics/
```

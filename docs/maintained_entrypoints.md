# Maintained entrypoints

This document lists the maintained solver, example, and test entrypoints after the Li 2024 and mRLFE refactors.

## Setup

From the repository root, always run:

```matlab
clear functions
rehash toolboxcache
startup
```

## Li 2024 acoustoelastic model

Main high-level solver:

```matlab
solveDispersionIOPHGOAtlasBranch_Li2024
```

Main model folders:

```text
models/li2024_acoustoelastic/core/
models/li2024_acoustoelastic/constitutive/
models/li2024_acoustoelastic/solvers/
models/li2024_acoustoelastic/options/
```

Maintained examples:

```text
examples/li2024/basic/
examples/li2024/sweeps/
examples/li2024/diagnostics/
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
models/li2024_acoustoelastic/solvers/
models/mrlfe/solvers/
models/mrlfe/options/
examples/li2024/diagnostics/
examples/mrlfe/diagnostics/
```

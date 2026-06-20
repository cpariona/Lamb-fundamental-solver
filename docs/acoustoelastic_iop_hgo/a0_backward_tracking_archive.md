### A0 backward tracking exploratory archive

This document preserves the purpose and conclusions of the exploratory A0-backward and tracking diagnostics used during early acoustoelastic IOP/HGO solver development.

### Scope

Archived exploratory group E2:

```text
run_acoustoelastic_iop_hgo_A0_backward.m
sweep_acoustoelastic_iop_hgo_A0_backward.m
compare_acoustoelastic_iop_hgo_tracking_strategies.m
diagnose_acoustoelastic_iop_hgo_grid_convergence.m
```

These scripts were not maintained public workflows. They were exploratory checks used before the current `atlasA0` policy and short workflow layer were established.

### Why these diagnostics existed

The early solver workflow tested the following branch-selection idea:

```text
corrected M54
  -> A0 branch
  -> backward tracking direction
  -> globalScan tracker
```

The goal was to determine whether the A0-like branch could be recovered using a direct real-Cp tracker and whether the resulting branch behaved plausibly under changes in IOP.

### Preserved conclusions

#### A0 backward single-case example

The A0 backward example demonstrated the full IOP/HGO path:

```text
IOP, R, thickness, mu, k1, k2
  -> lambda
  -> alpha, beta, gamma
  -> corrected M54 matrix
  -> A0 branch
  -> backward global scan
```

Preserved conclusion:

```text
The corrected-M54 A0 backward global-scan route was a useful early diagnostic route, but it has been superseded as a routine workflow by run_atlas_branch and the atlasA0 policy.
```

Routine replacement:

```matlab
run_atlas_branch
```

#### A0 backward IOP sweep

The A0 backward sweep tested whether the early A0 backward route produced physically plausible trends across IOP values.

Preserved conclusion:

```text
The sweep was useful for checking qualitative IOP sensitivity and the constitutive relationship between sigma, lambda, alpha, beta, and gamma. Routine sweep work is now handled by sweep_iop and sweep_mu, which use the maintained sweep adapter and short output paths.
```

Routine replacements:

```matlab
sweep_iop
sweep_mu
```

#### Tracking strategy comparison

The tracking-strategy comparison evaluated multiple candidate numerical routes:

```text
globalScan
predictiveContinuation
singularVectorTracking
A0High reference
complex-C determinant continuation as an experimental diagnostic
```

Preserved conclusion:

```text
Tracking choice cannot be justified by visual smoothness alone. The residual landscape contains competing minima and branch families, so branch policy must be conservative and explicitly documented.
```

This conclusion is now represented by retained diagnostics and docs:

```matlab
diagnose_sweep_reliability
diagnose_atlas_truncation
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
diagnose_branch_families
compare_atlasA0_vs_raw_branch1
```

#### Grid-convergence and branch-map diagnostic

The grid-convergence diagnostic tested whether selected Cp values depended strongly on Cp-grid density and whether the tracker jumped between solution families.

It inspected:

```text
Cp at a reference frequency
local minima at a reference frequency
full f-Cp branch maps for selected IOP cases
tracked rank over frequency
constitutive alpha/beta/gamma checks
```

Preserved conclusion:

```text
Increasing Cp-grid density alone is not enough to remove modal ambiguity. The hard cases are branch-selection and modal-family problems, not only scan-resolution problems.
```

Current retained diagnostics with stronger coverage:

```matlab
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
diagnose_branch_families
diagnose_raw_branch_corner
validate_atlas_raw_grid
```

### Relation to official solver policy

The official production policy remains:

```text
atlasA0 = conservative official output
```

The archived E2 diagnostics do not define official output and do not modify:

```matlab
result.Cp
result.validCp
```

They also do not promote:

```text
A0 backward globalScan
A0High
predictiveContinuation
singularVectorTracking
complex-C continuation
```

into official branch policies.

### Why executable scripts can be archived

These diagnostics can be archived because:

```text
1. They are not maintained public workflows.
2. They are not called by tests or maintained short entrypoints.
3. Their conclusions are preserved here.
4. Current maintained workflows use run_atlas_branch, sweep_iop, and sweep_mu.
5. Current maintained diagnostics provide stronger evidence for branch ambiguity and atlasA0 truncation behavior.
```

### Required validation after archival

After removing the executable E2 scripts, run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

Because the removed scripts are exploratory and not part of the smoke-test surface, no numerical behavior should change.

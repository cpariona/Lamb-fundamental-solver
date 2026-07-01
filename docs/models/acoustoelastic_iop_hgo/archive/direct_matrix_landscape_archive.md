### Direct matrix and residual-landscape exploratory archive

This document preserves the purpose and conclusions of the exploratory direct-matrix diagnostics that were used during acoustoelastic IOP/HGO solver development.

### Scope

Archived exploratory group:

```text
run_acoustoelastic_iop_hgo_direct_alpha_beta_gamma.m
diagnose_acoustoelastic_iop_hgo_matrix_variants.m
diagnose_acoustoelastic_iop_hgo_dimensionless_A1.m
diagnose_acoustoelastic_iop_hgo_residual_landscape.m
```

These scripts were not maintained public workflows. They were exploratory checks used to isolate the direct acoustoelastic matrix problem from the full IOP/HGO constitutive pipeline.

### Why these diagnostics existed

The full acoustoelastic IOP/HGO workflow combines several layers:

```text
IOP, R, thickness, mu, k1, k2
  -> HGO stretch/prestress solve
  -> alpha, beta, gamma
  -> acoustoelastic characteristic matrix
  -> dispersion residual landscape
  -> branch selection / tracking
```

The direct matrix diagnostics intentionally removed the first layer and prescribed:

```text
alpha
beta
gamma
thickness
rho
rhoF
fluidBulkModulus
frequency
```

This allowed early testing of the characteristic matrix and branch landscape before attributing behavior to the HGO prestress model.

### Preserved conclusions

#### Direct alpha-beta-gamma solver check

The direct alpha-beta-gamma example verified that the direct matrix solver could be exercised independently from the IOP/HGO constitutive block.

Preserved conclusion:

```text
The direct solver path is useful for isolating matrix/dispersion behavior from constitutive prestress behavior, but it is not the maintained user-facing workflow for IOP/HGO sweeps.
```

Maintained replacement for routine use:

```matlab
run_atlas_branch
sweep_iop
sweep_mu
```

#### M54 matrix-variant diagnostic

The M54 diagnostic compared the paper-reported matrix entry against the corrected variant used by the current solver options.

The original exploratory note was:

```text
The paper reports M54 = s2*(s1^2 + 1)*cosh(s1*k*h).
Based on the modal solution term B4*sinh(s2*k*x3), a corrected variant with cosh(s2*k*h) was also evaluated.
```

Preserved conclusion:

```text
The codebase retains M54_variant as an explicit option. Maintained workflows currently use the corrected variant, while the paper variant remains available as a controlled model option for traceability.
```

Relevant retained implementation/configuration points:

```text
models/acoustoelastic_iop_hgo/core/buildAcoustoelasticMatrix.m
models/acoustoelastic_iop_hgo/options/defaultAcoustoelasticIOPHGOOptions.m
```

#### Dimensionless A1-style diagnostic

The dimensionless A1-style diagnostic used:

```text
x = f*h/sqrt(alpha/rho)
y = c/sqrt(alpha/rho)
```

It was used to inspect the shape of the direct solver branches in a dimensionless form inspired by an Appendix-A1-style reference plot.

Preserved conclusion:

```text
Dimensionless scaling is useful for checking branch-shape plausibility in the direct matrix problem, but it is not a maintained production workflow and does not define the official atlasA0 branch.
```

#### Residual-landscape diagnostic

The residual-landscape diagnostic scanned:

```text
log10(sigma_min(M))
```

as a function of dimensionless phase velocity:

```text
y = c/sqrt(alpha/rho)
```

at selected dimensionless frequencies:

```text
x = f*h/sqrt(alpha/rho)
```

Preserved conclusion:

```text
The direct matrix residual contains multiple local minima and branch families. This supports the later decision to treat branch selection as a modal-ambiguity problem rather than as a simple single-minimum root search.
```

Current maintained diagnostics that supersede this exploratory reasoning:

```matlab
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
diagnose_branch_families
diagnose_raw_branch_corner
compare_atlasA0_vs_raw_branch1
```

### Relation to official solver policy

The official production policy remains:

```text
atlasA0 = conservative official output
```

The archived E1 diagnostics do not modify or promote:

```matlab
result.Cp
result.validCp
```

They also do not promote:

```text
identityA0Diagnostic
raw_branch1
complex-C continuation
threshold-relaxed continuation
```

into official outputs.

### Why executable scripts can be archived

These diagnostics can be archived because:

```text
1. They are not maintained public workflows.
2. They are not called by tests or maintained short entrypoints.
3. Their purpose and conclusions are preserved here.
4. Current maintained modal-atlas and branch-family diagnostics provide better evidence for the same ambiguity class.
5. The underlying solver/model options remain in the model implementation.
```

### Required validation after archival

After removing the executable E1 scripts, run:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

Because the removed scripts are exploratory and not part of the smoke-test surface, no numerical behavior should change.

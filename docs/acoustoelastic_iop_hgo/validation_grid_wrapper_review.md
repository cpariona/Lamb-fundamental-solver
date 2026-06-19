### Validation grid wrapper review

This document reviews the two validation-grid wrappers:

```text
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_grid.m
examples/acoustoelastic_iop_hgo/diagnostics/validate_idA0_score_grid.m
```

### Current wrapper targets

```text
validate_idA0_grid.m
  -> validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid.m

validate_idA0_score_grid.m
  -> validate_acoustoelastic_iop_hgo_branch_identity_score_grid.m
```

Both targets exist.

### Output-path status

Both validation implementations already use clean output helpers.

```matlab
outputFolder = aeOutputFolder(launchFolder, 'idA0_grid');
outputFolder = aeOutputFolder(launchFolder, 'idA0_score_grid');
```

Expected output folders:

```text
Results/ae_iop_hgo/idA0_grid
Results/ae_iop_hgo/idA0_score_grid
```

No `aeCopyLegacyResultFolder` bridge is required.

### Numerical and diagnostic scope

`validate_idA0_grid` runs a large grid over IOP, shear modulus, HGO fiber parameters, and thickness. It verifies that `identityA0Diagnostic` does not modify official `result.Cp` or `result.validCp`, while collecting diagnostic candidate information.

`validate_idA0_score_grid` runs a comparable grid for branch-identity scoring. It evaluates best candidate scores and summarizes cases where scoring finds diagnostic candidates.

Both diagnostics are heavy validation workflows rather than lightweight entrypoint smoke tests.

### Cleanup decision

Do not consolidate these two wrappers mechanically in the current pass.

Reason:

```text
The wrappers are safe and targets are clean.
The implementations are long and computationally heavy.
Direct conversion would reduce one wrapper layer but would not fix a real path or target defect.
```

Current classification:

```text
validate_idA0_grid.m
  KEEP_AS_WRAPPER
  Target exists and writes directly to the short result tree.

validate_idA0_score_grid.m
  KEEP_AS_WRAPPER
  Target exists and writes directly to the short result tree.
```

### Future optional cleanup

A later low-risk cleanup may fully invert these files if desired:

```text
1. Copy the long implementation body into the corresponding short entrypoint.
2. Convert the long descriptive files into aliases toward the short entrypoints.
3. Run both validation grids in MATLAB before committing.
```

This is optional, not required for structural correctness.

### Required checks if modified

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
validate_idA0_grid
validate_idA0_score_grid
```

Because these diagnostics are heavy, they should only be executed after an intentional modification to their implementation path.

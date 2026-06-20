### Modal atlas wrapper review

This document reviews the two modal-atlas wrapper patterns:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
```

### Current status

A focused cleanup has been applied to the standard modal-atlas entrypoint and validated by user-reported local MATLAB execution.

```text
diagnose_modal_atlas.m
  now delegates directly to the descriptive implementation;
  no longer creates or patches a temporary copy;
  writes to Results/ae_iop_hgo/modal_atlas through the migrated implementation;
  user-reported MATLAB execution passed.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  remains the descriptive implementation file;
  now writes directly to Results/ae_iop_hgo/modal_atlas through aeOutputFolder;
  is not production solver code.

diagnose_modal_atlas_lowfreq.m
  still runs a temporary copy of the low-frequency legacy implementation;
  redirects output to Results/ae_iop_hgo/modal_atlas_lowfreq;
  keeps interactive plotting disabled for routine execution;
  validates that the expected plotting and output-folder lines exist before patching;
  no longer calls aeCopyLegacyResultFolder;
  user-reported MATLAB execution passed after removing external state dependence.
```

This eliminates the temporary-copy output-patch bridge for `diagnose_modal_atlas`, while leaving the separate low-frequency wrapper pattern untouched until it can be reviewed and executed independently.

### Current pattern

```text
diagnose_modal_atlas
  -> diagnose_acoustoelastic_iop_hgo_modal_atlas
  -> Results/ae_iop_hgo/modal_atlas

diagnose_modal_atlas_lowfreq
  -> patched temporary copy of diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas
  -> Results/ae_iop_hgo/modal_atlas_lowfreq
```

### Remaining structural issue

Only the low-frequency modal-atlas entrypoint still executes a patched temporary copy of a long implementation script.

Target architecture for the remaining low-frequency case:

```text
short entrypoint -> direct descriptive implementation -> Results/ae_iop_hgo/modal_atlas_lowfreq
```

A full inversion where the short entrypoint owns the entire implementation body remains optional and is not required for structural correctness.

### Numerical logic

Both modal-atlas diagnostics remain diagnostic-only. They compute:

```text
objective maps over frequency and dimensionless phase-speed grids;
local minima per frequency;
branch linking across frequency;
condition summaries;
tracker overlays or low-frequency candidate summaries.
```

They call the shared model/solver layer through:

```matlab
computeAcoustoelasticABGFromIOPHGO
objectiveAcoustoelasticResidual
solveAcoustoelasticIOPHGODispersion
```

No solver/model code was changed in the wrapper cleanup.

### Remaining recommended cleanup

A later focused pass may simplify the low-frequency wrapper:

```text
1. Run dependency searches for diagnose_modal_atlas_lowfreq and diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.
2. Move the short output-folder assignment and noninteractive plotting setting directly into the low-frequency descriptive implementation if safe.
3. Simplify diagnose_modal_atlas_lowfreq.m so it delegates without temporary patching.
4. Run diagnose_modal_atlas_lowfreq in MATLAB before committing.
```

Do not delete either low-frequency file in the same pass.

### Required tests

Minimum path test:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

Because this cleanup area touches executable modal-atlas wrappers, run the relevant diagnostic after modifying it:

```matlab
diagnose_modal_atlas
```

For future low-frequency wrapper changes, also run:

```matlab
diagnose_modal_atlas_lowfreq
```

Expected behavior:

```text
Results/ae_iop_hgo/modal_atlas
Results/ae_iop_hgo/modal_atlas_lowfreq
```

should be produced directly by the maintained short entrypoints. Legacy output folders should not be required for routine short-entrypoint execution.

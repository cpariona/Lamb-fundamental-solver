### Modal atlas wrapper review

This document reviews the two modal-atlas wrapper patterns:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
```

### Current status

Focused cleanup has been applied to both maintained modal-atlas entrypoints and validated by user-reported local MATLAB execution.

```text
diagnose_modal_atlas.m
  delegates directly to the descriptive implementation;
  no longer creates or patches a temporary copy;
  preserves the MATLAB launch folder for output placement;
  writes to Results/ae_iop_hgo/modal_atlas through the migrated implementation;
  user-reported MATLAB execution passed.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  remains the descriptive implementation file;
  writes directly to Results/ae_iop_hgo/modal_atlas through aeOutputFolder;
  is not production solver code.

diagnose_modal_atlas_lowfreq.m
  delegates directly to the descriptive low-frequency implementation;
  no longer creates or patches a temporary copy;
  preserves the MATLAB launch folder for output placement;
  writes to Results/ae_iop_hgo/modal_atlas_lowfreq through the migrated implementation;
  user-reported MATLAB execution passed.

diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
  remains the descriptive low-frequency implementation file;
  writes directly to Results/ae_iop_hgo/modal_atlas_lowfreq through aeOutputFolder;
  keeps routine interactive plotting disabled;
  is not production solver code.
```

This closes the temporary-copy output-patch bridge for both maintained modal-atlas short entrypoints.

### Current pattern

```text
diagnose_modal_atlas
  -> diagnose_acoustoelastic_iop_hgo_modal_atlas
  -> Results/ae_iop_hgo/modal_atlas

diagnose_modal_atlas_lowfreq
  -> diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas
  -> Results/ae_iop_hgo/modal_atlas_lowfreq
```

Both paths preserve the MATLAB launch folder, so outputs are written relative to the user's active working directory rather than relative to the repository or the diagnostics script folder.

### Remaining structural issue

No modal-atlas short entrypoint currently requires temporary-copy patching.

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

### Required tests

Minimum path test:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

Because this cleanup area touches executable modal-atlas wrappers, run:

```matlab
diagnose_modal_atlas
diagnose_modal_atlas_lowfreq
```

Expected behavior:

```text
Results/ae_iop_hgo/modal_atlas
Results/ae_iop_hgo/modal_atlas_lowfreq
```

should be produced under the user's MATLAB launch folder. Legacy output folders should not be required for routine short-entrypoint execution.

### Current conclusion

The modal-atlas wrapper cleanup is closed. Remaining cleanup should move to the broader wrapper inventory, retained compatibility aliases, and legacy-script classification.

### Modal atlas wrapper review

This document reviews the consolidated modal-atlas wrapper pattern:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
```

### Current status

The modal-atlas entrypoint has been consolidated and validated by user-reported local MATLAB execution.

```text
diagnose_modal_atlas.m
  delegates through aeRunLegacyScript to the descriptive implementation;
  preserves the MATLAB launch folder for output placement;
  writes to Results/ae_iop_hgo/modal_atlas;
  starts at low frequency by design;
  user-reported MATLAB execution passed.

diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  remains the descriptive implementation file;
  writes directly to Results/ae_iop_hgo/modal_atlas through aeOutputFolder;
  uses shared modal-atlas helpers under analysis/acoustoelastic_iop_hgo/;
  is not production solver code.
```

The separate low-frequency wrapper and implementation were removed:

```text
diagnose_modal_atlas_lowfreq.m
diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
```

Reason:

```text
Low-frequency initialization is now implicit in diagnose_modal_atlas.
Maintaining two modal-atlas diagnostics was redundant and increased downstream dependency ambiguity.
```

### Current pattern

```text
diagnose_modal_atlas
  -> diagnose_acoustoelastic_iop_hgo_modal_atlas
  -> Results/ae_iop_hgo/modal_atlas
```

The path preserves the MATLAB launch folder, so outputs are written relative to the user's active working directory rather than relative to the repository or the diagnostics script folder.

### Numerical logic

The consolidated modal-atlas diagnostic remains diagnostic-only. It computes:

```text
objective maps over low-frequency-to-high-frequency and dimensionless phase-speed grids;
local minima per frequency;
branch linking across frequency;
condition summaries;
tracker overlays and low-frequency candidate summaries.
```

It calls the shared model/solver layer through:

```matlab
computeAcoustoelasticABGFromIOPHGO
objectiveAcoustoelasticResidual
solveAcoustoelasticIOPHGODispersion
```

Shared modal-atlas infrastructure now lives in:

```matlab
aeComputeModalAtlasForCase
aeFindTopModalAtlasLocalMinima
aeLinkModalAtlasMinimaIntoBranches
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
```

Expected behavior:

```text
Results/ae_iop_hgo/modal_atlas
```

should be produced under the user's MATLAB launch folder.

### Current conclusion

The modal-atlas wrapper cleanup is closed. Remaining cleanup should move to the broader wrapper inventory, retained validation wrappers, and solver-interface consistency checks.

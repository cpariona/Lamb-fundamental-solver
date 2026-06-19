### Modal atlas wrapper review

This document reviews the two modal-atlas wrappers:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
```

### Current status after partial cleanup

A conservative partial cleanup has been applied.

```text
diagnose_modal_atlas.m
  runs a temporary copy of the legacy implementation;
  redirects output to Results/ae_iop_hgo/modal_atlas;
  no longer calls aeCopyLegacyResultFolder.

diagnose_modal_atlas_lowfreq.m
  runs a temporary copy of the legacy implementation;
  redirects output to Results/ae_iop_hgo/modal_atlas_lowfreq;
  keeps interactive plotting disabled for routine execution;
  validates that the expected plotting and output-folder lines exist before patching;
  no longer calls aeCopyLegacyResultFolder.
```

This eliminates the normal short-entrypoint dependence on duplicated legacy output folders, while avoiding a risky manual copy of several hundred lines of diagnostic implementation code.

### Remaining structural issue

The short entrypoints still execute temporary copies of the long implementation scripts.

Current pattern:

```text
short entrypoint -> patched temporary copy of legacy implementation -> Results/ae_iop_hgo/<task>
```

Target architecture:

```text
short entrypoint -> direct maintained implementation -> Results/ae_iop_hgo/<task>
legacy descriptive script -> alias to short entrypoint
```

The current state is therefore cleaner than the previous bridge, but not a full inversion of ownership.

### Why full inversion was deferred

The modal-atlas implementations are long diagnostic scripts with nested helper functions. A direct inversion would require copying hundreds of lines into the short entrypoints and turning the legacy files into aliases.

That operation is mechanically possible, but risky without MATLAB execution because small copy errors in nested functions would be hard to detect through static review alone.

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

No solver/model code was changed in the partial cleanup.

### Remaining recommended cleanup

A later focused pass may fully invert these files:

```text
1. Copy the long implementation body into the corresponding short entrypoint.
2. Replace legacy output filenames with short output filenames directly.
3. Keep the low-frequency plot control as an explicit makeInteractivePlots variable.
4. Convert the long descriptive scripts into aliases toward the short entrypoints.
5. Run the two modal-atlas diagnostics in MATLAB before committing.
```

Do not delete either legacy file in the same pass.

### Required tests

Minimum path test:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

Because this pass touches executable modal-atlas wrappers, run:

```matlab
diagnose_modal_atlas
```

and, if runtime is acceptable:

```matlab
diagnose_modal_atlas_lowfreq
```

Expected behavior:

```text
Results/ae_iop_hgo/modal_atlas
Results/ae_iop_hgo/modal_atlas_lowfreq
```

should be produced directly by the short entrypoints. Legacy output folders should not be required for routine short-entrypoint execution.

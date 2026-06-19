### Modal atlas wrapper review

This document reviews the two remaining modal-atlas wrappers:

```text
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas.m
examples/acoustoelastic_iop_hgo/diagnostics/diagnose_modal_atlas_lowfreq.m
```

### Current execution model

#### diagnose_modal_atlas

Current short entrypoint:

```matlab
launchFolder = pwd;
thisFile = mfilename('fullpath');
thisFolder = fileparts(thisFile);
scriptPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_modal_atlas.m');
aeRunLegacyScript(scriptPath);
aeCopyLegacyResultFolder(launchFolder, ...
    'acoustoelastic_iop_hgo_modal_atlas', ...
    'modal_atlas', ...
    'acoustoelastic_iop_hgo_modal_atlas', ...
    'modal_atlas');
```

Interpretation:

```text
1. The short entrypoint runs the long legacy script through aeRunLegacyScript.
2. The legacy script writes to Results/acoustoelastic_iop_hgo_modal_atlas.
3. The short entrypoint then copies and renames files into Results/ae_iop_hgo/modal_atlas.
```

This is a compatibility bridge, not a clean maintained implementation.

#### diagnose_modal_atlas_lowfreq

Current short entrypoint:

```matlab
legacyPath = fullfile(thisFolder, 'diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m');
sourceText = fileread(legacyPath);
sourceText = strrep(sourceText, ...
    '        plotLowFrequencyAtlasCase(atlas, condition);', ...
    '        % plotLowFrequencyAtlasCase(atlas, condition); % disabled by short wrapper');
shortScript = fullfile(tempdir, 'ae_iop_hgo_lowfreq_atlas_noplot.m');
writeTemporaryScript(shortScript, launchFolder, sourceText);
run(shortScript);
aeCopyLegacyResultFolder(...);
```

Interpretation:

```text
1. The short entrypoint reads the long legacy script as text.
2. It comments out one plotting call by exact string replacement.
3. It writes a temporary no-plot script.
4. It runs the temporary copy.
5. It copies legacy result files into the short result tree.
```

This is more fragile than a normal wrapper because behavior depends on exact source-text matching.

### Current output behavior

The long modal-atlas scripts still write first to legacy output folders.

```text
Results/acoustoelastic_iop_hgo_modal_atlas
Results/acoustoelastic_iop_hgo_low_frequency_modal_atlas
```

The short wrappers then copy files to:

```text
Results/ae_iop_hgo/modal_atlas
Results/ae_iop_hgo/modal_atlas_lowfreq
```

This preserves backwards compatibility but leaves duplicated output folders.

### Numerical logic

Both legacy modal-atlas scripts contain their own diagnostic implementations.

They compute:

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

The review did not identify evidence that these wrappers mutate official production output fields. These diagnostics are independent exploratory analyses and are not production `atlasA0` outputs.

### Main cleanup issue

The problem is not numerical correctness. The problem is structural:

```text
short entrypoint -> temporary/legacy execution -> legacy output path -> copy to short output path
```

This is the opposite of the target architecture:

```text
short entrypoint -> maintained implementation -> Results/ae_iop_hgo/<task>
legacy alias -> short entrypoint
```

### Risks of immediate mechanical conversion

A broad mechanical conversion is possible but should not be done blindly because:

1. `diagnose_modal_atlas_lowfreq` intentionally disables interactive plotting by editing a temporary copy.
2. The low-frequency legacy script explicitly says it saves data only and does not save figures, while figures are generated for interactive inspection.
3. Changing the plotting path may affect user experience even if numerical outputs are unchanged.
4. Both scripts are long and contain nested helper functions.
5. Output filenames would change if `aeCopyLegacyResultFolder` behavior is not reproduced carefully.

### Recommended cleanup strategy

Handle modal atlas as a focused pass, not as part of a broad wrapper sweep.

#### Step 1: introduce explicit plotting control

Add a local flag in the short maintained implementation:

```matlab
makeInteractivePlots = true;
```

For the low-frequency entrypoint, set:

```matlab
makeInteractivePlots = false;
```

Then replace the current text-replacement behavior with a normal conditional:

```matlab
if makeInteractivePlots
    plotLowFrequencyAtlasCase(atlas, condition);
end
```

This avoids source-text mutation.

#### Step 2: write directly to short output folders

Replace legacy output construction:

```matlab
outputFolder = fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_modal_atlas');
```

with:

```matlab
launchFolder = pwd;
outputFolder = aeOutputFolder(launchFolder, 'modal_atlas');
```

and similarly:

```matlab
outputFolder = aeOutputFolder(launchFolder, 'modal_atlas_lowfreq');
```

#### Step 3: use short output filenames directly

The copy helper currently renames long file prefixes. A clean implementation should write short names directly, for example:

```text
modal_atlas_minima.csv
modal_atlas_branches.csv
modal_atlas_tracker_matches.csv
modal_atlas_condition_summary.csv
modal_atlas_workspace.mat

modal_atlas_lowfreq_minima.csv
modal_atlas_lowfreq_branches.csv
modal_atlas_lowfreq_condition_summary.csv
modal_atlas_lowfreq_workspace.mat
```

#### Step 4: invert aliases

After the short entrypoints become direct maintained implementations:

```text
diagnose_acoustoelastic_iop_hgo_modal_atlas.m
  -> legacy alias to diagnose_modal_atlas

diagnose_acoustoelastic_iop_hgo_low_frequency_modal_atlas.m
  -> legacy alias to diagnose_modal_atlas_lowfreq
```

Do not delete either legacy file in the same pass.

### Recommended tests

Minimum path test:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

Functional tests are expensive. Run only if the modal-atlas pass touches the actual implementation:

```matlab
diagnose_modal_atlas
```

For low-frequency atlas:

```matlab
diagnose_modal_atlas_lowfreq
```

Expected behavior after cleanup:

```text
1. no Results/acoustoelastic_iop_hgo_modal_atlas folder is required for normal short-entrypoint execution;
2. no Results/acoustoelastic_iop_hgo_low_frequency_modal_atlas folder is required for normal short-entrypoint execution;
3. no aeCopyLegacyResultFolder call is needed in either short entrypoint;
4. low-frequency no-plot behavior is controlled by a variable, not by source-text replacement;
5. legacy descriptive scripts remain callable as aliases.
```

### Decision

Do not consolidate these two wrappers through a broad mechanical patch.

Recommended next action:

```text
Create a focused patch that only touches the two modal-atlas short entrypoints and their two legacy aliases.
Do not touch shared solver/model code.
Do not change modal-atlas numerical formulas.
Do not delete legacy files.
```

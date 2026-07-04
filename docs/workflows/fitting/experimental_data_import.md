# FitTool experimental data import

## Scope

FitTool can load experimental dispersion vectors without changing model solvers, execution profiles, fitting adapters, or optimizer defaults.

Maintained GUI entrypoint:

```matlab
FitTool_GUI
```

## Supported files

- `.csv`
- `.txt`
- `.dat`
- `.mat`

Delimited text files are read as tables and only numeric/logical columns are exposed for selection. MAT files may contain a table, a numeric matrix with at least two columns, or a scalar struct containing same-length numeric vectors.

## Import workflow

1. Press **Load experimental data**.
2. Select the file.
3. Select the frequency column.
4. Select the phase-speed column.
5. Declare whether frequency is stored in Hz or kHz.
6. Review the normalized table and preview plot.
7. Run the fit using the existing model, branch, physical-parameter, execution-profile, and optimizer controls.

The internal fitting contract remains:

```matlab
experimental.frequency_Hz
experimental.Cp_mps
experimental.validMask
```

## Normalization

`guiPrepareExperimentalFitData` performs the maintained normalization step:

- converts frequency to Hz;
- converts phase speed to m/s;
- removes non-finite and non-positive rows;
- sorts by increasing frequency;
- collapses duplicate frequencies by mean phase speed by default;
- combines duplicate `Use` flags with logical `any`;
- creates provenance metadata.

The GUI table stays editable after import.

## Manual table editing

FitTool keeps the loaded or generated data in an editable table with columns:

```text
frequency_Hz | Cp_mps | Use
```

The table supports:

- **Add row**, which appends `[NaN, NaN, 1]`;
- **Delete selected row**, which removes the selected row or rows;
- direct cell editing.

Manual edits do not run validation immediately. Validation remains centralized in
`guiPrepareExperimentalFitData` and occurs when a fit request is built. A fit
still requires at least two valid positive finite frequency/speed pairs.

## Provenance metadata

Imported data records:

- file path and file name;
- MAT source variable when applicable;
- selected columns and column names;
- declared input units;
- canonical output units;
- duplicate policy;
- removed invalid rows;
- collapsed duplicate rows;
- final row count.

The most recent fit output exposes this as:

```matlab
FitToolLastOutput.experimentalDataMetadata
```

If imported or synthetic data are edited in the GUI, the original provenance is
preserved and the metadata adds:

```matlab
wasManuallyEdited = true
```

For example, an edited file import keeps `sourceType = "experimental_file"` and
the original `fileName`.

## Axis view controls

FitTool axis limits are visual state only. The controls:

```text
X min [kHz], X max [kHz], Y min [m/s], Y max [m/s]
Apply axes, Auto axes
```

update a local `axisViewState` and are not included in `guiBuildFitRequest`.
Manual limits persist across replotting, synthetic generation, model changes,
fits, and requested fitted-curve evaluation until **Auto axes** is selected.

## Architecture

File parsing and normalization are separated from the GUI:

```text
app/fitting/guiReadExperimentalFitFile.m
app/fitting/guiPrepareExperimentalFitData.m
```

`FitTool_GUI` handles only user interaction, table population, preview plotting, and request orchestration. `createFittingTab` remains the visual control builder.

## Tests

Run:

```matlab
startup
run_fit_data_import_tests
run_fit_validation_tests
run_gui_smoke_tests
```

The import tests use temporary files and do not write artifacts into the repository.

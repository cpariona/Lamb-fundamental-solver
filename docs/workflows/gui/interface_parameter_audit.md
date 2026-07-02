# GUI parameter exposure audit

## Scope

This audit compares the maintained MATLAB GUI surfaces:

- `LambFundamental_GUI`: single-case forward modeling.
- `SweepTool_GUI`: one-parameter sweeps.
- `FitTool_GUI`: one-parameter fitting.

The immediate design requirement is that fitting remains limited to one free parameter, while every non-fitted model parameter that influences the selected model remains visible and editable.

## Executive finding

`FitTool_GUI` is the highest-priority interface to revise.

The fitting backend already supports the required separation:

```text
fixedParams
freeParams
initialGuess
bounds
controls
fitOptions
```

The current limitation is primarily in the GUI layer. `guiGetFitRegistry` already declares more model parameters than `FitTool_GUI` exposes, but `createFittingTab` creates only controls for:

- model;
- branch;
- one free parameter;
- initial guess and bounds;
- robustness;
- fixed `etaS` for one mRLFE case;
- mRLFE A0 policy.

When a fit starts, `FitTool_GUI` reconstructs most non-fitted parameters from model defaults instead of reading editable GUI values. Consequently, the user cannot inspect or modify most fixed parameters before fitting.

## Current interface status

### Main GUI

`LambFundamental_GUI` is the broadest parameter-exposure surface. It is the best reference for labels, units, grouping, and model-specific controls.

Strengths:

- intended for full single-case model configuration;
- exposes model inputs before execution;
- preserves raw and normalized outputs;
- already supports Rayleigh-Lamb, mRLFE, and AE IOP/HGO.

Remaining concern:

- some parameter/control logic remains model-specific inside callbacks;
- it should be treated as a visual and semantic reference, not copied directly into FitTool callbacks.

### SweepTool

`SweepTool_GUI` is registry-driven, but it exposes only the selected sweep parameter. Other model parameters remain in a base request or adapter defaults.

Visible sweep parameters currently are:

| Model | Visible sweep parameters |
|---|---|
| Rayleigh-Lamb | `thickness`, `mu` |
| mRLFE | `etaS`, `mu`, `thickness` |
| AE IOP/HGO | `IOP`, `mu` |

This is adequate for a narrow one-parameter sweep tool, but it does not yet satisfy the broader requirement that every fixed parameter be visible and editable.

### FitTool

`FitTool_GUI` is partially registry-driven. The registry defines parameter metadata, but the UI does not render a complete model-parameter editor from that metadata.

Current one-parameter fitting choices:

| Model | Free-parameter choices shown in GUI |
|---|---|
| Rayleigh-Lamb | `mu`, `thickness` |
| mRLFE | `mu`, `thickness`, `etaS` |
| AE IOP/HGO | `mu`, `thickness`, `IOP` |

Current hidden or non-editable fixed parameters:

| Model | Parameters known by registry but not generally editable in FitTool |
|---|---|
| Rayleigh-Lamb | `rho`, `nu`, and whichever of `mu`/`thickness` is fixed |
| mRLFE | `rho`, `nu`, `fluidDensity`, `fluidSoundSpeed`, and whichever of `mu`/`thickness`/`etaS` is fixed |
| AE IOP/HGO | `R`, `k1`, `k2`, `rho`, `rhoF`, `fluidBulkModulus`, and whichever of `mu`/`thickness`/`IOP` is fixed |

`etaS` is a special case: the GUI exposes a dedicated fixed field only when `etaS` is not selected as the free parameter.

## Model-by-model fitting gap

### Rayleigh-Lamb

Registry parameters:

```text
mu
thickness
rho
nu
```

Desired behavior:

- exactly one of the supported fit parameters is free;
- all remaining parameters are shown as editable fixed values;
- fixed `rho` and `nu` must be passed through `fixedParams`;
- the fixed value of `mu` or `thickness` must come from the GUI, not from `rlDefaultParams()` at fit time.

### mRLFE

Registry parameters:

```text
mu
etaS
thickness
rho
nu
fluidDensity
fluidSoundSpeed
```

Desired behavior:

- exactly one of `mu`, `etaS`, or `thickness` is free initially;
- all other physical parameters are editable;
- `fluidDensity` and `fluidSoundSpeed` remain solver controls if the adapter requires that storage location, but must appear to the user as model parameters;
- atlas policy and robustness remain separate solver/policy controls.

### AE IOP/HGO

Registry parameters:

```text
mu
IOP
thickness
R
k1
k2
rho
rhoF
fluidBulkModulus
```

Desired behavior:

- exactly one of `mu`, `IOP`, or `thickness` is free in the first implementation;
- every other physical parameter is visible and editable;
- fixed values are passed through `fixedParams`;
- atlas discretization and branch-policy settings remain in a separate advanced solver-controls section.

## Architectural diagnosis

The backend is not the principal blocker.

`guiBuildFitRequest` already accepts arbitrary `fixedParams`, and each fitting adapter forwards them to the model-specific fit configuration. Therefore, the first implementation should avoid modifying solver equations or fitting algorithms.

The main coupling to remove is inside `FitTool_GUI`:

```text
selected model/free parameter
    -> hard-coded switch
    -> recreate defaults
    -> construct fixedParams
```

Recommended replacement:

```text
fit registry
    -> parameter editor state
    -> one selected free parameter
    -> editable fixed values for all other parameters
    -> request builder
```

## Recommended FitTool design

### 1. Registry as the single source of parameter metadata

Extend or reuse `guiGetFitRegistry` so each parameter carries:

- `id`;
- `fieldName`;
- label;
- display unit;
- display scale;
- default value;
- fit capability;
- default bounds;
- help text;
- destination: `fixedParams` or `controls`;
- optional visibility group.

The current registry already contains most of this information. The missing field is mainly the destination/role needed for mRLFE fluid controls and future advanced options.

### 2. Dynamic parameter table or scrollable panel

For the selected model, render all registered physical parameters.

Suggested columns:

| Parameter | Role | Value | Unit | Initial | Lower | Upper |
|---|---|---:|---|---:|---:|---:|

Behavior:

- only one row may have role `Fit`;
- all other rows use role `Fixed`;
- `Initial`, `Lower`, and `Upper` are enabled only for the fitted row;
- `Value` is enabled only for fixed rows;
- changing the free parameter transfers the current value sensibly rather than resetting every field to defaults;
- units are always visible.

A scrollable grid is preferable to model-specific hard-coded edit fields because AE IOP/HGO has many parameters.

### 3. Separate physical parameters from solver controls

Physical/model parameters:

```text
mu, thickness, rho, nu, etaS, IOP, R, k1, k2, rhoF, fluidBulkModulus, ...
```

Solver/policy controls:

```text
robustness
mRLFE A0 policy
atlas resolution
optimizer limits
tolerance presets
```

The main parameter panel should not mix numerical solver controls with physical quantities.

### 4. Request construction outside the main GUI function

Move registry-to-request conversion into small testable helpers, for example:

```text
guiBuildFitParameterState
guiBuildFitParameterRequest
guiValidateFitParameterState
```

Names are illustrative. Final names should follow repository naming conventions.

These helpers should be testable without opening a figure.

### 5. Synthetic-data consistency

`Generate synthetic from setup` must use the same current fixed values, free-parameter value, branch, and controls that a fit request would use. It must not silently return to model defaults.

### 6. Preserve one-parameter fitting

The first implementation should keep:

```text
numel(freeParams) == 1
```

Multi-parameter fitting should not be introduced in the same change. The UI and request state may be designed so it is possible later, but the active contract should remain one free parameter.

## Recommended implementation order

1. Add headless tests for registry completeness and parameter-state conversion.
2. Add a registry-driven parameter-state helper.
3. Add request-building helper that separates `fixedParams`, `initialGuess`, `bounds`, and `controls`.
4. Replace hard-coded fixed-parameter construction in `FitTool_GUI`.
5. Replace the minimal fixed-summary label with a scrollable parameter editor.
6. Make synthetic generation use the same state.
7. Run GUI smoke, fitting validation, model-specific fitting tests, and manual GUI checks.

## Recommendation

Work on `FitTool_GUI` first.

Reasons:

- it has the clearest functional gap;
- the backend request contract already supports the desired behavior;
- the work can be isolated mostly to GUI metadata, parameter-state helpers, request construction, and tests;
- it directly supports the intended workflow: estimate one parameter while controlling every other physical parameter;
- the same parameter-editor pattern can later be reused by `SweepTool_GUI`.

Do not start by modifying solver-core files. Begin with registry/state/request tests and only touch model adapters where a parameter currently has to be routed through `controls` rather than `fixedParams`.

## Validation target for the implementation phase

Automated:

```matlab
startup
test_gui_struct_helpers_contract
run_gui_smoke_tests
run_fit_validation_tests
run_mrlfe_fit_atlas_tests
run_all_smoke_tests
```

Add focused tests that verify, for every model family:

- all registered physical parameters are represented;
- exactly one parameter is free;
- every other parameter is placed in the correct fixed/control destination;
- display-to-solver unit conversion is correct;
- changing a fixed value changes the generated request;
- synthetic generation and fitting use the same parameter state.

Manual:

```text
FitTool_GUI
```

Check each model, each currently supported free parameter, fixed-parameter editing, units, bounds, model switching, synthetic generation, and fit execution.

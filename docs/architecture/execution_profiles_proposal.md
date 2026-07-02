# Execution Profiles Proposal

## Target concepts

Future work should split the current overloaded `robustness` concept into four independent axes.

### 1. App-level execution profile

Visible user concept:

```text
Fast
Balanced
Robust
```

Recommended future field:

```text
executionProfile
```

`robustness` should remain as a compatibility alias for at least one migration cycle.

### 2. Internal solver or atlas profile

Model-specific implementation detail:

- RL mallas and tracking windows.
- mRLFE atlas scan points, candidates, adaptive windows, DP settings.
- AE atlas Y resolution, retained minima, initialization frequency points.

This layer should report metadata such as:

```text
requestedExecutionProfile
effectiveSolverProfile
effectiveAtlasPreset
effectiveAtlasNumYPoints
effectiveAtlasTopNMinima
effectiveCpScanPoints
```

### 3. Route or branch policy

Separate from performance:

- mRLFE `adaptivePhysicalTail`
- mRLFE `delayedCut`
- mRLFE viscous unified atlas vs zero-viscosity adaptive atlas
- AE `atlasA0`
- fallback policy and fallback status

This metadata should answer: which physical/numerical branch route was used?

### 4. Optimizer profile

Separate from solver evaluation cost:

- `MaxIter`
- `MaxFunEvals`
- `TolX`
- `TolFun`
- weighting policy

FitTool should stop encoding optimizer choices as ad hoc GUI literals once named optimizer profiles exist.

## Proposed metadata contract

Each GUI adapter and fit adapter should eventually return:

```matlab
metadata.executionProfile.requested
metadata.executionProfile.effective
metadata.solverProfile.name
metadata.solverProfile.optionsSummary
metadata.atlasProfile.name
metadata.atlasProfile.optionsSummary
metadata.routePolicy.name
metadata.routePolicy.actualPath
metadata.routePolicy.fallbackUsed
metadata.optimizerProfile.name
metadata.optimizerProfile.optionsSummary
```

The first implementation should be additive only.

## Recommended default policy

Policy to evaluate, not implement in this audit:

```text
LambFundamental_GUI -> Balanced
SweepTool_GUI       -> Fast
FitTool_GUI         -> Fast
```

| Surface/model | Assessment | Reason |
| --- | --- | --- |
| Main GUI / RL | Viable | Current default already `Balanced`; semantics are direct. |
| Main GUI / mRLFE | Viable with warning | Current UI starts from `Balanced`, but GUI fast atlas presets make effective atlas density route-specific. |
| Main GUI / AE | Requires more benchmark | `Balanced` maps to 600/16; acceptable interactively only if timing remains reasonable. |
| SweepTool / RL | Viable but changes current RL sweep default | Registry currently uses `Balanced`; moving to `Fast` trades quality for throughput. |
| SweepTool / mRLFE | Viable and current | Current default `Fast` preserves deliberate fast route. |
| SweepTool / AE | Viable and current | Current default `Fast`; Robust not exposed. |
| FitTool / RL | Viable and current | Fit default is `Fast`. |
| FitTool / mRLFE | Required in practice | Fitting cost multiplies solver cost; preserve fast atlas fit route. |
| FitTool / AE | Viable and current | Fit GUI currently enforces 300/12/50 regardless of selected Robust. |

## Migration plan

### PR 1: Audit, benchmarks, specification, descriptive tests

- Add inventory helper.
- Add headless benchmark.
- Add tests that document current effective behavior.
- Publish architecture docs.
- Do not change production defaults.

### PR 2: Centralized profile metadata, no visible default changes

- Introduce profile-resolution helpers that return requested and effective metadata.
- Add `executionProfile` while accepting `robustness` as alias.
- Keep all existing defaults and numeric values.
- Extend adapters to report metadata without changing solver calls.

### PR 3: Surface integration and silent override cleanup

- Route Main, Sweep, and Fit through profile-resolution helpers.
- Make overrides explicit in metadata and UI diagnostics.
- Decide whether SweepTool RL should move from `Balanced` to `Fast`.
- Decide whether SweepTool AE should expose `Robust`.
- Keep mRLFE fast GUI and fit presets unless benchmarks justify a model-specific alternative.

### PR 4: Cleanup, aliases, docs, deprecations

- Update docs and examples to prefer `executionProfile`.
- Mark `robustness` as compatibility alias.
- Remove stale references only after metadata is present and tests prove compatibility.
- Consolidate optimizer option docs into named optimizer profiles.

## Risks

- Renaming `robustness` too early would break GUI and examples.
- Treating mRLFE `Fast/Balanced/Robust` as equivalent to RL presets would erase deliberate fast atlas decisions.
- Raising FitTool AE or mRLFE density by default can make fitting impractical.
- Centralizing profiles without route-policy separation could hide important physics/branch decisions.

## Recommended tests

- Keep `test_execution_profile_current_contract.m` as the migration guard.
- Add future tests for requested/effective metadata on Main, Sweep, Fit, and API calls.
- Add one non-fragile benchmark smoke that verifies benchmark table shape, not timing thresholds.
- Avoid fragile Cp snapshots except for small, model-owned numerical regression cases.

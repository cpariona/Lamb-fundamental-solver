# Execution Profiles Audit

> Historical note: This audit records pre-migration execution-profile behavior.
> Maintained mRLFE production routes now use the public `mrlfeSolve` API on
> Main GUI, SweepTool, and FitTool. Legacy route names in this document are
> retained only as historical audit evidence, not as active contracts.

## Executive summary

At the time of this audit, the repository used the words `Fast`, `Balanced`,
`Robust`, and `robustness` for several different concepts. Rayleigh-Lamb used
them as true solver presets. AE IOP/HGO used them mostly as atlas density
presets. mRLFE used them as a seed/default layer, while GUI and fitting routes
applied additional fast atlas presets and route policies that could dominate the
requested value.

No production defaults were changed in this audit. The important behavior at
that time was:

| Area | Current behavior | Risk |
| --- | --- | --- |
| Main GUI / RL | `Balanced` by default through `rlDefaultOptions("Balanced")`. | Low if preserved. |
| Main GUI / mRLFE | Starts from selected `rlDefaultOptions`, then GUI mRLFE route applies `fast_viscous` or `fast_zero_viscosity_adaptive` unless disabled. | High: user-facing `robustness` and actual atlas density are not the same concept. |
| Main GUI / AE | Uses the selected RL `robustness` only to build AE atlas options through `guiBuildAcoustoelasticIOPHGOOptions`. | Medium: the control name is shared, but semantics are AE atlas density. |
| SweepTool / RL | Registry default is `Balanced`; adapter falls back to `Balanced`. | Low. |
| SweepTool / mRLFE | Registry default is `Fast`; adapter falls back to `Fast`, then calls the same GUI mRLFE route policy. | High: fast GUI atlas presets are intentional performance policy. |
| SweepTool / AE | Registry exposes only `Fast` and `Balanced`; GUI maps `Balanced` to 600/16 and every other value to 300/12. | Medium: `Robust` exists in `aeDefaultSweepOptions` but is not exposed by SweepTool. |
| FitTool / RL | Registry default is `Fast`; adapter maps controls to `rlDefaultOptions`. | Low. |
| FitTool / mRLFE | Registry exposes all three presets, but adapter calls `mrlfeDefaultSweepOptions`, which hard-codes `rlDefaultOptions("Fast")`, then applies `fast_fit_atlas`. | High: requested `Balanced`/`Robust` is not effective for solver density in the default fit route. |
| FitTool / AE | Registry exposes all three presets, then GUI injects 300/12/50, overriding robustness-derived atlas density. | High: requested `Robust` can become effective 300/12/50. |

## Confirmed Git baseline

Baseline before audit:

```text
git fetch origin
git status -sb
## audit-execution-profiles

git log --oneline --decorate -5
1a0c85c (HEAD -> audit-execution-profiles, origin/main, origin/HEAD, main) Complete FitTool parameter configuration (#98)
ca3e61e Expose and validate FitTool model parameters (#97)
5762b74 Add internal API contracts and numerical regression coverage (#96)
3898616 Consolidate shared MATLAB infrastructure (#95)
af3b748 Audit MATLAB dependencies and path hygiene (#94)

git diff --stat origin/main...HEAD
<empty>
```

PR #97 and PR #98 are incorporated in `origin/main`. The #98 merge contains:

- `app/fitting/guiResolveFitModelSetup.m`
- `tests/app/fitting/test_fit_parameter_execution_contract.m`
- updates to `app/fitting/guiNormalizeFitResult.m`
- final AE/HGO FitTool defaults in `app/FitTool_GUI.m` and `app/fitting/guiGetFitRegistry.m`

## Inventory

The reproducible inventory helper is:

```matlab
inventory = inventoryExecutionProfiles();
```

It scans `.m`, `.md`, and `.txt` files for:

```text
Fast, Balanced, Robust, robustness, executionProfile, solverPreset,
atlasPreset, fitAtlasPreset, fast_fit_atlas, fast_viscous,
fast_zero_viscosity_adaptive, mrlfeUseGuiFastAtlasPreset,
mrlfeUseFitAtlasPreset, atlasNumYPoints, atlasTopNMinima,
atlasInitializationNumFrequencyPoints, mrlfeFitAtlasCpScanPoints,
mrlfeAdaptiveCpScanPoints, mrlfeViscoAtlasCpScanPoints,
mrlfeA0DPCpScanPoints, MaxIter, MaxFunEvals, TolX
```

Output:

```text
analysis/execution_profiles/execution_profile_inventory.csv
```

The table includes file, line, token, model classification, surface classification, origin, risk, and initial recommendation. The classification is heuristic; the architectural tables below are the reviewed contract interpretation.

## Reviewed source inventory

| File | Function or section | Model | Surface | Name requested | Effective configuration | Options affected | Route affected | Origin | Related document | Risk | Recommendation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `models/rayleigh_lamb/core/rlDefaultOptions.m` | `switch robustness` | RL/shared | API | `Fast` | initial grid 1200, tracking 300, `jumpTol=0.35`, mRLFE grid 220, complex max 70/150 | grids, search windows, jump tolerance, complex-k limits | Direct RL and seed paths | Default | `docs/models/rayleigh_lamb/public_api.md` | High | Preserve semantics; expose through future solver profile metadata. |
| `models/rayleigh_lamb/core/rlDefaultOptions.m` | `switch robustness` | RL/shared | API | `Balanced` | initial grid 3000, tracking 700, `jumpTol=0.25`, mRLFE grid 450 | grids, search windows, jump tolerance | Direct RL and seed paths | Default | `README.md` | High | Preserve as main GUI default. |
| `models/rayleigh_lamb/core/rlDefaultOptions.m` | `switch robustness` | RL/shared | API | `Robust` | initial grid 6000, tracking 1400, `jumpTol=0.30`, mRLFE grid 800, complex max 180/420 | grids, search windows, jump tolerance, complex-k limits | Direct RL and seed paths | Default | `README.md` | High | Preserve; do not conflate with optimizer robustness. |
| `analysis/acoustoelastic_iop_hgo/aeDefaultSweepOptions.m` | `localAtlasPreset` | AE | API/Sweep/Fit | `Fast` | `atlasNumYPoints=300`, `atlasTopNMinima=12` | atlas resolution, candidate minima | `atlasA0` | Default | `docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md` | High | Preserve as AE atlas preset. |
| `analysis/acoustoelastic_iop_hgo/aeDefaultSweepOptions.m` | `localAtlasPreset` | AE | API/Sweep/Fit | `Balanced` | `atlasNumYPoints=600`, `atlasTopNMinima=16` | atlas resolution, candidate minima | `atlasA0` | Default | active AE docs | High | Preserve; expose in SweepTool only if cost is acceptable. |
| `analysis/acoustoelastic_iop_hgo/aeDefaultSweepOptions.m` | `localAtlasPreset` | AE | API/Fit | `Robust` | `atlasNumYPoints=900`, `atlasTopNMinima=20` | atlas resolution, candidate minima | `atlasA0` | Default | active AE docs | High | Preserve but keep out of default fitting until benchmarked further. |
| `analysis/mrlfe/mrlfeDefaultSweepOptions.m` | body | mRLFE | API/Sweep/Fit | any caller | Always starts from `rlDefaultOptions("Fast")` | seed grid, mRLFE real-k flags | real-k, unified atlas optional | Default/helper | `docs/models/mrlfe/fitting_workflow.md` | High | Preserve for now; future API should accept explicit internal profile. |
| `app/adapters/guiRunMRLFEModel.m` | `applyGuiAtlasPreset` | mRLFE | Main/Sweep | `mrlfeUseGuiFastAtlasPreset` | true by default; sets 260 scan points and 5 candidates for GUI routes | atlas scan points, candidates, adaptive windows | `fast_viscous`, `fast_zero_viscosity_adaptive`, elastic reference | Adapter | GUI mRLFE atlas policy doc | High | Preserve; document as route-specific performance preset. |
| `analysis/mrlfe/mrlfeEvaluateAtlasFitModel.m` | `localApplyFitAtlasPreset` | mRLFE | Fit/API | `fast_fit_atlas` | true by default; Cp scan points 260 and candidates 5 | fit atlas scan/candidate density | atlas fit route | Evaluator | mRLFE fitting workflow | High | Preserve; separate from user execution profile. |
| `analysis/mrlfe/mrlfeEvaluateFitModel.m` | legacy branch | mRLFE | Fit/API | `mrlfeUseAtlasFitRoute=false` | legacy path only on explicit diagnostic/legacy calls | direct viscous atlas or maintained workflow | legacy route | Evaluator | archive/diagnostics | Medium | Keep as maintained compatibility route; do not default back. |
| `app/FitTool_GUI.m` | `buildParameterConfig` | mRLFE | Fit | `Fast/Balanced/Robust` | controls include selected value, but mRLFE adapter ignores it via `mrlfeDefaultSweepOptions` | optimizer 35/80/1e-5; atlas route true | atlas fit route | GUI | fitting architecture | High | Document silent mismatch; fix in later PR with metadata. |
| `app/FitTool_GUI.m` | `buildParameterConfig` | AE | Fit | selected robustness | GUI always writes `atlasNumYPoints=300`, `atlasTopNMinima=12`, init points 50 | atlas density and init grid | `atlasA0` | GUI | AE fitting workflow | High | Preserve for first phase; later rename as fit atlas preset. |
| `app/SweepTool_GUI.m` | `buildControlsForActiveFamily` | AE | Sweep | `Balanced` or fallback | `Balanced` -> 600/16; otherwise 300/12 | atlas density | `atlasA0` | GUI | sweep tool docs | Medium | Clarify that Robust is not selectable in SweepTool AE. |
| `app/sweep/guiGetSweepRegistry.m` | registry defaults | shared | Sweep | defaults | mRLFE Fast, RL Balanced, AE Fast | requested profile defaults | all sweep adapters | Registry | sweep docs | Medium | Desired policy already mostly matches except AE Robust availability. |
| `app/fitting/guiGetFitRegistry.m` | registry defaults | shared | Fit | defaults | RL/mRLFE/AE all Fast; all expose Robust | requested profile defaults | all fit adapters | Registry | fitting architecture | Medium | Keep UI visible values until metadata can explain effective values. |
| `app/createAdvancedTab.m` | main GUI advanced control | shared | Main | default `Balanced` | selected profile starts RL options | user-visible robustness | all main GUI adapters | GUI | README | Low | Future label should be `executionProfile`; keep alias. |

## Contradictions and silent overrides

1. `mrlfeDefaultSweepOptions` always uses `rlDefaultOptions("Fast")`, so FitTool `Balanced` or `Robust` requests do not alter the default mRLFE fit solver grid.
2. `mrlfeEvaluateAtlasFitModel` recomputes the Rayleigh-Lamb seed with `rlDefaultOptions("Fast")`, even if the caller's mRLFE options carry another `robustness`.
3. FitTool AE exposes `Robust`, but GUI-created requests set 300/12/50, overriding the 900/20 produced by `aeDefaultSweepOptions("Robust")`.
4. SweepTool AE does not expose `Robust`, although the AE API supports it.
5. `robustness` is used for solver density, atlas density, route policy labels, and optimizer options in nearby code, but these are different axes.

## Decisions to preserve

- RL `Fast/Balanced/Robust` numeric differences should be preserved exactly during migration.
- mRLFE GUI fast atlas presets are deliberate performance policy and should not be removed while moving to a clearer execution-profile API.
- mRLFE `fast_fit_atlas` is the maintained FitTool default route; legacy direct-viscous paths are opt-in diagnostics.
- AE/HGO FitTool physical defaults are final after PR #98 and are outside this audit's redesign.
- AE atlas density presets 300/12, 600/16, 900/20 are current public API behavior.

## Technical debt

- No single metadata object reports requested profile, effective solver profile, atlas preset, optimizer profile, and route policy across all surfaces.
- Main, Sweep, and Fit compute effective options in different places.
- mRLFE has route-policy names (`adaptivePhysicalTail`, `delayedCut`) adjacent to performance names (`fast_fit_atlas`) in the same option struct.
- Optimizer options are hard-coded in FitTool GUI and model fit functions instead of named optimizer profiles.
- Archived documents explain historical routes, but active docs do not consistently distinguish active contracts from diagnostics.

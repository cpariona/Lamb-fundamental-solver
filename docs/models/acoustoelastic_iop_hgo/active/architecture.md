# AE IOP/HGO architecture

This document defines the implemented architecture of the maintained
Acoustoelastic IOP/HGO (AE) model. It is a final-state contract, not a migration
report. Git history records the completed alignment work.

The repository-wide layer and naming rules remain authoritative:

- [`../../../repository/repository_structure.md`](../../../repository/repository_structure.md)
- [`../../../repository/naming_strategy.md`](../../../repository/naming_strategy.md)
- [`../../../repository/maintained_entrypoints.md`](../../../repository/maintained_entrypoints.md)

The official production output and branch policy are defined in
[`branch_policy.md`](branch_policy.md). Numerical issues that are not
architecture work are recorded separately in
[`solver_pending_work.md`](solver_pending_work.md).

## Production route

`solveAcoustoelasticIOPHGOBranch(params, options)` is the single production
solver route for application and maintained workflow consumers:

```text
solveAcoustoelasticIOPHGOBranch
  -> aeValidateRequest
  -> aeResolveConfiguration
  -> computeAcoustoelasticABGFromIOPHGO
  -> aeBuildInternalTrackingGrid, when enabled
  -> solveAcoustoelasticAtlasBranch
        -> aeBuildAtlas
           -> objectiveAcoustoelasticResidual
              -> buildAcoustoelasticMatrix
              -> computeAcoustoelasticSRoots
        -> aeFindAtlasLocalMinima
        -> aeLinkAtlasBranches
           -> aeSplitAtlasBranches
        -> aeSelectAtlasA0Branch
        -> aeBuildResult
           -> aeEvaluateAtlasA0Quality
     -> requested-grid projection, when enabled
     -> aeApplyAtlasA0FallbackPolicy
     -> aeBuildResult
```

The public entrypoint owns complete production orchestration. Configuration,
tracking, policy, quality, and result construction each have one model-layer
owner.

## Directory responsibilities

The stable model structure is:

```text
models/acoustoelastic_iop_hgo/
|-- configuration/  request validation, effective options, presets, grids
|-- constitutive/    IOP/HGO stretch, prestress, and alpha/beta/gamma
|-- core/            matrix, roots, and objective functions
|-- diagnostics/     explicit identity-A0 diagnostic algorithms
|-- options/         default options and branch-policy normalization
|-- policies/        official atlasA0 selection and fallback decisions
|-- quality/         requested-grid reliability and quality summaries
|-- results/         canonical result assembly only
|-- solvers/         public/advanced orchestration and atlas construction
`-- tracking/        minima detection, branch linking, and splitting
```

There is no `api/` folder. The small number of scientific entrypoints remain in
`solvers/`; adding another directory would not create a clearer ownership
boundary.

`models/` never depends on `analysis/`, `app/`, `examples/`, or `tests/`.
Analysis may call public model APIs. App code reaches the model through
maintained adapters and workflows. Examples use public APIs or analysis
workflows.

## Canonical ownership

| Responsibility | Canonical owner | Status |
| --- | --- | --- |
| Flat request validation | `aeValidateRequest` | maintained internal |
| Effective option resolution | `aeResolveConfiguration` | maintained internal |
| Fast/Balanced/Robust numerical presets | `aeGetNumericalPreset` | maintained internal configuration |
| Requested/internal tracking grid | `aeBuildInternalTrackingGrid` | maintained internal |
| IOP/HGO public solve | `solveAcoustoelasticIOPHGOBranch` | public production API |
| Direct atlas orchestration | `solveAcoustoelasticAtlasBranch` | maintained internal diagnostic |
| Objective atlas construction | `aeBuildAtlas` | maintained internal |
| Local minima | `aeFindAtlasLocalMinima` | maintained internal |
| Branch linking | `aeLinkAtlasBranches` | maintained internal |
| Branch splitting | `aeSplitAtlasBranches` | maintained internal |
| Official branch selection | `aeSelectAtlasA0Branch` | maintained internal policy |
| Fallback invalidation | `aeApplyAtlasA0FallbackPolicy` | maintained internal policy |
| Reliability and quality | `aeEvaluateAtlasA0Quality` | maintained internal |
| Atlas result schema | `aeBuildResult` | maintained internal |
| Identity-A0 extension | `aeBuildIdentityA0DiagnosticBranch` | diagnostic-only model extension |
| Identity candidate score | `aeScoreBranchIdentityCandidates` | diagnostic-only model extension |

No app or analysis consumer calls production tracking or policy internals.
Diagnostic algorithms with similar concepts remain separate when their
scientific purpose is different.

## Configuration boundary

The model owns numerical values and precedence:

```text
caller surface/profile choice and explicit overrides
  -> aeResolveExecutionProfile (app translation)
  -> aeResolveConfiguration (model authority)
     -> aeGetNumericalPreset
     -> defaultAcoustoelasticIOPHGOOptions
```

App adapters select a profile or surface and translate UI state. Analysis
workflows select campaign defaults or explicit overrides. Neither layer owns a
second preset table. `aeValidateRequest` owns model request checks;
workflow-specific fitting and sweep validation remains in its workflow layer.

## Workflow and application routes

```text
Main GUI
  -> guiRunAcoustoelasticIOPHGOModel
  -> aeResolveExecutionProfile
  -> solveAcoustoelasticIOPHGOBranch
  -> normalized GUI result

SweepTool
  -> guiRunAcoustoelasticIOPHGOSweep
  -> aeResolveExecutionProfile
  -> aeRunSweep
  -> solveAcoustoelasticIOPHGOBranch per condition
  -> aeSummarizeSweep
  -> guiNormalizeAcoustoelasticIOPHGOSweep

FitTool
  -> guiFitAcoustoelasticIOPHGOSolver
  -> aeResolveExecutionProfile
  -> aeFitDispersionData
  -> aeEvaluateFitModel
  -> solveAcoustoelasticIOPHGOBranch per evaluation
  -> guiNormalizeFitResult

basic example
  -> run_atlas_branch
  -> solveAcoustoelasticIOPHGOBranch

physical sweep
  -> ae_sweep_*_A0Like
  -> aeRunSweep or aeRunGridSweep
  -> solveAcoustoelasticIOPHGOBranch per condition

fitting example
  -> fit_ae_atlasA0
  -> aeFitDispersionData
  -> aeEvaluateFitModel
  -> solveAcoustoelasticIOPHGOBranch
```

Output folders and files are workflow responsibilities. `resolveModelOutputFolder` and
`aeWriteSweepOutputs` own AE analysis output handling; model solvers do not
write files.

## Retained diagnostic solvers

These internal entrypoints retain distinct scientific diagnostic capabilities:

```text
direct real-Cp tracking
  -> solveAcoustoelasticIOPHGODispersion, for IOP/HGO inputs
     -> constitutive conversion
  -> solveAcoustoelasticDispersion
  -> objectiveAcoustoelasticResidual
  -> matrix/root core
  -> direct continuation result

complex-C tracking
  -> solveAcoustoelasticComplexCDispersion
  -> optional real-Cp seed result
  -> objectiveAcoustoelasticComplexDeterminant
  -> matrix/root core
  -> complex continuation result
```

| Entrypoint | Classification | Purpose |
| --- | --- | --- |
| `solveAcoustoelasticAtlasBranch` | maintained internal diagnostic | Direct alpha/beta/gamma atlas solve |
| `solveAcoustoelasticIOPHGODispersion` | retained diagnostic | IOP/HGO conversion plus direct real-Cp tracking |
| `solveAcoustoelasticDispersion` | retained diagnostic | Direct alpha/beta/gamma real-Cp tracking |
| `solveAcoustoelasticComplexCDispersion` | retained diagnostic | Distinct complex-C continuation solve |

They are not parallel production routes for Main GUI, SweepTool, FitTool,
maintained sweeps, fitting, or the basic example. Tests and diagnostics may call
them directly to characterize their distinct contracts.

## Quality, results, diagnostics, and metadata

`aeEvaluateAtlasA0Quality` summarizes the already selected official branch on
the requested grid. It does not select or repair a branch.

`aeBuildResult` is the sole atlas result-schema constructor. The stable summary
is `result.diagnostics`; characterized objective maps, tables, configuration,
and internal tracking evidence remain at their existing top-level locations.
Moving them would be a schema change.

Metadata is intentionally repeated at several boundaries:

- the model result records physical/numerical evidence;
- analysis sweep and fit results record requests, conditions, and aggregates;
- normalized app results record display-ready values and execution-profile
  metadata;
- saved fit and sweep results preserve their established workflow schemas.

This duplication is schema compatibility, not duplicate production ownership.
No maintained field is removed or relocated without a separately authorized,
schema-versioned change and complete consumer evidence.

`identityA0Diagnostic`, `raw_branch1`, modal atlases, and branch-family
candidates are diagnostic-only. They never replace official
`result.phaseVelocity_mps`, `result.validMask`, or the `atlasA0` policy.

## Diagnostic separation and retained helpers

Diagnostic entrypoints live under
`examples/acoustoelastic_iop_hgo/diagnostics/`; reusable diagnostic computation
lives in `analysis/acoustoelastic_iop_hgo/diagnostics/`. The explicit
identity-A0 builder and scorer are model-owned under
`models/acoustoelastic_iop_hgo/diagnostics/` because the requested policy is
attached inside model orchestration. Production tracking does not call analysis
diagnostics, and model diagnostic helpers do not own production selection.

```text
diagnose_* / validate_* / compare_* / track_*
  -> reusable ae* diagnostic helpers
  -> advanced solver APIs or previously saved official results
  -> diagnostic tables, figures, and optional outputs
```

The six helpers reviewed during finalization are retained:

| Helper | Final classification | Reason |
| --- | --- | --- |
| `summarizeAcoustoelasticIOPHGOTrackingQuality` | intentionally dormant supported helper | General comparison table for real- and complex-C tracking results; external use remains possible |
| `aePlotGridSweepCp` | intentionally dormant supported helper | General grid-sweep curve renderer distinct from the axis-grouped maintained plot |
| `aeAnalyzeFirstUnrecoveredBreak` | repeatable diagnostic infrastructure | Inspects stored minima at the first unresolved contiguous break without changing output |
| `aeClassifyTruncationRecovery` | repeatable diagnostic infrastructure | Converts truncation/recovery evidence into a diagnostic classification |
| `aeClassifyAmbiguityRegime` | repeatable diagnostic infrastructure | Records known ambiguity regimes without changing branch tracking |
| `aeRefineAtlasA0BranchPersistence` | repeatable diagnostic infrastructure | Produces a separately labeled candidate and is covered by a focused contract |

None is a production route. No helper was deleted because static caller absence
alone does not prove that a distinct scientific diagnostic is redundant or
unused externally.

## Result-file compatibility

New outputs use:

```text
Results/ae_iop_hgo/<task>
```

`resolveModelOutputFolder` owns writes to that convention. `aeResolveResultFile` owns
read resolution for five maintained diagnostic scripts at eight call sites:

- `compare_atlasA0_vs_raw_branch1`;
- `diagnose_atlas_truncation`;
- `diagnose_idA0_plausibility`;
- `diagnose_idA0_score`;
- `diagnose_sweep_reliability`.

It checks the canonical task/file first, then the explicitly supplied legacy
`Results/<legacy-folder>/<legacy-file>` location. The fallback remains bounded
compatibility debt because generated scientific workspaces are not checked into
the repository and external legacy inputs cannot be ruled out. It may be
removed only after required diagnostics have canonical fixtures, all external
inputs have migrated, and focused plus manual loading checks pass.

## Naming contract

- `solveAcoustoelastic*` identifies maintained scientific solver entrypoints.
- `ae*` identifies AE-owned model and analysis helpers.
- `gui*` is reserved for application adapters and UI helpers.
- `run_*` identifies basic executable examples or runners.
- `ae_sweep_*` identifies maintained physical sweep scripts.
- `fit_*`, `diagnose_*`, `validate_*`, and `compare_*` identify executable
  fitting examples and diagnostic evidence.
- `test_*` identifies tests.

There are no author-specific maintained identifiers, forwarding aliases, or
parallel old/new production names. Valid explicit scientific names are retained
even when they are longer than internal `ae*` names.

## Validation ownership

Focused AE ownership is guarded by:

```matlab
test_ae_configuration_ownership
test_ae_result_ownership
test_ae_tracking_policy_ownership
test_ae_workflow_route_ownership
test_ae_final_architecture_contract
test_ae_result_file_compatibility
```

Schema and numerical characterization remain in the existing model, app,
fitting, sweep, and execution-profile tests. Canonical AE tiers are:

```matlab
run_ae_quick_tests
run_ae_extended_tests
run_acoustoelastic_smoke_tests
```

Their aggregate route is:

```text
run_quick_smoke_tests / run_all_smoke_tests
  -> run_acoustoelastic_smoke_tests
     -> run_ae_quick_tests
     -> run_ae_extended_tests
```

Repository structure, names, dependency direction, links, identifiers, and test
ownership are guarded by `run_repository_hygiene_tests`.

## Remaining work outside this architecture contract

Residual high-frequency AE `Cp(f)` waviness is numerical research, not
architecture finalization. Its scope and safeguards remain in
[`solver_pending_work.md`](solver_pending_work.md). Any future numerical task
must preserve this ownership map unless a separate architecture change is
explicitly approved.

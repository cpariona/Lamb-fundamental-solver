# AE IOP/HGO architecture audit and alignment plan

Status: Phase 1 audit with Phases 2-3 ownership implemented

Audit branch: `audit/ae-architecture-alignment`

Base: `42206beaf0e719226f03cd1fdb99b1049d81a1f4`

Reviewed and updated after Phase 3: 2026-07-16

## Decision summary

The maintained AE IOP/HGO implementation has a coherent physical core and a
single official production policy, `atlasA0`. Phase 2 established one
model-layer owner for effective configuration, request validation, numerical
presets, and internal tracking-grid construction. Phase 3 established one
atlas result builder and one requested-grid quality owner. Tracking and policy
remain later alignment phases.

The target is to retain the AE-specific scientific entrypoints and the exact
current numerical behavior while introducing explicit model ownership for:

```text
configuration -> problem construction -> solver dispatch -> tracking
              -> policies -> quality -> results
```

Implemented Phase 2-3 ownership is:

1. `aeGetNumericalPreset` owns Fast/Balanced/Robust atlas density and the
   separate Main GUI numerical bundle.
2. `aeResolveConfiguration` owns complete effective options, surface bundles,
   explicit-override precedence, and policy normalization.
3. `aeValidateRequest` owns maintained wrapper/fitting field checks, while
   `aeBuildInternalTrackingGrid` owns the unchanged hidden-grid algorithm.
4. `aeBuildResult` owns direct-atlas and requested-grid result construction;
   `aeEvaluateAtlasA0Quality` owns all requested-grid reliability summaries.
5. The former solver-local reliability/result summarizers were removed.
   Explicit identity diagnostics resolve through diagnostic-only helpers beside
   the model result boundary, so `models/` no longer calls `analysis/`.

The public flat `params, options` signatures and all AE physics, `atlasA0`,
grids, policies, thresholds, and results remain unchanged.

## Phase 3 implemented boundary

No new `result.debug` field was introduced. Exact schema characterization
showed maintained consumers reading top-level atlas evidence, so moving that
evidence would have violated Phase 3 parity. The implemented boundary is:

```text
stable official output       frequency, Cp, validCp, pointStatus
stable quality               reliability
stable summary diagnostics   diagnostics
retained unstable evidence   minima/branch tables, objective maps, grids,
                             options, constitutive/direct/internal metadata
diagnostic extension         identityA0
compatibility evidence       fallbackCandidate*
```

`aeBuildResult` preserves the characterized field order and delegates only
quality summarization to `aeEvaluateAtlasA0Quality`. Fallback invalidation
remains the existing policy decision in the IOP/HGO wrapper; after that
decision, the canonical owners rebuild the quality and diagnostic summaries.
The result builder does not solve, track, select, split, interpolate, or decide
fallback.

The identity helper and scorer moved intact from `analysis/` to
`models/acoustoelastic_iop_hgo/results/`. They remain diagnostic-only and are
called only for an explicit `identityA0Diagnostic` request. This is a
dependency correction, not promotion to official output.

## Authority, scope, and vocabulary

Maintained code and tests were treated as authoritative over documentation.
The inventory below covers every tracked file under the five primary AE paths
(108 files), plus the AE-specific app and validation integration owners needed
to reconstruct actual calls. Ignored generated figures are not maintained
source artifacts.

The classification vocabulary is deliberately small:

| Classification | Meaning |
| --- | --- |
| public production API | Supported production solver/default surface. |
| advanced supported API | Supported scientific API below the primary route. |
| maintained internal | Model or analysis implementation not intended as the primary user route. |
| workflow helper | Reusable fitting, sweep, plotting, summary, or output workflow. |
| app adapter | GUI request/result/profile translation. |
| diagnostic-only | Repeatable scientific investigation; never official output. |
| compatibility surface | Bounded retained compatibility behavior with an explicit owner. |
| test or validation owner | Test, runner, or repeatable validation owner. |
| documentation owner | Maintained contract or evidence interpretation. |

`Production/diagnostic` below describes use, not folder location. `Future
owner` is proposed and must not be read as a completed move.

## Complete maintained-file inventory

### Model layer: 30 files

| Current folder | MATLAB identifier | Responsibility | Direct callers | Direct repository dependencies | Classification | Production/diagnostic | Future owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `configuration/` | `aeValidateRequest` | Preserve maintained flat IOP/direct-atlas/fitting request checks | IOP atlas wrapper; direct atlas solver; fit evaluator | none | maintained internal | production | `configuration/` |
| `configuration/` | `aeResolveConfiguration` | Build complete effective options, apply surface/preset/overrides, normalize policy, report metadata | AE solvers, analysis defaults/evaluator, app adapters | public defaults; preset owner; policy normalizer | maintained internal | production | `configuration/` |
| `configuration/` | `aeGetNumericalPreset` | Own Fast/Balanced/Robust and separate Main GUI numerical bundles | configuration resolver; focused tests | public defaults for unchanged shared values | advanced supported API | production | `configuration/` |
| `configuration/` | `aeBuildInternalTrackingGrid` | Build the exact sorted/unique internal atlas frequency grid | IOP atlas wrapper; focused tests | configuration resolver | maintained internal | production | `configuration/` |
| `constitutive/` | `computeAcoustoelasticABGFromIOPHGO` | IOP/HGO to alpha, beta, gamma and state | IOP/HGO solver wrappers; atlas diagnostics; constitutive test | prestress, HGO stretch, alpha/beta/gamma helpers | advanced supported API | production and diagnostic | `constitutive/` |
| `constitutive/` | `computeAcoustoelasticAlphaBetaGamma` | Constitutive moduli from stretch and HGO parameters | `computeAcoustoelasticABGFromIOPHGO` | none | advanced supported API | production | `constitutive/` |
| `constitutive/` | `computeAcoustoelasticPrestressSigma` | Thin-wall prestress | `computeAcoustoelasticABGFromIOPHGO` | none | advanced supported API | production | `constitutive/` |
| `constitutive/` | `solveAcoustoelasticHGOStretch` | Nonlinear HGO stretch solve and bracketing | `computeAcoustoelasticABGFromIOPHGO` | none | advanced supported API | production | `constitutive/` |
| `core/` | `buildAcoustoelasticMatrix` | AE fluid-loaded matrix and optional row normalization | both objective functions | S-root helper; default options | advanced supported API | production | `core/` |
| `core/` | `computeAcoustoelasticSRoots` | Characteristic roots | matrix builder | none | advanced supported API | production | `core/` |
| `core/` | `objectiveAcoustoelasticResidual` | Real-Cp singular-value residual | atlas/direct solvers; modal diagnostics | matrix builder; default options | advanced supported API | production and diagnostic | `core/` |
| `core/` | `objectiveAcoustoelasticComplexDeterminant` | Complex-C determinant objective | complex-C solver | matrix builder; default options | advanced supported API | diagnostic-capable | `core/` |
| `options/` | `defaultAcoustoelasticIOPHGOOptions` | Public base defaults for direct, tracking, policy, and diagnostics | configuration resolver; AE workflows and solvers | branch-policy normalizer | public production API | production | `options/` |
| `options/` | `aeNormalizeBranchPolicy` | Accept only `atlasA0` and `identityA0Diagnostic` | defaults, atlas solver, fitting, policy tests | none | advanced supported API | production and diagnostic | `policies/` |
| `solvers/` | `solveAcoustoelasticIOPHGOBranch` | Recommended IOP/HGO convenience entrypoint | Main GUI, sweeps, diagnostics, validation | IOP/HGO atlas wrapper | public production API | production | `api/` |
| `solvers/` | `solveAcoustoelasticIOPHGOAtlasBranch` | Validate/configure, build constitutive state, select internal grid, project requested output, apply fallback policy, rebuild result/quality | primary branch API, basic example, fitting, tests | canonical configuration, atlas solver, fallback policy, result, quality, and diagnostic identity owners | public production API | production | `solvers/` behind primary API |
| `solvers/` | `solveAcoustoelasticAtlasBranch` | Orchestrate atlas construction, minima, linking/splitting, selection, assignment, and canonical result construction | IOP/HGO atlas wrapper | canonical atlas, tracking, policy, result, quality, and diagnostic identity owners | advanced supported API | production with explicit diagnostic option | `solvers/` |
| `solvers/` | `aeBuildAtlas` | Construct the configured y/Cp grid and exact production objective map | direct atlas solver | real residual; resolved options | maintained internal | production | `solvers/` |
| `tracking/` | `aeFindAtlasLocalMinima` | Detect, optionally refine, rank, and retain production minima for one atlas column | direct atlas solver; focused ownership tests | objective column; configured top-N/refinement | maintained internal | production | `tracking/` |
| `tracking/` | `aeLinkAtlasBranches` | Link ranked minima, invoke configured splitting, and assemble the branch table | direct atlas solver; focused ownership tests | split owner; tracking options | maintained internal | production | `tracking/` |
| `tracking/` | `aeSplitAtlasBranches` | Split linked branches at large relative Cp jumps and retain qualifying segments | branch-link owner; focused ownership tests | configured jump and minimum-point values | maintained internal | production | `tracking/` |
| `policies/` | `aeSelectAtlasA0Branch` | Apply low-start filters, exact scoring/tie-break, and unfiltered-selection fallback metadata | direct atlas solver; focused ownership tests | branch table; resolved policy options | maintained internal | production | `policies/` |
| `policies/` | `aeApplyAtlasA0FallbackPolicy` | Preserve fallback candidate evidence and invalidate only the decided official surface | IOP/HGO atlas wrapper; focused ownership tests | selected result and fallback decision metadata | maintained internal | production | `policies/` |
| `quality/` | `aeEvaluateAtlasA0Quality` | Summarize already-decided official output on the current requested grid | canonical result builder | decided result artifacts and optional prior tracking metadata | maintained internal | production | `quality/` |
| `results/` | `aeBuildResult` | Construct and rebuild the characterized atlas result schema and stable diagnostics summary | atlas solver and IOP/HGO wrapper | quality owner; already-decided artifacts | maintained internal | production | `results/` |
| `results/` | `aeBuildIdentityA0DiagnosticBranch` | Build separate identity-scored diagnostic extension | explicit identity policy in atlas paths; diagnostics | identity scorer; decided solver evidence | diagnostic-only | diagnostic | `results/` diagnostic extension |
| `results/` | `aeScoreBranchIdentityCandidates` | Score diagnostic continuation candidates | identity builder; score diagnostics | decided solver evidence | diagnostic-only | diagnostic | `results/` diagnostic extension |
| `solvers/` | `solveAcoustoelasticIOPHGODispersion` | IOP/HGO-to-direct real-Cp solve | raw-branch/modal diagnostics | constitutive builder; direct dispersion solver; defaults | advanced supported API | diagnostic/advanced | `solvers/` |
| `solvers/` | `solveAcoustoelasticDispersion` | Direct real-Cp continuation, candidate scoring, validity, result assembly | IOP/HGO direct wrapper | real residual; defaults | advanced supported API | diagnostic/advanced | `solvers/`, then shared tracking/result owners where justified |
| `solvers/` | `solveAcoustoelasticComplexCDispersion` | Complex-C continuation and diagnostic summary | no maintained direct caller | complex objective; defaults | advanced supported API | diagnostic/advanced | `solvers/` |

### Analysis layer: 37 files

| Current folder | MATLAB identifier | Responsibility | Direct callers | Direct repository dependencies | Classification | Production/diagnostic | Future owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `analysis/acoustoelastic_iop_hgo/` | `aeDefaultSweepParams` | Shared physical campaign defaults | physical sweeps, fit problem, contracts | none | workflow helper | production workflow | analysis configuration |
| same | `aeDefaultSweepOptions` | Select maintained physical-sweep surface and execution profile | sweeps, fitting, tests | canonical model configuration resolver | workflow helper | production workflow | analysis workflow selector |
| same | `aeRunSweep` | One-parameter campaign loop | six physical sweeps; SweepTool adapter; contract test | primary AE branch API | workflow helper | production workflow | analysis sweeps |
| same | `aeRunGridSweep` | Multi-axis campaign loop | mu-IOP sweep | primary AE branch API; sweep options | workflow helper | production workflow | analysis sweeps |
| same | `aeSummarizeSweep` | Condition, dispersion, selected-branch tables | physical sweeps; SweepTool; reliability analysis | none | workflow helper | production workflow | analysis sweeps |
| same | `aeSummarizeGridSweep` | Grid-sweep tables | mu-IOP sweep | none | workflow helper | production workflow | analysis sweeps |
| same | `aeBuildSweepPlotData` | Adapt AE results to neutral plot data | `aePlotSweepCp`; renderer test | none | workflow helper | production workflow | analysis sweeps |
| same | `aeBuildGridSweepCpCube` | Build numerical Cp cube for interactive display | app interactive surface | none | workflow helper | production workflow | analysis sweeps |
| same | `aePlotSweepCp` | Invoke shared renderer | six physical sweeps; renderer test | plot-data builder; `plotSweepCpFigure` | workflow helper | production workflow | analysis sweeps |
| same | `aePlotGridSweepCp` | Plot all grid conditions | no maintained direct caller | shared plot limits | workflow helper | supported workflow | analysis sweeps |
| same | `aePlotGridSweepCpByAxis` | Static grouped grid figures | mu-IOP sweep | shared plot limits | workflow helper | production workflow | analysis sweeps |
| same | `aeWriteSweepOutputs` | CSV/MAT campaign output | all physical sweeps | output-folder helper | workflow helper | production workflow | analysis output |
| same | `aeSaveExampleFigure` | Save `.fig` and `.png` beside example | all physical sweeps | none | workflow helper | production workflow | analysis output |
| same | `aeDeleteExampleFigure` | Remove obsolete generated example figure | mu-IOP sweep | none | workflow helper | production workflow | analysis output |
| same | `aeOutputFolder` | Create canonical `Results/ae_iop_hgo/<task>` | examples, diagnostics, output writer | cross-model output resolver | workflow helper | production and diagnostic | analysis output |
| same | `aeResolveResultFile` | Read canonical then documented legacy result file | seven diagnostics | filesystem only | compatibility surface | diagnostic | analysis output compatibility |
| same | `aeBuildFitProblem` | Validate data, merge parameters, bounds, residual/objective closures | fit backend | shared fitting helpers; AE defaults/evaluator/policy | workflow helper | production workflow | analysis fitting |
| same | `aeEvaluateFitModel` | Prepare flat inputs and evaluate official `atlasA0` | fit problem, example, explicit curve, tests | AE atlas wrapper; sweep options; policy | workflow helper | production workflow | analysis fitting; configuration delegated to model |
| same | `aeFitDispersionData` | Optimizer dispatch, metrics, sensitivity, fit result | FitTool adapter, fitting example/tests | fit problem; shared fit quality helpers | workflow helper | production workflow | analysis fitting |
| same | `summarizeAcoustoelasticIOPHGOTrackingQuality` | Cross-result tracking summary | no maintained direct caller | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeAnalyzeSweepReliability` | Truncation, consistency, monotonicity analysis | reliability diagnostic | sweep summary | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeAnalyzeTruncationRecovery` | Diagnostic recovery candidates | persistence/truncation analyzers and test | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeAnalyzeFirstUnrecoveredBreak` | Inspect first unrecovered break and local minima | no maintained direct caller | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeAnalyzeBranchPersistenceCandidates` | Enrich persistence candidates | truncation diagnosis; refinement | truncation recovery | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeRefineAtlasA0BranchPersistence` | Diagnostic persistence classification | focused test | persistence analyzer | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeClassifyTruncationRecovery` | Classify truncation/recovery summaries | no maintained direct caller | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeClassifyAmbiguityRegime` | Classify difficult AE parameter regime | path contract; no maintained computation caller | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeDiagnoseAtlasA0TruncationCause` | Assemble causal truncation evidence | `diagnose_atlas_truncation` | recovery and persistence analyzers | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeExtractRawBranch1Candidate` | Resolve/build raw branch-1 candidate and tracker comparison | raw-branch commands | output compatibility; IOP/HGO direct solver; defaults | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeComputeModalAtlasForCase` | Shared diagnostic atlas computation | modal-atlas diagnostic | real residual; diagnostic minima/link helpers | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeFindTopModalAtlasLocalMinima` | Diagnostic local-minimum extraction | modal-atlas helper | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeLinkModalAtlasMinimaIntoBranches` | Diagnostic branch linking | modal-atlas helper | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeDefaultIdentityA0ValidationParams` | Shared heavy-validation physical defaults | two identity grid validators | none | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeDefaultIdentityA0ValidationOptions` | Shared heavy-validation solver options | two identity grid validators | public AE defaults | diagnostic-only | diagnostic | analysis diagnostics |
| same | `aeDefaultIdentityA0ValidationGrid` | Shared 110-case identity grid | two identity grid validators | none | diagnostic-only | diagnostic | analysis diagnostics |

The six analysis helpers with no current direct computation caller remain
tracked, path-checked, or documented. Phase 6 must decide retention from actual
repeatable value; Phase 1 does not delete them.

### Executable examples: 22 files

| Current folder | MATLAB identifier | Responsibility | Direct callers | Direct repository dependencies | Classification | Production/diagnostic | Future owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `basic/` | `run_atlas_branch` | Minimal official branch run, MAT/PNG output | user | defaults; atlas wrapper; output folder | public production API | production example | `examples/.../basic/` |
| `fitting/` | `fit_ae_atlasA0` | Synthetic official-branch fitting example | user | defaults; evaluator; fit backend | public production API | production example | `examples/.../fitting/` |
| `sweeps/` | `ae_sweep_iop_A0Like` | Robust IOP campaign and outputs | user | shared AE sweep stack | public production API | production example | `examples/.../sweeps/` |
| same | `ae_sweep_mu_A0Like` | Robust mu campaign and outputs | user | shared AE sweep stack | public production API | production example | same |
| same | `ae_sweep_thickness_A0Like` | Robust thickness campaign and outputs | user | shared AE sweep stack | public production API | production example | same |
| same | `ae_sweep_k1_A0Like` | Robust k1 campaign and outputs | user | shared AE sweep stack | public production API | production example | same |
| same | `ae_sweep_k2_A0Like` | Robust k2 campaign and outputs | user | shared AE sweep stack | public production API | production example | same |
| same | `ae_sweep_radius_A0Like` | Robust radius campaign and outputs | user | shared AE sweep stack | public production API | production example | same |
| same | `ae_sweep_mu_iop_A0Like` | Robust two-axis campaign, static and interactive displays | user | grid sweep/summary/output/plot helpers; app interactive surface | public production API | production example | same |
| `diagnostics/` | `compare_atlasA0_vs_raw_branch1` | Compare official, identity, and raw branch-1 curves | user | branch API; raw extractor; output compatibility | diagnostic-only | diagnostic | `examples/.../diagnostics/` |
| same | `validate_atlas_raw_grid` | Multi-case atlas/raw validation | user | branch API; constitutive/residual logic; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_raw_branch_corner` | Difficult-corner raw branch study | user | branch API; constitutive/residual logic; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_branch_families` | Branch-family ambiguity study | user | branch API; constitutive/residual logic; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_grid_start_sensitivity` | Requested/internal grid start sensitivity | user | branch API; defaults; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_sweep_reliability` | Analyze saved sweep reliability | user | result fallback; reliability analyzer; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_atlas_truncation` | Analyze saved sweep truncation cause | user | result fallback; truncation analyzer; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_idA0_score` | Score saved branch-identity candidates | user | result fallback; score helper; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_idA0_plausibility` | Interpret saved identity-grid plausibility | user; depends on `validate_idA0_grid` output | result fallback; output helper | diagnostic-only | diagnostic | same |
| same | `diagnose_modal_atlas` | Low-frequency modal atlas and direct-tracker comparison | user | modal-atlas helper; direct IOP/HGO solver; constitutive helper | diagnostic-only | diagnostic | same |
| same | `track_raw_branch1` | Thin raw-branch extraction command | user | raw extractor | diagnostic-only | diagnostic | same |
| same | `validate_idA0_score_grid` | Heavy identity-score grid | user | shared identity defaults; branch API; score helper | diagnostic-only | diagnostic | same |
| same | `validate_idA0_grid` | Heavy official/identity parity grid | user | shared identity defaults; branch API | diagnostic-only | diagnostic | same |

### Model tests: 17 files

| Current folder | MATLAB identifier | Responsibility | Canonical owner | Direct dependencies | Classification | Future owner |
| --- | --- | --- | --- | --- | --- | --- |
| `tests/models/acoustoelastic_iop_hgo/` | `test_acoustoelastic_iop_hgo_branch_policy_validation` | Canonical and rejected policy names | `run_ae_quick_tests` | defaults; policy normalizer | test or validation owner | model policy tests |
| same | `test_ae_configuration_characterization` | Pre-extraction defaults, profiles, surfaces, overrides, validation, and metadata baseline | `run_ae_quick_tests` | maintained public/workflow/app surfaces | test or validation owner | configuration regression tests |
| same | `test_ae_configuration_ownership` | Canonical presets, effective config, validation, and exact grid cases | `run_ae_quick_tests` | four model configuration owners | test or validation owner | configuration tests |
| same | `test_acoustoelastic_iop_hgo_constitutive_identity` | IOP/HGO constitutive identity | `run_ae_quick_tests` | constitutive builder | test or validation owner | constitutive tests |
| same | `test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy` | Official-field parity and diagnostic separation | `run_ae_quick_tests` | primary branch API | test or validation owner | diagnostic-boundary tests |
| same | `test_acoustoelastic_iop_hgo_branch_persistence_refinement` | Persistence diagnostic contract | `run_ae_quick_tests` | persistence refinement helper | test or validation owner | diagnostic tests |
| same | `test_ae_analyze_truncation_recovery` | Recovery analysis contract | `run_ae_quick_tests` | truncation recovery helper | test or validation owner | diagnostic tests |
| same | `test_ae_physical_sweep_examples_contract` | Campaign values, paths, owners, removed commands | `run_ae_quick_tests` | source/path inspection; sweep helpers | test or validation owner | workflow tests |
| same | `test_acoustoelastic_iop_hgo_short_entrypoints` | Maintained and absent command names/docs | `run_ae_quick_tests` | path/docs inspection | test or validation owner | route/naming tests |
| same | `test_acoustoelastic_iop_hgo_fallback_invalidation` | Official fallback invalidation | `run_ae_extended_tests` | atlas wrapper | test or validation owner | policy/result tests |
| same | `test_acoustoelastic_iop_hgo_internal_tracking_grid` | Internal/requested-grid contract | `run_ae_extended_tests` | atlas wrapper | test or validation owner | configuration/tracking tests |
| same | `test_acoustoelastic_iop_hgo_atlasA0_smoke` | Representative atlas solve | `run_ae_extended_tests` | atlas wrapper | test or validation owner | solver regression tests |
| same | `test_ae_fit_synthetic_atlasA0` | Synthetic fit and evaluator parity | `run_ae_extended_tests` | fit/evaluator/defaults | test or validation owner | fitting tests |
| same | `test_ae_result_schema_characterization` | Exact atlas/wrapper/result/quality/diagnostic schema and workflow surfaces | `run_ae_extended_tests` | canonical result/quality owners and maintained workflows | test or validation owner | result regression tests |
| same | `test_ae_result_ownership` | Canonical result/quality ownership and model-to-analysis boundary | `run_ae_extended_tests` | model source/path inspection | test or validation owner | result ownership tests |
| same | `test_ae_tracking_policy_characterization` | Pre-extraction profiles, objective/grid/minima/link/selection/fallback path | `run_ae_extended_tests` | maintained public solver result only | test or validation owner | tracking/policy regression tests |
| same | `test_ae_tracking_policy_ownership` | Canonical owner paths, removed local implementations, and focused helper contracts | `run_ae_extended_tests` | six Phase-4 owners; source/path inspection | test or validation owner | tracking/policy ownership tests |

### Documentation: 16 files

| Current folder | Document | Responsibility/evidence | Direct document consumers | Direct dependencies | Classification | Future owner |
| --- | --- | --- | --- | --- | --- | --- |
| `docs/models/acoustoelastic_iop_hgo/` | `docs/models/acoustoelastic_iop_hgo/README.md` | Model routing index and official status | users; project routing | active contracts and diagnostic index | documentation owner | model index |
| `active/` | `docs/models/acoustoelastic_iop_hgo/active/public_api.md` | Supported APIs, workflows, diagnostics, tests | users; path contract test | maintained entrypoint/naming contracts | documentation owner | API contract |
| same | `docs/models/acoustoelastic_iop_hgo/active/branch_policy.md` | Official `atlasA0`, grids, filters, splitting, fallback, reliability | production/workflow docs | public API and diagnostic evidence | documentation owner | policy contract |
| same | `docs/models/acoustoelastic_iop_hgo/active/sweep_workflow.md` | Physical campaigns, shared flow, outputs | users; sweep contract | branch policy; repository sweep/naming contracts | documentation owner | workflow contract |
| same | `docs/models/acoustoelastic_iop_hgo/active/fitting_workflow.md` | Official fitting route and limits | users; fitting contract | branch policy; shared fitting architecture | documentation owner | workflow contract |
| same | `docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md` | Separate high-frequency waviness issue | future numerical work | branch policy | documentation owner | bounded pending numerical work |
| same | `docs/models/acoustoelastic_iop_hgo/active/architecture_audit.md` | Current audit, target map, naming, phases | future AE phases | all contracts cited in this document | documentation owner | architecture contract until finalization |
| `diagnostics/` | `docs/models/acoustoelastic_iop_hgo/diagnostics/README.md` | Diagnostic evidence index | users | eight evidence documents; branch policy | documentation owner | diagnostic index |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/atlas_vs_raw_branch1_diagnostic.md` | Raw comparison interpretation | diagnostic users | comparison/grid/corner commands | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/branch_families_diagnostic.md` | Ambiguity interpretation | diagnostic users | branch-family command | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/atlasA0_truncation_cause_diagnostic.md` | Truncation causal schema | diagnostic users | truncation command | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/identityA0_diagnostic_policy.md` | Identity diagnostic safety/schema | diagnostic users and test | identity option/test | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/branch_identity_score_diagnostic.md` | Score components/classes | diagnostic users | score command | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/branch_identity_score_grid_validation.md` | 110-case score interpretation | diagnostic users | score-grid command | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/identityA0_diagnostic_grid_validation.md` | Official parity/extension evidence | diagnostic users | identity-grid command | documentation owner | diagnostic evidence |
| same | `docs/models/acoustoelastic_iop_hgo/diagnostics/identityA0_physical_plausibility_diagnostic.md` | Plausibility and caution boundary | diagnostic users | plausibility command | documentation owner | diagnostic evidence |

The count of 15 existing documents becomes 16 after this audit document is
added; the 101-file baseline above is the pre-audit tracked inventory.

### AE-specific app and cross-layer integration owners

These files are not additional AE physics owners. They are the direct
integration surface required to understand maintained calls.

| Layer/file | Responsibility | Direct caller/owner | Direct AE dependencies | Classification | Target |
| --- | --- | --- | --- | --- | --- |
| `app/adapters/guiBuildAcoustoelasticIOPHGORequest.m` | Main GUI unit/request translation | `LambFundamental_GUI` | frequency builder; AE GUI options builder | app adapter | retain; translate UI only |
| `app/adapters/guiBuildAcoustoelasticIOPHGOOptions.m` | Main GUI profile wrapper | request builder | AE profile resolver | app adapter | retain thin metadata wrapper |
| `app/adapters/aeResolveExecutionProfile.m` | App profile normalization and model-configuration metadata translation | all AE app adapters; tests | canonical model configuration; generic profile helpers | app adapter | retained thin metadata adapter |
| `app/adapters/guiRunAcoustoelasticIOPHGOModel.m` | Select Main GUI surface, solve, and normalize raw result | `LambFundamental_GUI`; GUI/profile tests | canonical model configuration; primary AE API; struct helpers | app adapter | retained without numerical values |
| `app/adapters/guiRunAcoustoelasticIOPHGOSweep.m` | SweepTool request defaults, run, normalization, metadata | `guiRunSweep`; sweep/profile tests | AE sweep stack; profile resolver | app adapter | retain orchestration; delegate physical/numerical configuration |
| `app/adapters/guiNormalizeAcoustoelasticIOPHGOSweep.m` | Normalize official curves and summary | AE SweepTool adapter | none beyond result schema | app adapter | retain |
| `app/adapters/guiFitAcoustoelasticIOPHGOSolver.m` | FitTool request, profile/options, backend call, normalization | `guiRunFit`; fitting/profile tests | profile resolver; AE fit backend; generic fit helpers | app adapter | retain orchestration; delegate numerical configuration |
| `app/sweep/aePlotGridSweepFrequencySurfaceInteractive.m` | Interactive UI state and slider | mu-IOP example | `aeBuildGridSweepCpCube` | app adapter | retain in app/sweep |
| `analysis/execution_profiles/validateExecutionProfileMatrix.m` | Reproducible cross-surface AE/RL/mRLFE profile matrix | integration tests/manual command | AE Main/Sweep/Fit adapters | test or validation owner | retain |
| `app/LambFundamental_GUI.m` | User-facing Main GUI dispatch | user | AE request/model adapters | app adapter | generic surface retained |
| `app/SweepTool_GUI.m`; `app/sweep/guiBuildSweepRequest.m`; `app/sweep/guiRunSweep.m` | User-facing sweep request and dispatch | user | AE sweep adapter | app adapter | generic surface retained |
| `app/FitTool_GUI.m`; `app/fitting/guiBuildFitRequest.m`; `app/fitting/guiRunFit.m`; `app/fitting/guiNormalizeFitResult.m`; `app/fitting/guiEvaluateRequestedFitCurve.m` | User-facing fit request, dispatch, normalization, explicit curve | user | AE fit adapter/evaluator | app adapter | generic surface retained |
| `tests/app/gui/test_gui_acoustoelastic_iop_hgo_main_adapter_smoke.m` | Main GUI AE adapter smoke | `run_gui_quick_tests` | Main adapter | test or validation owner | app integration tests |
| `tests/app/sweeps/test_gui_acoustoelastic_iop_hgo_sweep_adapter_smoke.m` | AE SweepTool smoke | `run_gui_quick_tests` | sweep dispatcher/adapter | test or validation owner | app integration tests |
| `tests/app/sweeps/test_gui_sweep_adapters_smoke.m`; `test_gui_sweep_registry_smoke.m` | Cross-family registry/adapter contracts including AE | `run_gui_quick_tests` | AE sweep route | test or validation owner | app integration tests |
| `tests/app/fitting/test_gui_fit_registry_contract.m`; `test_fit_tool_requested_curve_models.m`; `test_fit_tool_interaction_helpers.m` | AE registry, fitting, requested-curve behavior | GUI quick/interaction/requested-curve runners | AE fit route | test or validation owner | app fitting tests |
| `tests/app/execution_profiles/test_model_execution_profile_resolvers.m`; `test_execution_profile_surface_metadata.m`; `test_execution_profile_surface_integration.m`; `test_execution_profile_fit_curve_metadata.m`; `test_execution_profile_validation_matrix.m` | AE profile mapping and metadata across surfaces | execution-profile runners | AE profile/adapters | test or validation owner | profile integration tests |
| `tests/shared/fitting/test_fit_validation_ae_iop_hgo.m`; `test_fit_validation_ae_iop_hgo_hidden_params.m` | App/backend fitting validation | `run_fit_validation_tests` | AE fit route | test or validation owner | shared fitting tests |
| `tests/shared/sweeps/test_sweep_plot_renderer_contract.m` | AE neutral-renderer boundary | `run_ae_quick_tests` | AE plot-data/rendering | test or validation owner | shared sweep tests |
| `tests/shared/regression/test_lightweight_numerical_regression.m` | Lightweight AE/RL regression | core numerical regression runner | AE atlas wrapper | test or validation owner | shared regression |
| `tests/runners/run_ae_quick_tests.m` | Canonical seven AE quick owners plus renderer | quick-smoke aggregates | listed quick tests | test or validation owner | AE runner |
| `tests/runners/run_ae_extended_tests.m` | Canonical four AE numerical owners | numerical/extended aggregates | listed extended tests | test or validation owner | AE runner |
| `tests/runners/run_acoustoelastic_smoke_tests.m` and public wrapper | Maintained AE path checks and quick+extended aggregate | `run_all_smoke_tests` | AE runners and identifiers | test or validation owner | AE aggregate; wrapper remains compatibility surface |

## Current maintained call graphs

The graphs below name actual calls observed in source. A bracketed item is a
responsibility performed as a local function in the named file.

### Basic AE execution

```text
run_atlas_branch
  -> [flat SI params + explicit 300/12 atlas options]
  -> solveAcoustoelasticIOPHGOAtlasBranch
       -> aeValidateRequest
       -> aeResolveConfiguration
       -> computeAcoustoelasticABGFromIOPHGO
            -> computeAcoustoelasticPrestressSigma
            -> solveAcoustoelasticHGOStretch
            -> computeAcoustoelasticAlphaBetaGamma
       -> aeBuildInternalTrackingGrid
       -> solveAcoustoelasticAtlasBranch
            -> objectiveAcoustoelasticResidual
                 -> buildAcoustoelasticMatrix
                      -> computeAcoustoelasticSRoots
            -> [localMinima -> linkBranches -> splitBranchesOnLargeCpJump]
            -> [selectBranch: A0 start filter and fallback selection]
            -> [assignCpFromBranch]
            -> [summarizeReliability -> summarizeResult]
       -> [restrictResultToRequestedFrequency]
       -> [invalidateFallbackOutputIfNeeded]
  -> aeOutputFolder
  -> MAT workspace + PNG
```

Official output is `result.Cp`/`result.validCp`. `identityA0` is only built
when explicitly requested, but the model solver currently calls an analysis
diagnostic helper to do so.

### Main GUI AE execution

```text
LambFundamental_GUI
  -> guiBuildAcoustoelasticIOPHGORequest
       -> [UI units to flat SI params]
       -> rlBuildFrequencyVector
       -> guiBuildAcoustoelasticIOPHGOOptions
            -> aeResolveExecutionProfile
                 -> guiNormalizeExecutionProfile
                 -> aeResolveConfiguration
  -> guiRunAcoustoelasticIOPHGOModel
       -> defaultAcoustoelasticIOPHGOOptions + guiMergeStructs
       -> guiNormalizeExecutionProfile
       -> aeResolveConfiguration(surface = MainGUI)
       -> solveAcoustoelasticIOPHGOBranch
       -> [wavenumber, k-thickness, branch/result/diagnostic normalization]
  -> lastGuiResult for plotting
  -> guiBuildMainResultExport/guiSaveMainResultExport when requested
```

The app translates units and selects a surface/profile. Numerical values are
resolved by the model configuration owner.

### SweepTool AE execution

```text
SweepTool_GUI
  -> guiGetSweepRegistry
  -> guiBuildSweepRequest
  -> guiRunSweep
  -> guiRunAcoustoelasticIOPHGOSweep
       -> [buildAcoustoelasticBaseParams: defaults and 35-point grid]
       -> [buildAcoustoelasticOptions]
            -> aeResolveExecutionProfile -> aeDefaultSweepOptions
            -> [control overrides and repeated preset metadata inference]
       -> aeRunSweep
            -> solveAcoustoelasticIOPHGOBranch per point
       -> aeSummarizeSweep
       -> guiNormalizeAcoustoelasticIOPHGOSweep
  -> guiPlotSweepResult
  -> SweepTool workspace exports when requested
```

SweepTool does not write the physical-campaign CSV/MAT files used by example
sweeps; it exports normalized/raw app state.

### FitTool AE fitting

```text
FitTool_GUI
  -> guiBuildFitRequest
  -> guiRunFit
  -> guiFitAcoustoelasticIOPHGOSolver
       -> guiBuildFitRequest (canonicalize)
       -> aeNormalizeBranchPolicy; require atlasA0
       -> aeResolveExecutionProfile -> aeDefaultSweepOptions
       -> [legacy explicit atlas-density/init overrides + repeated metadata]
       -> aeFitDispersionData
            -> aeBuildFitProblem
                 -> validateExperimentalDispersionData
                 -> aeDefaultSweepParams / aeDefaultSweepOptions
                 -> shared parameter/residual helpers
                 -> aeEvaluateFitModel
                      -> [required flat-parameter and frequency validation]
                      -> solveAcoustoelasticIOPHGOAtlasBranch
            -> optimizer -> metrics -> sensitivity/identifiability
       -> guiNormalizeFitResult
       -> guiBuildFitDisplayCurve (no solver call)
  -> guiPlotFitResult
```

The explicit **Evaluate fitted curve** route is:

```text
guiEvaluateRequestedFitCurve
  -> aeEvaluateFitModel(final parameters, requested frequency)
  -> solveAcoustoelasticIOPHGOAtlasBranch
```

### Maintained physical sweeps

The six one-parameter scripts differ only in campaign definition:

```text
ae_sweep_<parameter>_A0Like
  -> aeDefaultSweepParams
  -> aeDefaultSweepOptions("Robust")
  -> aeRunSweep -> solveAcoustoelasticIOPHGOBranch per condition
  -> aeSummarizeSweep
  -> aeWriteSweepOutputs
       -> aeOutputFolder
       -> condition, dispersion, selected-branch CSV + MAT workspace
  -> aePlotSweepCp -> aeBuildSweepPlotData -> plotSweepCpFigure
  -> aeSaveExampleFigure -> FIG + PNG
```

The two-parameter route is:

```text
ae_sweep_mu_iop_A0Like
  -> same defaults
  -> aeRunGridSweep -> solveAcoustoelasticIOPHGOBranch per condition
  -> aeSummarizeGridSweep -> aeWriteSweepOutputs
  -> aePlotGridSweepCpByAxis -> aeSaveExampleFigure
  -> aePlotGridSweepFrequencySurfaceInteractive
       -> aeBuildGridSweepCpCube
  -> interactive figure displayed but not automatically saved
```

### Diagnostic scripts

| Entrypoint(s) | Actual core path | Input/output |
| --- | --- | --- |
| `compare_atlasA0_vs_raw_branch1` | branch API for official/identity plus `aeExtractRawBranch1Candidate` | reads/builds raw curve; writes CSV/MAT |
| `validate_atlas_raw_grid`, `diagnose_raw_branch_corner`, `diagnose_branch_families` | branch API plus script-local duplicated raw atlas minima/link logic and direct residual calls | writes CSV/MAT under canonical results |
| `diagnose_grid_start_sensitivity` | branch API over grid-start cases | writes CSV/MAT |
| `diagnose_sweep_reliability` | `aeResolveResultFile -> aeAnalyzeSweepReliability` | reads saved sweeps; writes CSV/MAT |
| `diagnose_atlas_truncation` | `aeResolveResultFile -> aeDiagnoseAtlasA0TruncationCause -> recovery/persistence helpers` | reads saved sweeps; writes CSV/MAT/plots |
| `diagnose_idA0_score` | saved sweep -> `aeScoreBranchIdentityCandidates` | writes candidate/summary CSV/MAT |
| `validate_idA0_score_grid` | shared diagnostic defaults -> branch API -> score helper | writes heavy-grid CSV/MAT |
| `validate_idA0_grid` | shared diagnostic defaults -> branch API for official/identity | writes parity/extension CSV/MAT |
| `diagnose_idA0_plausibility` | `aeResolveResultFile` for identity-grid workspace | writes plausibility CSV/MAT |
| `diagnose_modal_atlas` | constitutive conversion -> `aeComputeModalAtlasForCase`; direct IOP/HGO solver for tracker matches | writes atlas/tracker CSV/MAT |
| `track_raw_branch1` | `aeExtractRawBranch1Candidate` | writes extractor-owned outputs |

The duplicated script-local raw atlas algorithms are diagnostic-only. They
must not be promoted into production simply to reduce line count.

### Test runners

```text
run_quick_smoke_tests
  -> run_ae_quick_tests
       -> policy, recovery, persistence, constitutive, sweep-source,
          shared-renderer, identity-diagnostic, and naming contracts

run_numerical_regression_tests / run_extended_integration_tests
  -> run_ae_extended_tests
       -> fallback invalidation, internal grid, atlas smoke, synthetic fit

run_acoustoelastic_smoke_tests (public wrapper -> canonical runner)
  -> path/absence inventory checks
  -> run_ae_quick_tests
  -> run_ae_extended_tests

run_all_smoke_tests
  -> run_acoustoelastic_smoke_tests
  -> GUI/shared aggregates that also cover AE integration
```

`run_quick_contract_tests` does not own the numerical AE model tests, but it
does cover repository hygiene, profile contracts, and shared contracts that
constrain the proposed architecture.

## mRLFE responsibility reference

| Responsibility | Current mRLFE owner/pattern |
| --- | --- |
| API | `api/mrlfeSolve`, defaults, and validation form one public request boundary. |
| Configuration | `configuration/mrlfeResolveConfiguration` merges defaults, validates, resolves preset and effective engine. |
| Options and presets | Public options/defaults remain separate from `mrlfeGetNumericalPreset`; numerical preset is not branch policy. |
| Problem construction | `core/mrlfeBuildProblem` owns requested/internal grids, seed dependency, and physical problem fields. |
| Constitutive/physical core | `core/mrlfeMatrix`, residual, and objective own equations only. |
| Solver dispatch | `solvers/mrlfeSolveBranch` dispatches explicit elastic/viscoelastic engines. |
| Tracking | `tracking/mrlfeBuildSeed`, adaptive tracker, and robust-start helper own continuation. |
| Policies | `policies/mrlfeApplyTerminationPolicy` and physical-tail evaluator own named termination. |
| Quality | `quality/mrlfeEvaluateBranchQuality` owns acceptance metrics and thresholds. |
| Results | `results/mrlfeBuildInternalBranchResult` and `mrlfeBuildResult` own stable public and unstable debug boundaries. |
| Analysis workflows | `analysis/mrlfe/` owns fit/sweep requests, campaigns, summaries, output, and analysis. |
| App adapters | App files translate UI and normalize results; they do not select trackers or numerical internals. |
| Examples | Basic/fitting/sweep/diagnostic scripts call maintained APIs and analysis workflows. |
| Diagnostics | Diagnostics inspect the public route or explicit analysis helpers; they are not production dependencies. |
| Tests | Public-contract, production-core, helper, consumer, route-integrity, and aggregate runners have explicit ownership. |
| Documentation | `README`, public API, production core, fitting, sweeps, diagnostics, and validation contracts link rather than duplicate. |

## Responsibility comparison and alignment decision

| Responsibility | mRLFE ownership | Current AE ownership | State | Physical justification | Alignment | Risk |
| --- | --- | --- | --- | --- | --- | --- |
| API | One `mrlfeSolve` request API | Several supported long scientific solvers; one recommended convenience route | mixed | Direct alpha/beta/gamma and complex-C scientific APIs are legitimate | Keep scientific APIs; make `solveAcoustoelasticIOPHGOBranch` the one production consumer route | moderate |
| Configuration | Model resolver | `aeResolveConfiguration`, `aeGetNumericalPreset`, and `aeValidateRequest` own effective options, values, and maintained checks | equivalent after Phase 2 | none | retain flat public API; no request-struct rewrite | low |
| Options/presets | Separate public options and preset lookup | One large default struct plus analysis-local profile switch and GUI overrides | mixed | AE has atlas-specific values, not app-specific ownership | add explicit model preset owner; preserve values | low-moderate |
| Problem construction | Explicit model builder | constitutive conversion and internal-grid construction inside IOP/HGO wrapper | mixed | AE constitutive conversion is unique | extract only if it reduces duplication; keep AE physics explicit | moderate |
| Physical core | Model core | model `constitutive/` and `core/` | equivalent | yes | retain | low |
| Solver dispatch | Neutral dispatcher and engines | convenience wrapper delegates only to atlas; advanced direct/complex solvers are separate | partly equivalent | multiple scientific algorithms are legitimate | document primary versus advanced; avoid artificial dispatch abstraction | low |
| Atlas construction | Solver/problem functions | objective map and result setup in 554-line atlas solver | mixed | atlas is AE-specific | keep model-owned; separate construction from result/policy | high |
| Local minima | Tracking helper | local functions in production solver; duplicate variants in diagnostics | mixed | diagnostic experiments may differ intentionally | extract production helper only; retain labeled diagnostic variants | high |
| Branch linking | Tracking helper | local production linker plus diagnostic helper/script copies | mixed | experimental modes/configs justify diagnostic copies | one production owner; diagnostics remain explicit | high |
| Branch splitting | Tracking/policy boundary | local production function | mixed | AE jump split is physics/numerics-specific | explicit model tracking owner, exact parity | high |
| A0 start filtering/selection | Named model policy | local `selectBranch` | mixed | AE-specific and justified | explicit `atlasA0` policy owner | high |
| Internal/requested grids | problem/configuration | local wrapper builder/projection; fit evaluator also validates grid | mixed | separate grids are essential AE behavior | centralize construction/validation; preserve exact grids | moderate-high |
| Fallback invalidation | policy/result | local IOP/HGO wrapper mutates all public, reliability, diagnostic fields | mixed | conservative invalidation is essential | explicit policy followed by one result builder | high |
| Reliability/quality | quality owner | two local summary builders plus post-invalidation mutation | mixed | AE schema differs legitimately | one model quality owner per requested output | moderate-high |
| Result schema | result builders | constructed/mutated across atlas solver and wrapper; app re-normalizes | mixed | AE schema legitimately differs | explicit stable result/debug builder; no schema change | moderate-high |
| Diagnostics/debug | debug boundary; analysis diagnostics | production model calls analysis identity diagnostic and returns full atlas internals at top level | misplaced | diagnostic evidence is legitimate; dependency direction is not | remove model-to-analysis dependency and define explicit debug boundary | moderate-high |
| Fitting request | analysis builders, public solver | generic request in app; AE problem/evaluator in analysis; config repeated | partly equivalent | flat AE parameters are legitimate | preserve fitting architecture; delegate config only | moderate |
| Sweep request | analysis builders and public solver | examples are thin; SweepTool adapter builds physical/default/numerical request | mixed | unit translation belongs in app | move physical campaign defaults to analysis and numerical config to model | moderate |
| Output/result files | analysis output helper | canonical writer plus bounded legacy-read helper | equivalent | diagnostic reproducibility justifies legacy read | retain compatibility surface until fixtures migrate | low |
| App adapters | translation/normalization only | translation plus numerical override/preset inference | misplaced | none | thin after model config exists | moderate |
| Tests/docs | explicit route/core contracts | strong behavior tests but no explicit AE production-core/config/result contract | gap | none | add focused characterization before each extraction | low |

Different AE function names and its constitutive/atlas concepts are not
themselves problems. The problems are duplicated authority, reversed layer
dependencies, and result/policy mutation spread across owners.

## Phase 1 findings and implemented dispositions

1. **Configuration and numerical presets were cross-layer.** Resolved in
   Phase 2 by `aeResolveConfiguration` and `aeGetNumericalPreset`; analysis and
   app layers now select a profile/surface without defining numerical values.
2. **Main GUI owned solver numerics.** Resolved in Phase 2: the exact bundle is
   model-owned and explicit complete GUI options retain their established
   override precedence.
3. **Request validation was duplicated.** The maintained IOP wrapper, direct
   atlas wrapper, and fitting evaluator now delegate their existing checks to
   `aeValidateRequest`. Other solver-family validation is outside Phase 2.
4. **Requested/internal frequency ownership was mixed.** Grid construction is
   now owned by `aeBuildInternalTrackingGrid`; requested-grid projection stays
   in the wrapper because result ownership is Phase 3.
5. **Atlas, tracking, selection, quality, and result construction were one
   file.** Resolved in Phases 3 and 4. Atlas construction, production minima,
   linking, splitting, selection, result, and requested-grid quality now have
   one canonical model owner each. `solveAcoustoelasticAtlasBranch` retains
   orchestration and selected-branch assignment only.
6. **Diagnostic code was a production-layer dependency on `analysis/`.**
   Resolved in Phase 3 by moving the explicitly requested diagnostic identity
   builder/scorer behind model-owned diagnostic result helpers. Production
   tracking remains distinct and has no `analysis/` dependency.
7. **Diagnostic atlas logic is duplicated.**
   `aeComputeModalAtlasForCase` centralizes one route, but
   `validate_atlas_raw_grid`, `diagnose_raw_branch_corner`, and
   `diagnose_branch_families` retain script-local minima/link algorithms.
   This is acceptable only while they remain explicitly diagnostic variants;
   it is not a second production tracker.
8. **Fallback invalidation mixed policy, quality, and schema ownership.**
   Resolved in Phases 3 and 4. `aeApplyAtlasA0FallbackPolicy` changes only the
   already-decided official fields and preserves diagnostic candidate evidence;
   `aeBuildResult` and `aeEvaluateAtlasA0Quality` then rebuild their own data.
9. **Reliability was constructed in multiple local paths.** Resolved in Phase
   3 by the single `aeEvaluateAtlasA0Quality` owner invoked through
   `aeBuildResult` for tracking-grid, requested-grid, and fallback decisions.
10. **Result normalization remains layered but is now bounded.** The model returns
    public fields and large diagnostic internals at the same top level; Main
    GUI builds another raw-compatible branch; SweepTool and FitTool build
    different normalized shapes. App normalization is legitimate, but the
    model needs a clear stable public/debug split first.
11. **Fitting request construction crosses app and analysis.** The app
    canonicalizes the generic request and resolves numerical options;
    `aeBuildFitProblem` merges physical defaults and creates objectives;
    `aeEvaluateFitModel` revalidates and forces policy/defaults. Optimizer and
    shared fitting ownership are correct; model configuration is not.
12. **Sweep request construction differs by surface.** Physical examples use
    `aeDefaultSweepParams`/`aeDefaultSweepOptions`; SweepTool locally duplicates
    physical defaults and its 35-point grid. Unit conversion is an app duty;
    default physical/numerical ownership should be reusable and explicit.
13. **Output writing is correctly analysis-owned, with bounded debt.**
    `aeWriteSweepOutputs` and `aeOutputFolder` are correctly outside models.
    `aeResolveResultFile` and raw-extractor legacy names are compatibility
    reads for diagnostics, not alternate production output conventions.

## Target AE responsibility map

All ten model folders are justified by maintained responsibilities; none is
speculative or empty in the proposed end state.

```text
models/acoustoelastic_iop_hgo/
|-- api/             primary production entrypoint and public validation boundary
|-- configuration/   merge/validate flat inputs, resolve exact numerical preset,
|                    construct requested/internal grids
|-- constitutive/     IOP/HGO prestress, stretch, alpha/beta/gamma
|-- core/             matrix, roots, residual, objective
|-- options/          public defaults and option vocabulary
|-- policies/         atlasA0 selection, start filter, interpolation rule,
|                    fallback invalidation decision
|-- quality/          requested-grid reliability and quality summaries
|-- results/          stable public schema and explicit debug/diagnostic payload
|-- solvers/          atlas/direct/complex algorithm orchestration
`-- tracking/         production minima extraction, linking, splitting, assignment
```

This is a responsibility map, not authorization to move all files at once.
The smallest safe extraction is preferred in each phase. `analysis/` continues
to own fitting, campaigns, summaries, figures, files, and diagnostics. `app/`
continues to own unit translation, UI state, surface metadata, normalization,
plotting, and export.

Target production flow:

```text
app/example/analysis consumer
  -> solveAcoustoelasticIOPHGOBranch(params, options)
       -> aeResolveConfiguration
       -> aeBuildProblem
       -> AE solver/tracker/policy owners
       -> aeEvaluateAtlasA0Quality
       -> aeBuildResult
```

The current flat `params, options` public shape is retained initially. A new
request struct is not required for architectural alignment and would add risk
without solving current ownership problems.

Rejected alternatives:

- copying the mRLFE folder tree without extracting real responsibility;
- renaming long AE scientific APIs only for visual symmetry;
- promoting identity/raw/family diagnostics into production;
- putting campaign output or GUI metadata in the model layer;
- preserving old/new names with forwarding aliases;
- combining tracking extraction with numerical refinement of Cp waviness.

## Stable repository-wide AE naming plan

Rules for every later phase:

1. Keep `solveAcoustoelastic*` for supported scientific solver entrypoints
   where the explicit physical name is useful.
2. Use `ae*` for new model internals and AE analysis/workflow helpers.
3. Use `gui*` only for app-layer request/result/UI adapters; the existing
   `aeResolveExecutionProfile` remains an allowed model-specific app adapter.
4. Use `run_*` for basic executable examples/runners, `ae_sweep_*` for AE
   campaigns, `test_*` for tests, and `diagnose_*`/`validate_*`/`compare_*`
   for diagnostics.
5. Give each responsibility one canonical identifier. A direct rename in its
   approved phase updates every caller and removes the old name; no forwarding
   alias or parallel old/new implementation is allowed.
6. A proposed name in this document is not current and must not be documented
   as callable until its implementation phase lands.

### Proposed canonical-name table

| Responsibility | Current owner/name | Proposed canonical owner/name | Status | Reason | Phase | Compatibility requirement |
| --- | --- | --- | --- | --- | --- | --- |
| Primary production solve | `solvers/solveAcoustoelasticIOPHGOBranch` | `api/solveAcoustoelasticIOPHGOBranch` | public | Existing explicit name is suitable | 4 or 6 | Direct move only; command and behavior unchanged |
| Public options | `options/defaultAcoustoelasticIOPHGOOptions` | retain | public | Existing scientific API is suitable | 2 | Exact fields/values unchanged |
| Request/config validation | repeated local checks | `configuration/aeValidateRequest` | internal | One stable model owner | 2 | Preserve accepted/rejected inputs first; stable identifiers may be added with tests |
| Configuration resolution | model/analysis/app mix | `configuration/aeResolveConfiguration` | internal | Mirrors responsibility, not mRLFE syntax | 2 | Characterization parity on every surface |
| Numerical preset | Phase 1 analysis/app mapping (removed in Phase 2) | `configuration/aeGetNumericalPreset` | advanced supported | Makes numerical values model-owned | 2 | Exact Fast/Balanced/Robust and GUI-specific values |
| Problem construction | IOP/HGO wrapper local code | `core/aeBuildProblem` | internal | Isolate constitutive state and grids | 2 or 4 | Exact direct params and grids |
| Internal tracking grid | Phase 1 solver-local builder (removed in Phase 2) | `configuration/aeBuildInternalTrackingGrid` | internal | Essential model configuration | 2 | Exact sorted/unique grid parity |
| Constitutive functions | four explicit `compute/solveAcoustoelastic*` names | retain | advanced supported | Physical names add value | none | No rename |
| Matrix/roots/objectives | four explicit `Acoustoelastic` names | retain | advanced supported | Documented scientific exceptions | none | No rename |
| Primary atlas solver | `solveAcoustoelasticIOPHGOAtlasBranch` | retain supported name, subordinate to primary route | advanced supported | Useful explicit scientific boundary | 3/4 | Schema and numerics unchanged |
| Direct real-Cp solver | `solveAcoustoelasticIOPHGODispersion` / `solveAcoustoelasticDispersion` | retain | advanced supported | Legitimate diagnostic/scientific route | 6 | Do not promote to primary production |
| Complex-C solver | `solveAcoustoelasticComplexCDispersion` | retain | advanced supported | Legitimate distinct algorithm | 6 | Diagnostic/advanced status explicit |
| Atlas construction | `solvers/aeBuildAtlas` | retain | internal | Separate solve artifact from tracking/result | implemented 4 | Objective map exact parity |
| Production minima | `tracking/aeFindAtlasLocalMinima` | retain | internal | One production owner | implemented 4 | Exact candidates/ranks/objectives |
| Branch linking | `tracking/aeLinkAtlasBranches` | retain | internal | One production owner | implemented 4 | Exact IDs and tables |
| Branch splitting | `tracking/aeSplitAtlasBranches` | retain | internal | Named numerical responsibility | implemented 4 | Exact jump behavior |
| Official selection | `policies/aeSelectAtlasA0Branch` | retain | internal | Explicit policy owner | implemented 4 | Exact filter, score, fallback choice |
| Fallback invalidation | `policies/aeApplyAtlasA0FallbackPolicy` | retain | internal | Decision separated from schema rebuilding | implemented 4 | Exact `atlasA0` invalidation and diagnostic candidates |
| Reliability | two local summarizers | `quality/aeEvaluateAtlasA0Quality` | internal | One requested-grid quality owner | 3 | Exact field/value parity |
| Public result | built in two solvers | `results/aeBuildResult` | internal | Stable schema boundary | 3 | Field, shape, value, NaN, mask parity |
| Debug payload | top-level internals and `diagnostics` | `results/aeBuildDebugResult` | internal | Explicit unstable boundary | 3 | Preserve maintained diagnostic access during migration |
| Identity diagnostic | `analysis/aeBuildIdentityA0DiagnosticBranch` | retain name and analysis owner | diagnostic | Already clear and established | 3 | Production model must stop depending on it; repeatable diagnostic parity |
| Raw branch diagnostic | `analysis/aeExtractRawBranch1Candidate` | retain | diagnostic | Existing name is clear | none | Remains nonproduction |
| Modal atlas diagnostics | three `ae*ModalAtlas*` helpers | retain | diagnostic | Existing names are coherent | none | Remain nonproduction |
| Sweep workflow | `aeDefaultSweep*`, `aeRunSweep`, summary/plot/output helpers | retain | internal workflow | Correct analysis ownership | 5 | Campaign/output parity |
| Fit workflow | `aeBuildFitProblem`, `aeEvaluateFitModel`, `aeFitDispersionData` | retain | internal workflow | Correct fitting grammar | 5 | Optimizer/objective/result parity |
| Main app route | `guiBuild/RunAcoustoelasticIOPHGO*` | retain | app | Existing model-specific adapter grammar | 5 | UI/result parity |
| Sweep/Fit app routes | `guiRun/NormalizeAcoustoelasticIOPHGOSweep`, `guiFitAcoustoelasticIOPHGOSolver` | retain | app | Matches cross-family adapters | 5 | App metadata parity |
| Result output compatibility | `aeResolveResultFile` | retain until fixtures migrate | compatibility | Explicit bounded diagnostic debt | 6 | Remove only after all maintained inputs migrate |
| User workflows/diagnostics/tests | current `run_`, `ae_sweep_`, verbs, `test_` | retain | public/diagnostic/test | Already matches repository naming | all | Direct rename only if independently justified |

## Stable phase structure

Every phase uses the responsibility and naming maps above. Later branches are
suggestions only and must be created from the then-current `origin/main`.

### Phase 1 - architecture audit and target map

- Branch: `audit/ae-architecture-alignment`
- Objective: evidence-backed inventory, calls, target ownership, names, risks.
- Allowed scope: bounded AE architecture documentation and one index link.
- Likely files: this document and AE README.
- Dependencies: merged PR #121 base.
- Prohibited: all executable and behavior changes; later branches.
- Validation: link/identifier/file searches, repository hygiene, quick contracts,
  Git diff checks.
- Behavior impact: none.
- Rollback boundary: documentation commit(s) only.

### Phase 2 - configuration, request validation, and numerical preset ownership

- Branch: `refactor/ae-configuration-ownership`
- Objective: one model owner for defaults, accepted inputs, exact presets,
  internal/requested grids, and current surface-specific numerical bundles.
- Allowed scope: AE `api/options/configuration/core` responsibility files;
  `aeDefaultSweepOptions`; AE profile/request app adapters; focused tests/docs.
- Phase 2 implementation note: `app/SweepTool_GUI.m` and `app/FitTool_GUI.m`
  also construct maintained AE requests with duplicated numerical literals.
  Their AE-only request construction is therefore in scope solely to select
  canonical model-owned profile/surface configuration. GUI state, optimizer
  settings, physical defaults, and presentation remain unchanged.
- Implemented responsibilities: `aeValidateRequest`, `aeResolveConfiguration`,
  `aeGetNumericalPreset`, `aeBuildInternalTrackingGrid`; thin adapter changes.
- Dependencies: Phase 1 approved; exhaustive current configuration
  characterization recorded before extraction.
- Prohibited: equations, matrix, residual, objectives, atlas/tracking/selection,
  fallback, reliability, result schemas, fitting/sweep/GUI behavior or values.
- Validation: new configuration/preset/grid parity tests;
  `run_repository_hygiene_tests`, `run_quick_contract_tests`,
  `run_ae_quick_tests`, `run_ae_extended_tests`, execution-profile surface and
  integration tests, GUI quick tests, and `run_all_smoke_tests`.
- Behavior impact: none; numerical risk low-moderate because ownership moves
  while values remain byte-for-byte/equal.
- Rollback boundary: configuration extraction and direct consumer migration as
  one revertible commit set.

### Phase 3 - public result, quality, diagnostics, and debug boundaries

- Branch: `refactor/ae-result-quality-boundary`
- Status: implemented; exact schema retained without adding `result.debug`.
- Objective: one public result builder, one requested-grid quality owner, and
  an explicit diagnostic/debug boundary; remove model-to-analysis dependency.
- Allowed scope: AE `quality/results` responsibilities, atlas wrapper assembly,
  identity diagnostics, app normalizers, focused schema tests/docs.
- Dependencies: resolved configuration from Phase 2.
- Prohibited: numerical candidate generation, linking, selection, splitting,
  fallback decision, official values/masks/schema, diagnostic promotion.
- Validation: exact result field/shape/value characterization, identity official
  parity, fallback invalidation, internal-grid, app normalization/export,
  fitting/sweep consumers, full smoke.
- Behavior impact: none; moderate-high schema risk controlled by exact parity.
- Rollback boundary: result/quality/debug extraction and consumer adaptation.

### Phase 4 - production tracking and policy ownership

- Branch: `refactor/ae-tracking-policy-ownership`
- Objective: extract one production minima/link/split/selection/fallback-policy
  path behind neutral AE names.
- Allowed scope: AE solver, tracking, and policy responsibilities and focused
  numerical characterization tests/docs.
- Dependencies: stable configuration and result/quality boundaries.
- Prohibited: numerical values, `atlasA0` behavior, interpolation/reconnection,
  branch identities, diagnostic promotion, Cp-waviness refinement.
- Validation: exact objective maps, minima/branch tables, selected IDs, Cp,
  masks, statuses, reliability, fallback cases, sweeps/fits/GUI, full smoke and
  representative manual cases.
- Behavior impact: none; high numerical risk, exact parity required.
- Rollback boundary: each extracted production responsibility with its direct
  call migration; no mixed old/new route.

### Phase 5 - workflow and app-adapter alignment

- Branch: `refactor/ae-workflow-adapter-alignment`
- Objective: make Main GUI, SweepTool, FitTool, and physical examples thin
  consumers of the stabilized model configuration/API.
- Allowed scope: AE analysis fitting/sweep request construction, AE app
  adapters, registries/metadata, focused app/tests/docs.
- Dependencies: Phases 2-4 model contracts.
- Prohibited: model physics/numerics/policies, optimizer architecture, campaign
  values, outputs, GUI appearance/behavior, result schema.
- Validation: GUI quick/smoke, fit validation, execution-profile suites, AE
  sweep source and representative manual workflows, full smoke.
- Behavior impact: none; moderate integration risk.
- Rollback boundary: one surface at a time, but only one canonical production
  route may remain after each committed migration.

### Phase 6 - remove proven redundancy and finalize documentation

- Branch: `refactor/ae-architecture-finalization`
- Objective: remove only unused or proven duplicate internals/compatibility,
  enforce names/dependencies, and replace this audit with final-state contracts.
- Allowed scope: proven redundant AE files/local functions, diagnostic legacy
  result reads after fixture migration, tests, maintained contracts/indexes.
- Dependencies: all consumer migrations and absence evidence complete.
- Prohibited: opportunistic solver refinement, new aliases, broad repository
  cleanup, deletion of distinct diagnostic evidence.
- Validation: reference/absence scans, naming/dependency/entrypoint contracts,
  repository hygiene, all focused AE/app suites, full smoke, manual user routes.
- Behavior impact: none; low-moderate compatibility risk.
- Rollback boundary: direct deletion/rename plus all reference updates in a
  coherent commit; Git history is the compatibility record.

## Implemented phases and next approval boundary

Phases 2, 3, and 4 implemented configuration, request validation, numerical
preset, internal-grid, result, requested-grid quality, production atlas,
tracking, selection, and fallback-policy ownership. Do not begin **Phase 5 -
workflow and app-adapter alignment** without repository-owner approval.

Bounded parity requirements:

- no change to public flat `params, options` behavior;
- no change to default option fields or values;
- exact Fast `300/12`, Balanced `600/16`, Robust `900/20` mapping;
- exact Main GUI maintained numerical bundle, including current `420/8`,
  refinement, initialization, tracking, fallback, window, and weight values;
- exact SweepTool/FitTool legacy explicit override semantics and metadata;
- exact requested and internal tracking frequency vectors;
- no change to `atlasA0`, objective maps, candidates, branch tables, selected
  branch, `Cp`, `validCp`, statuses, fallback, reliability, fitting, sweeps, or
  GUI output.

Risk is low to moderate if characterization precedes migration. It is the best
first phase because every production surface currently crosses the mixed
configuration boundary, while the extraction can stop before any constitutive,
tracking, policy, or result code changes.

## Known uncertainties and decisions deferred

- Whether all six currently uncalled/path-only analysis diagnostics still have
  enough repeatable value to retain is deferred to Phase 6.
- Whether `solveAcoustoelasticIOPHGOAtlasBranch` remains public advanced API or
  becomes internal cannot be decided without external-consumer evidence; it is
  retained throughout the proposed phases.
- A model request struct analogous to mRLFE is not recommended now. Reconsider
  only if flat input validation cannot be made coherent without a breaking API.
- Diagnostic raw-atlas implementations may intentionally encode different
  experimental settings. Deduplicate only after equivalence is proven.
- Phase 3 retained unstable/debug evidence at its characterized top-level
  fields. Moving it requires later consumer evidence and explicit approval;
  no maintained diagnostic field may disappear implicitly.
- Residual high-frequency `Cp(f)` waviness remains a separate numerical task and
  is explicitly outside every architecture phase above.

## Verification contract for this document

The current-state identifiers above must resolve to tracked `.m` files or be
named local functions in the cited current file. Proposed identifiers occur
only in target/future sections. Removed diagnostic and sweep names guarded by
`test_acoustoelastic_iop_hgo_short_entrypoints` and
`test_ae_physical_sweep_examples_contract` are not presented as maintained.

Supporting contracts are linked from the [AE model index](../README.md), the
[repository structure](../../../repository/repository_structure.md), the
[naming strategy](../../../repository/naming_strategy.md), the
[GUI adapter architecture](../../../workflows/gui/adapter_architecture.md), the
[fitting architecture](../../../workflows/fitting/architecture.md), and the
[sweep architecture](../../../workflows/sweeps/parametric_sweeps.md).

## Phase 3 validation record

Pre-refactor characterization was committed before production extraction.
A detached worktree at that commit produced complete MATLAB result snapshots.
The implemented branch returned exact `isequaln` parity for:

```text
direct atlas result
IOP/HGO atlas result
primary public result
internal-grid requested projection
identityA0Diagnostic result
fallback-invalidated result
```

Focused schema/ownership, atlasA0, fallback, internal-grid, identity, Main GUI,
SweepTool, FitTool, fitting-evaluator, physical-sweep, and grid-sweep tests
passed. MATLAB Code Analyzer reported zero messages across every changed
`.m` file.

The required validation commands were executed after the final implementation:

```matlab
clear functions
rehash toolboxcache
startup
run_repository_hygiene_tests
run_quick_contract_tests
run_ae_quick_tests
run_ae_extended_tests
run_execution_profile_contract_tests
run_execution_profile_integration_tests
run_gui_quick_tests
run_gui_smoke_tests
run_acoustoelastic_smoke_tests
run_fit_validation_tests
run_numerical_regression_tests
run_all_smoke_tests
run_extended_integration_tests
```

`run_repository_hygiene_tests` exited 0. The remaining required runner
sequence exited 0 in 1933.8 seconds. Deterministic test inventories were
regenerated and validated. Final searches found one atlas result owner, one
requested-grid quality owner, no former local reliability builders, no stale
identity-helper paths, and no model-to-`analysis/` dependency.

## Phase 1 validation record

Static audit verification represented all 101 pre-audit tracked primary files,
confirmed that 14 proposed identifiers are not current `.m` files, rejected
the removed diagnostic/sweep names guarded by current tests, and resolved all
six Markdown links in this document. Markdown table shape validation reported
zero inconsistent rows.

Executed from the repository root:

```text
git diff --check
git status -sb
git diff --stat
```

The checks completed without whitespace errors. Git emitted only the existing
Windows LF-to-CRLF working-copy warning for the modified README. Final full
diff/status evidence is repeated after staging and before commit.

MATLAB command:

```matlab
clear functions
rehash toolboxcache
startup
run_repository_hygiene_tests
run_quick_contract_tests
```

The first restricted `matlab -batch` launch failed before repository code ran
with `System Error: File system inconsistency`. The same command was rerun with
MATLAB preference/cache access and exited 0. Both required runners passed;
repository structure, documentation, naming, artifacts, dependency, startup,
root, output-folder, fitting-helper, execution-profile, FitTool data/interaction,
and mRLFE public API contract checks reported pass status.

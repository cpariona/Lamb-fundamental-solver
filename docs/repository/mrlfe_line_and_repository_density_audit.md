# mRLFE maintained line and repository density audit

Audit date: 2026-07-15
Branch: `audit/mrlfe-line-and-repository-density`
Base: `d35eb6c4449cb4f5dae7eaec88be74e153ce6aba`

## Evidence vocabulary

- **Measured fact**: produced from the tracked base by the audit generator or
  by an executed MATLAB command.
- **Static call-graph evidence**: direct token/call, registry, callback,
  function-handle, `str2func`, and `feval` inspection. Static evidence cannot
  prove that a user never types a function name manually.
- **Documented contract**: statement in a current contract, subordinate to
  maintained code and tests.
- **Architectural judgment**: proposed ownership or decomposition.
- **Deletion decision**: an explicit phase-2 action backed by the evidence in
  the inventories.
- **Remaining uncertainty**: evidence that cannot be established without
  executing costly or external workflows.

## Executive conclusion

**Measured fact:** the audited source base contains 577 tracked files: 445
MATLAB, 125 Markdown, 5 CSV, one `.gitignore`, and one extensionless `LICENSE`.
After adding this reproducible audit, the final branch contains 583 tracked
files: 446 MATLAB, 126 Markdown, 9 CSV, one `.gitignore`, and one extensionless
`LICENSE`. There are no tracked binary/generated artifacts. Final tracked text
contains 63,270 physical lines and 51,144 nonblank/noncomment lines; the
repository-level physical-line split is 23,261 main, 26,352 supporting, and
13,657 historical/secondary lines.

**Static call-graph evidence:** `mrlfeSolve` is the single maintained public
physical solver. Main GUI, SweepTool, and FitTool all reach it. The current
production dispatcher is `mrlfeSolveBranch`; the similarly named
`solveMRLFEBranch` has zero executable callers, zero test references, no
explicit dynamic reference, and only two historical documentation references.

**Architectural judgment:** the physics/tracking core is coherent and should
not be rewritten. The correction phase should concentrate on four seams:

1. remove the verified orphan `solveMRLFEBranch`;
2. replace 448 lines of triplicated request mapping with one shared public
   request-construction core and thin wrappers;
3. stop Main GUI, SweepTool, FitTool compatibility code, the benchmark, and
   the RL compatibility host from reaching through
   `result.diagnostics.rawInternalResult`;
4. make execution-profile metadata a merge of solver-owned facts and
   surface-owned facts instead of rebuilding it in every adapter.

**Repository-density judgment:** 21.585% of final tracked text lines are
classified historical/secondary. The Markdown inventory marks 70 retain, 3 consolidate,
0 archive, 53 delete, and 0 defer. Git history is sufficient preservation for
the 53 completed reports, phase logs, superseded proposals, and migration
records; no Markdown file has unusual evidence requiring an archive copy in the
live tree.

## Current maintained call graph

```text
Main GUI callback/dispatcher                         [application surface]
  -> guiRunMRLFEModel                               [application adapter]
     -> guiNormalizeExecutionProfile                [shared app metadata]
     -> mrlfeBuildGuiSolveRequest                   [request mapper]
     -> mrlfeSolve                                  [public API]
     -> adaptPublicResultsForMainGui                [private-result adapter]
     -> guiNormalizeRawResult                       [shared app normalizer]

SweepTool registry/dispatcher                       [application surface]
  -> guiRunMRLFESweep                               [application adapter]
     -> mrlfeResolveExecutionProfile                [shared mRLFE app resolver]
     -> mrlfeBuildSweepSolveRequest                 [request mapper]
     -> mrlfeSolve once per point                   [public API]
     -> adaptPublicResultForSweepRaw                [private-result adapter]
     -> guiNormalizeMRLFESweep                      [surface normalizer]
     -> aggregateSweepMetadata                      [surface aggregation]

FitTool registry/dispatcher                         [application surface]
  -> guiFitMRLFESolver                              [application adapter]
     -> mrlfeResolveExecutionProfile                [shared mRLFE app resolver]
     -> mrlfeFitDispersionData                      [fitting backend]
        -> mrlfeBuildFitProblem                     [fitting problem]
           -> mrlfeEvaluateFitModel                 [model evaluator]
              -> mrlfeBuildFitSolveRequest          [request mapper]
              -> mrlfeBuildFitFrequencyGrid         [fit-only grid policy]
              -> mrlfeSolve                         [public API]
              -> localAdaptPublicResultForFitWorkflow [private-result adapter]

mrlfeSolve                                          [public API]
  -> mrlfeResolveConfiguration                      [public-to-internal config]
     -> mrlfeValidateRequest                        [public validation]
     -> mrlfeGetNumericalPreset                     [preset resolution]
     -> rlDefaultParams / rlDefaultOptions          [RL configuration coupling]
  -> mrlfeBuildProblem                              [production problem]
     -> rlDefaultOptions                            [seed options]
     -> rlComputeFundamentalLambModes               [physical seed dependency]
  -> mrlfeSolveBranch                               [production dispatcher]
     -> mrlfeSolveElasticBranch                     [production core]
     -> mrlfeSolveViscoelasticBranch                [production core]
        -> mrlfeBuildSeed                           [model helper]
        -> mrlfeTrackBranchRobustStart              [model helper]
           -> mrlfeTrackBranchAdaptive              [model helper]
        -> mrlfeApplyTerminationPolicy              [model helper]
           -> mrlfeEvaluatePhysicalTail             [model helper]
        -> mrlfeBuildInternalBranchResult           [private result builder]
  -> mrlfeBuildResult                               [public result builder]
     -> mrlfeEvaluateBranchQuality                  [quality helper]
```

The detailed per-file callers, callees-by-token, dynamic risk, coverage, and
documentation evidence are in
`analysis/repository_audit/mrlfe_file_decisions.csv`.

### Dynamic invocation review

**Static call-graph evidence:** no `str2func`, `feval`, callback, registry, or
model-map entry names `solveMRLFEBranch`. Current GUI and Fit/Sweep registries
select the model family, then call fixed adapter functions. Tests also contain
no reference to the old symbol. Scripts can still be invoked manually from an
interactive MATLAB prompt; that is not a maintained dependency.

## Production-core assessment

### API boundary

**Verdict: retain the core, refactor its configuration and diagnostics
boundary.**

- `mrlfeSolve` is the only maintained public solving entrypoint.
- Production does not depend on GUI structs or app callbacks.
- Request validation has stable `mrlfe:*` identifiers and the public request is
  coherent.
- The documented public result fields are stable, but
  `result.configuration` exposes almost the whole resolved configuration and
  `result.diagnostics.rawInternalResult` exposes the full private solver/RL
  seed graph. Those are accidental public contracts.
- `mrlfeBuildInternalBranchResult` embeds `problem.rawSeedResult` and duplicates
  it into `models.mRLFERealK` and `models.mRLFE`; the public builder then exposes
  that object without a debug opt-in.

### Configuration density

`mrlfeResolveConfiguration.m` is 173 physical lines and owns default merging,
public validation, preset resolution, material-regime selection, public
parameter normalization, RL parameter construction, RL option construction,
tracker configuration, robust-start configuration, termination toggles, branch
toggles, and quality defaults.

**Architectural judgment:** keep one orchestration function and its small
default-merging helpers. Extract only the RL seed/internal-options translation
into one focused helper. Splitting defaults, every policy, and each scalar into
separate files would add navigation without removing coupling.

### Rayleigh-Lamb coupling

| Dependency | Location | Classification | Decision |
| --- | --- | --- | --- |
| `rlDefaultParams` | configuration | accidental configuration coupling | replace with a narrow seed-parameter mapper |
| `rlDefaultOptions("Fast")` | configuration | accidental internal-option carrier | replace with an mRLFE-owned internal option base |
| `rlDefaultOptions("Fast")` | problem builder | reasonable seed dependency | retain behind seed construction |
| `rlComputeFundamentalLambModes` | problem builder | necessary physical seed dependency | retain |

No other `rl*` dependency exists under `models/mrlfe/`.

### Old solver implementation

`models/mrlfe/solvers/solveMRLFEBranch.m` is 231 lines/204
nonblank-noncomment lines. Git history shows its last functional evolution in
June 2026 and its last commit (`74d1563`) merely staged it into the solver
folder. It implements the former seed-anchored real/complex-k refinement loop,
whereas current production uses robust-start plus adaptive Cp-window tracking.

**Deletion decision: delete.** It contributes no unique maintained capability:
complex-k is not enabled by the public API, real-k production is implemented by
the neutral current tracker, and no test covers this file. Required deletion
validation is an explicit `isempty(which('solveMRLFEBranch'))` assertion plus
public contract, production core, mRLFE smoke, and startup/path checks.

## Main GUI assessment

`guiRunMRLFEModel.m` has 190 lines, 10 functions, 36 manually assigned
metadata/result fields, two direct raw-internal access lines, and reconstructs
two legacy model aliases. It calls the public solver correctly and does not own
physics, but it owns too much compatibility and metadata assembly.

**Verdict: refactor, do not replace.** Keep one orchestrator with at most:

1. branch selection (local);
2. shared public-request wrapper;
3. shared public-result-to-app compatibility adapter;
4. shared execution-metadata merger.

Plot/export already consumes normalized branches; raw compatibility should be
isolated rather than assembled in the orchestration body.

## SweepTool assessment

`guiRunMRLFESweep.m` is the densest surface: 250 lines, 10 functions, 24
metadata assignments, two raw-internal access lines, per-point exception
handling, legacy raw-shape adaptation, aggregation, printing, and normalization.

**Verdict: refactor into four responsibilities without a new hierarchy:**

- request preparation;
- point execution;
- result aggregation;
- surface normalization/output assembly.

These can remain local helpers in one adapter plus the two shared cross-surface
helpers. A class or a folder of one-line helpers is not justified.

## FitTool assessment

`guiFitMRLFESolver.m` has 164 lines, 7 functions, and 8 direct metadata
assignments. It does not itself access raw internals, but
`mrlfeEvaluateFitModel` does so to create compatibility aliases and route
summaries. Three defensive helpers catch all exceptions and return `unknown` or
the input default.

**Verdict: retain the fitting architecture, refactor metadata access.** The
`fitOptimized` objective grid and `numericalPreset` requested-curve grid are
deliberate distinct policies. `actualPath`, effective preset, engine,
termination, fallback, quality, and etaS should be guaranteed by the public
result/normalized fitting contract; broad `try/catch` should not be the schema.

## Request-builder duplication

The three builders total 448 lines and 26 functions:

| Builder | Lines | Functions |
| --- | ---: | ---: |
| GUI | 124 | 8 |
| Sweep | 169 | 9 |
| Fit | 155 | 9 |

They independently repeat branch validation, frequency validation, aliases for
mu/rho/nu/thickness/fluid, etaS precedence, scalar checks, termination mapping,
adaptive selection, fallback none, preset parsing, and error identifiers.
Sweep point mutation and Fit grid/settings are the genuine surface-specific
parts. See `mrlfe_duplication_matrix.csv` for the field-by-field matrix.

**Target:** add `analysis/mrlfe/mrlfeBuildPublicSolveRequest.m`, taking a
normalized physical parameter struct plus branch/frequency/preset/policies.
Keep all three existing names as thin public wrappers. This removes three
copies of validation while preserving callers and stable error identifiers.

## Result/raw-internal coupling

Maintained or maintained-adjacent consumers of private structures are:

| Consumer | Private dependency | Genuine need | Target |
| --- | --- | --- | --- |
| Main GUI adapter | `rawFullResult`, internal branch | legacy normalized shape | shared compatibility adapter |
| Sweep adapter | `rawFullResult` | legacy summary/raw export | public point result plus optional compatibility adapter |
| Fit evaluator | branch, branchSolve, rawFullResult | fit diagnostics/cache compatibility | stable fitting diagnostics contract |
| Fit problem cache | `rawFullResult.models.mRLFEElasticRealK` | etaS seed/cache | explicit elastic reference object |
| RL compatibility host | raw model and branch | old `rlCompute...` result schema | dedicated compatibility adapter |
| execution-profile benchmark | solve-frequency/private route | diagnostics only | public debug summary |
| three fitting diagnostics | raw tracking timing/counts | diagnostic only | one stable diagnostic summary |

Tests of robust start and termination legitimately inspect private details;
they should use a documented debug-only field or a model-internal test helper,
not make the raw tree part of the public contract.

**Architectural judgment:** keep stable public `quality`, `termination`,
`fallback`, `execution`, and a small `diagnostics.solveGrid`/tracking summary.
Move the complete raw structure to an explicitly unstable debug field enabled
for tests/diagnostics, or return it from an internal API not used by surfaces.

## Execution-profile metadata ownership

| Field | Canonical owner | Main GUI | SweepTool | FitTool | Source |
| --- | --- | --- | --- | --- | --- |
| requested/effective profile | `mrlfeResolveExecutionProfile` | supply selected/default | supply selected/default | supply selected/default | surface |
| profile source/default/support | shared app resolver | Balanced default | Fast default | Fast default | surface |
| requested/effective preset | `mrlfeSolve.result.execution` | copy | aggregate point values | copy final evaluation | solver |
| internal engine | `mrlfeSolve` | aggregate branches | aggregate points | copy | solver |
| termination/fallback/quality | `mrlfeSolve` | aggregate branches | aggregate points | copy | solver |
| profile override | shared app resolver | none | none | none | derived |
| grid policy | fitting evaluator | not applicable | sweep public grid | fitOptimized/numericalPreset | surface/workflow |
| route policy | solver termination plus surface label | `mrlfeSolve` | `mrlfeSolve` | public solver | derived |
| optimizer profile | fitting backend | empty | empty | optimizer result | fit workflow |

Main GUI currently rebuilds most of this table manually. Sweep mutates resolver
metadata after aggregation. Fit adds route facts through defensive extraction.
One shared `mrlfeBuildSurfaceExecutionMetadata` helper should merge, not invent,
solver and surface facts.

## Legacy and orphan code

| File/group | Decision | Evidence |
| --- | --- | --- |
| `solveMRLFEBranch.m` | delete | zero callers/tests/dynamic refs; superseded algorithm |
| `analysis/mrlfe/run_mrlfe_solver_route_audit.m` | delete | launches completed route audit only |
| `compareMRLFETrackingStrategies.m` | delete | both strategies now resolve to the same public route |
| atlas-primary diagnostic | delete | tests removed route concepts |
| three fitting diagnostics | consolidate | overlapping timing/options/cache inspection |
| five pre-public numerical investigations | archive | useful historical evidence, not maintained workflows |
| public grid validations | retain | current public API and repeatable purpose |

No maintained-code file is left as `defer`.

## Documentation contradictions

| Document/statement | Code truth | Status | Decision/replacement |
| --- | --- | --- | --- |
| `public_api.md`: Main GUI preset is `fast` | Main GUI defaults Balanced and resolves `balanced` | active contradiction | correct in phase 2; surface integration is replacement truth |
| `execution_profile_manual_validation.md` lines 79-80/107: Fit maps Balanced/Robust to Fast/`fast_fit_atlas` | profiles map directly; no override | active contradiction inside current checklist | consolidate into surface-integration checklist |
| `execution_profile_diagnostics_validation.md`: reports `fast_fit_atlas` | maintained metadata uses `fast/balanced/robust` | active stale validation text | correct or consolidate |
| `mrlfe_atlas_policy_integration.md`: Main GUI uses fast atlas route | Main GUI uses selected public preset | superseded active-location history | delete/consolidate current facts into adapter architecture |
| execution-profile audit/proposal/benchmark/cleanup | describe mapped-to-Fast or old atlas density | historical | delete; Git preserves migration history |
| solver-route audit/quick results/legacy inventory | describe removed route names | historical | delete |

Current code truth is: Main GUI default Balanced; SweepTool/FitTool default
Fast; Fast/Balanced/Robust map directly to `fast/balanced/robust`; Fit objective
uses `fitOptimized`; requested curve uses `numericalPreset`; A0Like termination
is `physicalTail`; S0Like is `none`; fallback is `none`; etaS zero/nonzero use
elastic/viscoelastic adaptive engines.

## Repository composition

### Counting methodology

The generator uses `git ls-files`; ignored and untracked files cannot enter the
inventories. MATLAB nonblank/noncomment lines exclude blank, leading `%`, and
`%{...%}` block-comment lines. Other text nonblank counts exclude blank lines.
Percentages below use all 61,756 tracked physical text lines.

| Area | Files | Physical lines | Nonblank/noncomment | Text-line share |
| --- | ---: | ---: | ---: | ---: |
| analysis | 112 | 12,916 | 11,152 | 20.414% |
| app | 69 | 7,098 | 6,194 | 11.219% |
| docs | 120 | 19,599 | 14,288 | 30.977% |
| examples | 55 | 7,708 | 6,390 | 12.183% |
| models | 60 | 6,210 | 5,050 | 9.815% |
| references | 1 | 7 | 6 | 0.011% |
| root | 6 | 359 | 271 | 0.567% |
| tests | 160 | 9,373 | 7,793 | 14.814% |

### Main versus supporting versus historical

Main line is production solver/model code required by maintained APIs,
application code required by the three surfaces, and shared code directly
required by those routes. Supporting includes tests, runners, current examples,
current docs, diagnostics, and generated inventories. Historical/secondary
includes completed reports, phase logs, superseded designs, orphan code, and
one-off diagnostics selected for archive/delete.

| Line class | Files | File share | Physical text lines | Text-line share |
| --- | ---: | ---: | ---: | ---: |
| main | 226 | 38.765% | 23,261 | 36.765% |
| supporting | 273 | 46.827% | 26,352 | 41.650% |
| historical/secondary | 84 | 14.408% | 13,657 | 21.585% |

## Deletion/consolidation decisions

### Markdown

| Decision | Count |
| --- | ---: |
| retain | 70 |
| consolidate | 3 |
| archive | 0 |
| delete | 53 |
| defer | 0 |

The zero archive count is deliberate: Git history preserves completed reports
and migration evidence. The three consolidation targets preserve unique current
content from FitTool grid sensitivity, the execution-profile dependency map,
and the manual execution-profile checklist.

### Diagnostics

For executable mRLFE diagnostics (`examples/mrlfe/diagnostics/*.m` plus the
three diagnostic-only `analysis/mrlfe` helpers): retain 4, consolidate 3,
archive 5, delete 3, defer 0. The complete per-file decisions and required
validation are in the file inventory.

## Target architecture

```text
models/mrlfe/
  api/                mrlfeSolve; defaults; public validation
  configuration/      compact resolver + one internal seed/options mapper
  core/               problem and residual/matrix construction
  results/            public result + explicit unstable debug summary
  solvers/            current elastic/visco dispatcher only
  tracking/           seed, robust-start, adaptive tracking
  policies/ quality/  termination and quality

analysis/mrlfe/
  mrlfeBuildPublicSolveRequest       shared physical request core
  mrlfeBuildGuiSolveRequest          thin wrapper
  mrlfeBuildSweepSolveRequest        thin wrapper
  mrlfeBuildFitSolveRequest          thin wrapper
  fitting backend/evaluator/grid     retained

app/adapters/
  guiRunMRLFEModel                   thin orchestrator
  guiRunMRLFESweep                   point orchestration + aggregation
  guiFitMRLFESolver                  fit orchestration
  shared mRLFE compatibility-result adapter
  shared mRLFE surface-metadata merger
```

New helpers are limited to three: shared request construction removes three
duplicate implementations and has three callers; the result adapter removes
two raw-shape implementations and supports three surfaces/RL compatibility;
the metadata merger removes two full metadata constructions and one defensive
extraction path. They belong respectively in `analysis/mrlfe` and
`app/adapters`; none belongs in the physical model.

## Implementation phases

Each workstream is one reversible commit unless noted.

| # | Workstream and exact files | Delete/add estimate | Net line estimate | Risk | Required validation / rollback |
| ---: | --- | --- | ---: | --- | --- |
| 1 | delete `models/mrlfe/solvers/solveMRLFEBranch.m`; add absence assertion to legacy cleanup test | -1/+0 files | -231 | medium | public/core/smoke/legacy cleanup; revert commit |
| 2 | three request builders; add `mrlfeBuildPublicSolveRequest.m` | 0/+1 files | -180 to -240 | high | builder, GUI, sweep, fit parity; revert commit |
| 3 | `guiRunMRLFEModel.m` plus shared result adapter | 0/+1 | -50 to -90 | high | Main GUI direct parity and export contract |
| 4 | `guiRunMRLFESweep.m`, normalizer, shared result adapter | 0/+0 | -70 to -110 | high | sweep mapping/metadata and point characterization |
| 5 | `guiFitMRLFESolver.m`, `mrlfeEvaluateFitModel.m`, fitting problem | 0/+0 | -40 to -80 | high | fit public route, fixed etaS, grid policy, requested curve |
| 6 | result builders, RL compatibility host, benchmark | 0/+0 | -80 to -140 | high | schema, robust-start, termination, RL/mRLFE smoke |
| 7 | resolver plus three adapters; add metadata merger | 0/+1 | -90 to -140 | high | execution-profile contracts/matrix |
| 8 | correct retained active mRLFE/workflow/validation docs | 0/+0 | -100 to -200 | low | link/term scans and doc contract tests |
| 9 | delete 53 Markdown; merge 3 into retained targets | -56/+0 | about -8,850 | low-medium | inbound links, naming/path tests, quick contracts |
| 10 | delete 3 obsolete diagnostic code files; consolidate 3 into one; archive 5 | -5/+1 plus moves | -500 to -800 active lines | medium | startup `which`, current diagnostics, public solver tests |
| 11 | regenerate all inventories and run three-surface validation | 0/+0 | neutral | low | generator determinism, focused MATLAB stack |

The realistic phase-2 target is a net reduction of 59 files and approximately
10,100 physical lines (planning uncertainty about 700 lines). This assumes three new shared helpers, deletion of
53 historical Markdown files and four dead MATLAB files, merge of three docs
and three fitting diagnostics into existing/one targets, and archive moves that
do not themselves reduce Git file count.

## Quantitative feasibility

- No orphan maintained-code files: feasible after workstream 1 and exact scans.
- One physical request-construction core: feasible; 11 responsibilities are
  equivalent across three builders.
- No duplicate scalar validation: feasible without changing error IDs.
- No Main/Sweep rawFullResult dependency: feasible after shared adapter/schema.
- One metadata builder: feasible if solver and surface ownership remain distinct.
- Sweep adapter below roughly 170 lines and Main adapter below roughly 140 lines:
  realistic without micro-files.
- Active mRLFE docs reduced to index, public API, production core, fitting,
  sweeps, current grid/robust-start/benchmark procedures: realistic.
- Numerical and metadata parity: must be proven, not assumed.

## Validation plan for correction task

Static gates per commit:

```text
git grep exact old/new names
dynamic-dispatch and registry search
documentation inbound-link validation
buildRepositoryDensityAudit('WriteCsv', true, 'ValidatePaths', true)
git diff --check
checkcode on touched MATLAB
```

MATLAB sequence:

```matlab
clear functions
rehash toolboxcache
startup

run_quick_contract_tests
test_mrlfe_main_gui_uses_public_solver
test_mrlfe_sweep_uses_public_solver
test_mrlfe_fit_uses_public_solver
test_mrlfe_no_legacy_routes

run_mrlfe_public_contract_tests
run_mrlfe_production_core_tests
run_mrlfe_main_gui_public_solver_tests
run_mrlfe_sweeptool_public_solver_tests
run_mrlfe_fit_public_solver_tests
run_execution_profile_surface_tests
run_quick_smoke_tests
run_numerical_regression_tests
```

Run expensive characterizations once at the final integration boundary, not
after every reversible refactor commit.

## Risks

- Legacy normalized shapes are consumed outside the obvious adapters by
  `rlComputeFundamentalLambModes` and fitting cache logic.
- Public-result parity can remain numerically exact while metadata shape breaks;
  schema assertions are required.
- MATLAB path/manual invocation is more permissive than static call graphs.
- Deleting historical docs requires repairing tests that assert the presence of
  `atlas_policy_notes.md` and current indexes that link to historical files.
- Raw tracking details are useful to internal tests; removing them before an
  explicit debug contract would weaken diagnostics.

## Remaining uncertainty

There are no `defer` decisions. Remaining uncertainty is bounded to:

1. no evidence can prove that an external, untracked user script manually calls
   `solveMRLFEBranch`; it is not a maintained repository dependency;
2. last successful execution is not documented for every one-off diagnostic;
   archive/delete decisions therefore rely on current API usage, overlap, and
   maintained test coverage;
3. the correction phase must measure numerical/metadata parity after refactors;
   this diagnostic phase intentionally does not alter or characterize physics.

The inventories provide a concrete correction plan; no further broad audit is
required before implementation.

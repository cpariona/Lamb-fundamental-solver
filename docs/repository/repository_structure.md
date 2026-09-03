# Repository structure

This document defines the maintained repository layers and dependency
direction.

## Top-level contract

```text
analysis/    reusable analysis, fitting, sweep, summary, and workflow helpers
app/         GUI surfaces, adapters, UI state, plotting, and export
docs/        current contracts, workflows, validation, and project context
examples/    executable examples, maintained campaigns, and diagnostics
models/      physical and numerical model implementation
tests/       tests, runners, shared test infrastructure, and public wrappers
Results/     generated outputs; never source code
```

`analysis/` is the shared reusable workflow layer. A root-level `shared/`
source directory is not planned: shared material transformations belong in
`models/materials/`, and shared tests belong in `tests/shared/`.

The allowed production dependency direction is:

```text
app/ or examples/
    -> analysis/
    -> models/
```

App adapters may call model APIs directly when no reusable analysis workflow is
needed. Models must not depend on `analysis/`, `app/`, or `examples/`.
Production and analysis code must not call files under `examples/`.

The executable boundary matrix is:

| Caller | Allowed maintained dependencies | Forbidden dependencies |
| --- | --- | --- |
| `models/` | model-local and shared material model code | `analysis/`, `app/`, `examples/`, `tests/` |
| `analysis/` | `models/`, analysis-local helpers | `app/`, `examples/`, `tests/` |
| `app/` | `analysis/`, `models/`, app-local helpers | `examples/`, `tests/` |
| `examples/` | `app/`, `analysis/`, `models/` | production ownership of example code |
| `tests/` | all maintained layers | none within the repository test contract |

Within `models/`, sibling model families are independent except for one
documented scientific seed edge:

```text
mrlfeBuildSeed -> rlComputeFundamentalLambModes
```

Rayleigh-Lamb has no reverse dependency on mRLFE. Cross-model dispatch belongs
to an owning consumer or workflow, never inside the RL solver.

## `models/`: physical and numerical ownership

`models/` owns equations, constitutive laws, matrix construction, residuals,
root solving, branch tracking, model numerical policies, request validation,
model result construction, and public model APIs.

```text
models/
|-- materials/                    shared elastic-material transformations
|-- rayleigh_lamb/
|   |-- approximations/
|   |-- core/
|   |-- equations/
|   `-- tracking/
|-- mrlfe/
|   |-- api/
|   |-- configuration/
|   |-- core/
|   |-- options/
|   |-- policies/
|   |-- quality/
|   |-- results/
|   |-- solvers/
|   `-- tracking/
`-- acoustoelastic_iop_hgo/
    |-- configuration/
    |-- constitutive/
    |-- core/
    |-- diagnostics/
    |-- options/
    |-- policies/
    |-- quality/
    |-- results/
    |-- solvers/
    `-- tracking/
```

For AE, `quality/aeEvaluateAtlasA0Quality` summarizes the already-decided
official output on the requested grid. `results/aeBuildResult` is the only
atlas-result schema builder. `diagnostics/` owns the identity-A0 builder and
candidate scorer needed by an explicitly requested diagnostic without creating
a forbidden model-to-`analysis/` dependency. They do not participate in
production branch selection.

Campaign execution, summary-table aggregation, figures, output folders, GUI
normalization, and application state do not belong in `models/`.

## `analysis/`: reusable workflow ownership

```text
analysis/
|-- diagnostics/             repeatable scientific diagnostics by model
|-- execution_profiles/      cross-surface validation and benchmark analysis
|-- fitting/                 shared optimizer plus model-specific fit workflows
|-- io/                      output paths, writers, and figure persistence
|-- performance/             maintained performance validation workflows
|-- plotting/                plotting and plot-data construction from results
|-- requests/                reusable canonical model-request translation
|-- sweeps/                  shared iteration plus model-specific sweep workflows
`-- test_inventory/          deterministic test graph and ownership tooling
```

The shared sweep and plotting modules own:

```matlab
runParametricSweep
buildParametricSweepPlotData
plotParametricSweepCp
plotSweepCpFigure
setSweepPlotLimits
summarizeParametricSweepBranch
```

`aeRunSweep` lives in `analysis/sweeps/acoustoelastic_iop_hgo/`. It supplies an
AE evaluator to the shared one-dimensional `runParametricSweep` owner;
`aeRunGridSweep` remains the explicit two-dimensional campaign owner.

`resolveModelOutputFolder` lives in `analysis/io/shared/`; model-specific output
writers live beside the persistence functions they reuse.

Analysis helpers may generate normal MATLAB figures. Helpers that own UI
controls, callbacks, or persistent interactive state belong in `app/`.

## `app/`: surface ownership

```text
app/
|-- fitting/   FitTool request, model translation, state, and presentation
|-- main/      Main GUI controls, model translation, presentation, and export
|-- shared/    profile and struct operations used by multiple surfaces
|-- sweep/     SweepTool configuration, model translation, and presentation
`-- root       the three public GUI entrypoints only
```

Root app entrypoints:

```matlab
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
```

The four Main GUI tab builders and normalized-result export live under
`app/main/`. `createFittingTab` and model-specific fit translators live under
`app/fitting/`. Model-specific sweep translators live under `app/sweep/`.
Execution-profile resolvers and struct operations used by multiple surfaces
live under `app/shared/`. The former mixed `app/adapters/` folder is absent.

The interactive AE grid-sweep surface helper lives in `app/sweep/` because it
owns a slider callback and UI state. Its numerical cube construction remains in
the AE analysis layer.

App code may orchestrate and present results but must not implement physical
equations, constitutive behavior, residuals, or numerical solvers.

## `examples/`: executable workflows

```text
examples/<family>/basic/        minimal model execution
examples/<family>/sweeps/       maintained campaign entrypoints
examples/<family>/fitting/      maintained fitting examples where present
examples/<family>/diagnostics/  active repeatable diagnostics
examples/rayleigh_lamb/validation/  maintained RL validation example
```

Examples call maintained APIs in `models/`, `analysis/`, or `app/`. They do not
own reusable production helpers, and no production, app, or analysis file may
call an example.

## Model-family ownership

| Path | Responsibility |
| --- | --- |
| `models/<family>/` | Model APIs, physical equations, numerical policies, and solvers |
| `analysis/<family>/` | Reusable fitting, campaigns, summaries, diagnostics, and output helpers |
| `examples/<family>/` | User-executable examples and diagnostics |
| `tests/models/<family>/` | Model-family numerical and contract tests |
| `docs/models/<family>/` | Current model API, workflow, and diagnostic contracts |

GUI-facing tests live under `tests/app/`; shared analysis tests live under
`tests/shared/`.

## Tests

```text
tests/
|-- app/       GUI, FitTool, SweepTool, adapters, and surface integration
|-- models/    model-family numerical and contract tests
|-- runners/   canonical runner implementations
`-- shared/    fitting, sweeps, regression, path, and utility tests
```

Five intentional public wrappers are documented in `tests/README.md`.
Specialized runner commands, including Main GUI export, resolve directly from
`tests/runners/`. `startup` adds `tests/` recursively, so physical runner paths
may change only when canonical ownership and documented commands remain stable.

## Documentation

```text
docs/architecture/  accepted ADRs and cross-cutting architecture
docs/models/        model-family API, workflow, and diagnostic contracts
docs/project/       operational context, handoff, and task templates
docs/repository/    repository-wide maintained contracts
docs/validation/    current repeatable validation procedures
docs/workflows/     fitting, GUI, and sweep workflow contracts
```

Completed audits, phase reports, and investigations belong in Git history.

## Output paths

The canonical generated result roots are:

```text
Results/rayleigh_lamb/<task>
Results/mrlfe/<task>
Results/ae_iop_hgo/<task>
Results/test_runtime/test_runtime_measurements.csv
```

`resolveModelOutputFolder` is the sole maintained owner that creates these
paths relative to the caller's launch folder. Existing documented AE legacy folders remain readable only where
`aeResolveResultFile` explicitly provides fallback compatibility.

## Path behavior

`configureProjectPath` adds `models/`, `analysis/`, `app/`, maintained examples,
and tests recursively. Moving a function inside one of these trees preserves its
MATLAB command name. A move must leave exactly one tracked definition and must
not add a path-only compatibility wrapper.

## Executable guardrail

Run `run_repository_hygiene_tests` to validate the top-level allowlist,
required directories, test locations, archive absence, model UI/campaign
absence, dependency matrix, generated-artifact policy, documentation paths,
naming, startup path, and test ownership.

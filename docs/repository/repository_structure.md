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
    |-- constitutive/
    |-- core/
    |-- options/
    `-- solvers/
```

Campaign execution, summary-table aggregation, figures, output folders, GUI
normalization, and application state do not belong in `models/`.

## `analysis/`: reusable workflow ownership

```text
analysis/
|-- acoustoelastic_iop_hgo/  AE fitting, campaigns, summaries, diagnostics,
|                            plot-data construction, and output helpers
|-- execution_profiles/      cross-surface validation and benchmark analysis
|-- fitting/                 model-neutral fitting and quality infrastructure
|-- mrlfe/                   mRLFE fitting, sweep, request, and summary helpers
|-- performance/             maintained performance validation workflows
|-- rayleigh_lamb/           RL fitting, sweep, output, and figure helpers
|-- sweeps/                  shared cross-model sweep module
|-- test_inventory/          deterministic test graph and ownership tooling
`-- resolveModelOutputFolder.m
```

The shared sweep module owns:

```matlab
runParametricSweep
buildParametricSweepPlotData
plotParametricSweepCp
plotSweepCpFigure
setSweepPlotLimits
summarizeParametricSweepBranch
```

`aeRunSweep` lives in `analysis/acoustoelastic_iop_hgo/`. It calls the public AE
solver once per condition and aggregates campaign results; it does not implement
solver physics.

`resolveModelOutputFolder` remains at the analysis root because it is a small
cross-model output-path primitive rather than part of the sweep module.

Analysis helpers may generate normal MATLAB figures. Helpers that own UI
controls, callbacks, or persistent interactive state belong in `app/`.

## `app/`: surface ownership

```text
app/
|-- adapters/  model-to-surface request translation, profile resolution,
|              result normalization, and surface metadata
|-- export/    normalized Main GUI result export
|-- fitting/   FitTool request/state/display workflow and visual controls
|-- sweep/     SweepTool registry/request/plot workflow and interactive sweep UI
`-- root       public GUI entrypoints and cross-surface UI infrastructure
```

Root app entrypoints:

```matlab
LambFundamental_GUI
FitTool_GUI
SweepTool_GUI
```

The root also retains the four Main GUI tab builders because there is no
separate Main-GUI submodule, plus genuinely cross-surface execution-profile
normalization and formatting helpers. `createFittingTab` is owned by
`app/fitting/`. Model-specific execution-profile resolvers and mRLFE surface
metadata construction are owned by `app/adapters/`.

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

Nine intentional public wrappers and the standalone Main GUI export runner are
documented in `tests/README.md`. `startup` adds `tests/` recursively, so internal
test paths may change only when canonical ownership and public runner commands
remain stable.

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
```

`rlOutputFolder`, `mrlfeOutputFolder`, and `aeOutputFolder` delegate to
`resolveModelOutputFolder`, which creates these paths relative to the caller's
launch folder. Existing documented AE legacy folders remain readable only where
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

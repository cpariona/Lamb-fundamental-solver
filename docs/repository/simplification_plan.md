# Repository simplification plan

This document defines the next bounded repository-maintenance task after the
completed AE architecture alignment. The objective is to reduce structural
exceptions and navigation cost without changing any physical model, numerical
result, public result schema, GUI behavior, fitting behavior, or sweep campaign.

## Motivation

The production architecture is stable, but the repository still retains several
forms of avoidable structural complexity:

- `analysis/acoustoelastic_iop_hgo/` mixes fitting, sweeps, plotting/output, and
  diagnostic responsibilities in one flat directory;
- two identity-A0 diagnostic model helpers live under `results/` even though
  they implement diagnostic logic rather than public result construction;
- `tests/fitting/run_fit_validation_tests.m` is a documented layout exception
  beside the canonical runner in `tests/runners/`;
- nine root-level test wrappers duplicate canonical runner identifiers and must
  be reduced to a small, explicitly public convenience surface;
- `analysis/test_inventory/test_runtime_measurements.csv` is an
  environment-dependent measurement stored beside deterministic inventories;
- `docs/repository/maintained_entrypoints.md` currently classifies the two
  identity-A0 model helpers inconsistently.

Generated example figures and `Results/` workspaces are local ignored outputs and
are not part of this task.

## Approved target

### AE analysis layout

Organize the AE workflow layer by real responsibility, with no forwarding
wrappers and one tracked definition per MATLAB identifier:

```text
analysis/acoustoelastic_iop_hgo/
|-- fitting/
|-- sweeps/
|-- diagnostics/
`-- io/ or workflow-local output helpers where justified
```

Use the smallest directory set supported by the actual dependency graph. Do not
create empty folders or one-file categories without a clear ownership benefit.
Rayleigh-Lamb remains flat because its analysis layer is small. mRLFE must be
audited for the same responsibility pattern, but it should be subdivided only if
its current size and dependency graph justify the added structure.

### AE model diagnostics

Move these functions out of `models/acoustoelastic_iop_hgo/results/`:

```text
aeBuildIdentityA0DiagnosticBranch
aeScoreBranchIdentityCandidates
```

Their target ownership is:

```text
models/acoustoelastic_iop_hgo/diagnostics/
```

They remain diagnostic-only model internals. Their algorithms, function names,
callers, outputs, and policy status must not change.

### Test runners

- remove `tests/fitting/run_fit_validation_tests.m` and the resulting empty
  directory;
- keep canonical implementations under `tests/runners/`;
- characterize all nine root-level wrappers and reduce them to a small public
  convenience set;
- root wrappers that remain must contain no validation logic and must delegate
  through `runRepositoryTestRunner`;
- remove structural-test exceptions instead of replacing them with new
  whitelists.

The exact retained public wrapper set must be justified by documented user or
automation value. Specialized model-contract runners should normally remain only
under `tests/runners/`.

### Runtime measurements

Keep `measureTestRuntime.m`, but treat runtime data as local generated evidence,
not deterministic repository inventory. Move its default output under an ignored
`Results/test_runtime/` location, remove the tracked
`test_runtime_measurements.csv`, and remove its approved-CSV exception. Add a
focused schema test for the generated measurement table if needed.

### Documentation and contracts

Update:

- `docs/repository/maintained_entrypoints.md`;
- `docs/repository/repository_structure.md`;
- `docs/repository/validation_status.md`;
- `docs/repository/test_runner_ownership.md`;
- `tests/README.md`;
- project context and handoff documents;
- deterministic test inventories.

The final documentation must classify every maintained function by its actual
layer and must contain no path exceptions for removed files.

## Non-goals

Do not change:

- solver equations, constitutive laws, matrices, residuals, objectives, roots,
  tracking, policies, presets, grids, thresholds, tolerances, or branch results;
- public model function names or result schemas;
- GUI behavior or appearance;
- fitting objectives, bounds, optimizers, or parameter summaries;
- sweep values, order, outputs, or file names;
- diagnostic algorithms or scientific interpretation;
- local ignored example figures or result workspaces;
- mRLFE or Rayleigh-Lamb model implementation merely for visual symmetry.

## Required evidence

Before every move or deletion:

1. enumerate static callers, tests, examples, documentation, and dynamic lookup;
2. characterize current behavior where execution is involved;
3. migrate all callers in the same change;
4. leave exactly one tracked definition and no forwarding alias;
5. regenerate deterministic inventories;
6. run focused and aggregate validation.

## Completion criteria

The task is complete when:

- AE analysis responsibilities are navigable by directory rather than only by
  filename prefix;
- identity-A0 diagnostic internals have explicit model diagnostic ownership;
- `tests/fitting/` no longer exists;
- the root test-wrapper surface is minimal and documented;
- runtime measurements are generated locally and not versioned;
- repository contracts contain no exception for removed paths;
- all numerical and user-facing behavior remains unchanged;
- repository hygiene, quick contracts, smoke, fitting, AE, mRLFE, RL, GUI, and
  extended integration validation pass.

# MATLAB test inventory

This folder contains reproducible, static evidence for the repository-wide
MATLAB test-suite audit. It does not execute tests or numerical solvers.

## Generator

Run from any working directory after the repository `startup` has made this
folder available:

```matlab
[inventory, edges] = buildTestInventory();
```

CSV writing is opt-in:

```matlab
[inventory, edges] = buildTestInventory('WriteCsv', true);
```

The committed CSV files use deterministic path and column ordering, repository-
relative forward-slash paths, and no timestamps or absolute machine paths.

## Static model

The generator:

- obtains `tests/**/*.m` and `tests/*.m` from `git ls-files`;
- classifies tests, maintained runner implementations, compatibility wrappers,
  and helpers;
- records explicit executable runner/test/helper edges;
- models `runRepositoryTestRunner` wrapper delegation explicitly;
- treats file paths passed to `runtests` as medium-confidence dynamic edges;
- records `which`/path references as low-confidence exposure evidence rather
  than executable membership;
- computes direct and transitive maintained-runner membership and reachability
  from `tests/runners/run_all_smoke_tests.m`;
- identifies static numerical-cost indicators without executing source files.

## Limitations

This is a conservative source parser, not the MATLAB parser or dependency
analyzer. It can miss names assembled dynamically, callbacks stored in structs,
workspace-driven script dispatch, shadowing caused by MATLAB path order, and
calls hidden behind general-purpose helpers. Comments and quoted strings are
removed before high-confidence executable-call matching, except for the known
`runtests` file-list convention. Recursive startup path exposure means an
unregistered test can still be invoked manually by name.

`LikelyHeavy` is a planning flag derived from loops, solver/fitting calls,
benchmark markers, and known suite structure. It is not a measured duration.
The only runtime evidence imported into the audit report is explicitly labeled
with its external provenance.

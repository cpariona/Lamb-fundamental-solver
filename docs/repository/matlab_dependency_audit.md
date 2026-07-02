# MATLAB dependency and path audit

This audit records the current MATLAB dependency-hygiene findings for startup path policy, shadowing, maintained entrypoints, and dynamic calls. It is a maintenance note, not a solver or GUI behavior contract.

## Scope

Reviewed source and test files under:

```text
analysis/
app/
examples/
models/
tests/
startup.m
```

The audit did not change solver equations, branch-selection policy, fitting behavior, GUI behavior, public result structs, or expected numerical outputs.

## Startup/path policy

`startup.m` adds the repository root plus maintained source trees:

```text
app/
models/
analysis/
examples/rayleigh_lamb/
examples/acoustoelastic_iop_hgo/
examples/mrlfe/
tests/
```

The example trees are filtered so folders named `archive` or `figures` are not added to the MATLAB path. This keeps archived exploratory scripts and generated example-figure folders from resolving as active MATLAB entrypoints while preserving maintained examples, sweeps, diagnostics, and tests.

Validation:

```matlab
test_startup_path_policy
```

## Path shadowing

Duplicate `.m` basenames found in the active source/test trees are the public runner wrappers and their runner implementations:

```text
tests/run_*_tests.m
tests/runners/run_*_tests.m
tests/fitting/run_fit_validation_tests.m
tests/runners/run_fit_validation_tests.m
```

Classification: intentional runner-wrapper shadowing. Public runner names are preserved; implementation logic lives under `tests/runners/`.

No risky solver/helper shadowing was found in `analysis/`, `app/`, or `models/`.

## Main function naming

Several example and test files are scripts with local helper functions. Simple declaration scans can report the first local helper as if it were a mismatched main function. These are MATLAB-valid script patterns and should not be renamed solely from grep output.

No behavior-neutral function rename was identified in this pass.

## Maintained entrypoints

Maintained entrypoint coverage remains split across:

```text
docs/repository/maintained_entrypoints.md
tests/models/mrlfe/test_mrlfe_maintained_entrypoints_naming.m
tests/models/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_short_entrypoints.m
tests/shared/utilities/test_startup_path_policy.m
```

Rayleigh-Lamb, mRLFE, AE IOP/HGO, app, fitting, and runner coverage should continue to be updated with focused tests rather than by broad automated deletion of apparently unused `.m` files.

## Dynamic-call caveats

The repository uses MATLAB callbacks, function handles, and a small number of `evalin` calls in expected places:

```text
app/*_GUI.m and tab builders                  GUI callbacks
analysis/*BuildFitProblem.m                   fitting objective/evaluator handles
tests/runners/run_fit_validation_tests.m      base-workspace summary collection
analysis/acoustoelastic_iop_hgo/aeRunLegacyScript.m   retained legacy-script runner
```

These patterns mean a helper should not be deleted or renamed based only on exact-name grep counts.

## Deferred items

- Build a fuller dependency graph with MATLAB-aware parsing before declaring internal helpers unused.
- Consider a shared test utility for repo-root detection only if more tests start duplicating fragile path calculations.
- Keep archived diagnostics out of the startup path, but preserve them on disk for traceability.

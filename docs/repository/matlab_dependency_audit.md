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
tests/shared/utilities/test_repository_root_utilities.m
tests/shared/utilities/test_model_output_folder_helpers.m
tests/app/gui/test_gui_struct_helpers_contract.m
tests/shared/regression/test_lightweight_numerical_regression.m
```

Rayleigh-Lamb, mRLFE, AE IOP/HGO, app, fitting, and runner coverage should continue to be updated with focused tests rather than by broad automated deletion of apparently unused `.m` files.

## Shared infrastructure consolidation

Root-level public test runner wrappers remain in place, but their repository-root lookup and runner dispatch now flow through:

```text
tests/shared/utilities/testRepositoryRoot.m
tests/shared/utilities/runRepositoryTestRunner.m
```

Model-specific output-folder helpers continue to own public names and model folder labels. Their shared create-if-needed behavior is centralized in:

```text
analysis/resolveModelOutputFolder.m
```

Validation:

```matlab
test_repository_root_utilities
test_model_output_folder_helpers
run_core_smoke_tests
```

GUI adapter struct-field/default overlay helpers are centralized in:

```text
app/adapters/guiGetStructField.m
app/adapters/guiMergeStructs.m
```

These helpers preserve the existing adapter convention that non-struct overlays are ignored, overlay fields take precedence, and empty fields are treated as missing for read access. They are covered by:

```matlab
test_gui_struct_helpers_contract
run_gui_smoke_tests
```

## Dependency findings

| Function/File | Classification | Direct callers | Indirect-call risk | Action |
| --- | --- | --- | --- | --- |
| `guiGetStructField` | app adapter helper | GUI model/sweep adapters | Low; direct helper calls only | Consolidated duplicate local helpers and added contract test. |
| `guiMergeStructs` | app adapter helper | GUI model/sweep adapters | Low; direct helper calls only | Consolidated duplicate overlay helpers and preserved precedence. |
| `test_lightweight_numerical_regression` | regression test | `run_core_smoke_tests` | Low; direct test invocation | Added deterministic snapshots for RL, mRLFE, and AE IOP/HGO. |
| `aeRunLegacyScript` | retained legacy runner | short AE diagnostic wrappers | Medium; executes scripts via `run` | Preserve; do not classify targets as dead by grep alone. |
| `runRepositoryTestRunner` | public runner dispatch helper | root runner wrappers | Medium; executes runner by computed file path | Preserve and keep runner-wrapper shadowing intentional. |

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
- Keep archived diagnostics out of the startup path, but preserve them on disk for traceability.

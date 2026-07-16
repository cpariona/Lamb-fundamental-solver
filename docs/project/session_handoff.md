# Session handoff

Updated: 2026-07-16

## Repository state

- Repository: `cpariona/Lamb-fundamental-solver`
- Default branch: `main`
- Latest merged repository-wide change: PR #119
- Merge commit: `749feb159795f7fe0e0a4eecaecf8696b4369dad`
- Active implementation branch: none
- Selected next technical objective: none
- Active provisional phase: none

A new chat must verify that local `main` matches `origin/main` before drawing
conclusions from this handoff.

## Required reading order

Read:

```text
docs/project/README.md
docs/project/active_context.md
docs/project/session_handoff.md
docs/repository/repository_structure.md
docs/repository/naming_strategy.md
```

Then read only the model, workflow, architecture, or validation contracts needed
to evaluate the selected technical topic. Maintained code and tests take
precedence over operational context.

## Recently completed work

PR #119 completed the repository cleanup sequence:

- obsolete code, archived diagnostics, generated audit artifacts, and historical
  task reports were removed;
- source-layer ownership was corrected;
- maintained MATLAB naming was normalized;
- active documentation was consolidated;
- repository structure, naming, documentation, artifact, dependency, and test
  ownership guardrails were added;
- Main GUI, SweepTool, and FitTool were manually reviewed without observed route
  breakage.

This cleanup is complete. Do not reopen it as another broad phase unless a
specific guardrail or concrete file demonstrates a new violation.

## Open technical areas

### 1. AE solver refinement

The bounded numerical issue is documented in:

```text
docs/models/acoustoelastic_iop_hgo/active/solver_pending_work.md
```

The current concern is residual high-frequency waviness in AE `Cp(f)`. It must
be investigated through solver diagnostics and regression evidence, not through
GUI-side smoothing.

### 2. mRLFE runtime characterization

A manual review suggested possible slower perceived runtime after cleanup.
Static comparison against the pre-cleanup base found no changes to:

```text
frequency-step presets
low-frequency anchors
internal frequency-grid construction
scan-point counts
candidate counts
adaptive windows
profile-to-preset mapping
public request construction
maintained tracking and solver algorithms
```

No runtime regression is established. The next step, if selected, is a controlled
same-machine, same-session benchmark with cold/warm runs and identical requests.

### 3. Compatibility-debt migration

The bounded retained compatibility surfaces are documented in:

```text
docs/repository/validation_status.md
```

They include public test wrappers, the `robustness` alias,
`result.diagnostics.rawInternalResult`, and the AE legacy-result fallback.
Each requires a separate, versioned, consumer-aware task rather than general
cleanup.

## Standard validation

```matlab
clear functions
rehash toolboxcache
startup

run_repository_hygiene_tests
run_quick_contract_tests
run_quick_smoke_tests
run_numerical_regression_tests
```

Use the focused and extended commands listed in
`docs/repository/validation_status.md` when the changed surface requires them.

## Working rules for the next task

- Create one new branch per selected objective.
- Start from updated `origin/main`; never work directly on `main`.
- Keep changes small and localized.
- Preserve repository structure, naming, public contracts, and ownership.
- Define validation before implementation.
- Do not open a PR until automated and relevant manual validation pass.
- The repository owner performs the merge manually.

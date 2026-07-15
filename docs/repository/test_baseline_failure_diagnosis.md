# MATLAB test-baseline failure diagnosis

## Scope and evidence labels

This report diagnoses the three failures recorded by the test-suite runtime
audit. The repairs were measured on MATLAB R2024b (`PCWIN64`) from branch
`test/test-baseline-failure-diagnosis`, based on
`ba7c1f2c88c34abc38ef781d5ec9c2bc184105f5`.

Evidence is labeled as follows:

- **Measured fact**: observed by executing the current MATLAB code.
- **Static inference**: derived from executable call and data-flow inspection.
- **Historical evidence**: derived from Git log, blame, or commit diffs.
- **Maintained contract**: stated by active documentation or public metadata.
- **Remaining uncertainty**: not established by the focused validation here.

No runner membership, public wrapper, folder layout, numerical preset, public
profile mapping, GUI behavior, or sweep behavior changed.

## AE `identityA0Diagnostic` requested-grid schema

### Observed failure and reproduction

The original assertion was:

```text
identityA0 CpCandidate length must match result.Cp length.
```

It failed at line 42 of
`test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy` with an empty error
identifier. The test is a standalone contract with no executable maintained
runner registration; `run_acoustoelastic_smoke_tests` verifies its path but
does not call it.

The clean reproduction stack was `assert` followed by
`test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy` line 42. The direct
reproduction reached the assertion in 4.269 seconds; the phase-1 harness had
recorded 3.8154831 seconds to failure.

**Measured fact, before repair:**

| Array | Size | Finite/valid points | Frequency extent |
| --- | ---: | ---: | --- |
| requested frequency | 1 x 40 | 40 | 100 to 20000.000000000004 Hz |
| `result.frequency` / `result.Cp` | 1 x 40 | 23 valid Cp | same requested extent |
| `identityA0.frequency` / `CpCandidate` | 1 x 89 | 69 valid candidates | same extent, internal points included |
| internal tracking frequency | 1 x 89 | 89 | same extent |

Both grids were strictly increasing. Repeated execution produced identical
official Cp, candidate Cp, and masks. Disabling
`useInternalAtlasTrackingGrid` made both result and candidate length 40, which
isolated the failure to the internal-grid projection path rather than a
profile, truncation, or nondeterminism issue.

### History and root cause

**Historical evidence:** commit `f6966571` introduced the diagnostic test and
its equal-length assertion. Commit `0160423c` later decoupled the AE internal
tracking grid from the requested output grid. Its
`restrictResultToRequestedFrequency` implementation projected official fields
such as `Cp`, `validCp`, objective, ranks, and point status, but copied the
already-built `identityA0` structure unchanged.

**Maintained contract:** the active branch-policy documentation says public
`result.Cp` and `result.validCp` use the requested output grid. The
`identityA0Diagnostic` documentation says `CpCandidate` starts from official
`result.Cp` and fills only missing frequencies. Those statements require the
diagnostic arrays to share the requested grid.

**Root cause:** a genuine production result-schema regression. `CpCandidate`
was defined on the internal tracking grid while the enclosing public result
was defined on the requested grid. Invalid/truncated points did not cause the
length difference; they only explained the different valid counts. Raw-length
equality was always intended by the diagnostic contract, so masking or
truncating the two arrays would have hidden the schema defect.

Classification: `real_regression` with a diagnostic-field semantic mismatch
and requested-grid versus internal-grid mismatch.

### Repair

The IOP/HGO wrapper now rebuilds `identityA0` after official requested-grid
projection. It reuses `aeBuildIdentityA0DiagnosticBranch` and supplies only the
existing objective-map columns selected by the exact requested-to-tracking
`ismember` mapping. No interpolation, minimum-length truncation, solver
mathematics, branch selection, or official Cp values changed.

The test now additionally verifies:

- diagnostic and result frequencies are identical;
- official Cp is preserved at every official valid point;
- the official valid mask is a subset of the diagnostic valid mask.

**Measured fact, after repair:** requested/result/candidate lengths are all
40; official validity is 23/40; diagnostic validity is 31/40; the internal
tracking grid remains 89 points; fallback was not used; and the policy remains
`identityA0Diagnostic`.

Validation:

- individual test: passed, 4.617 seconds in the direct validation run;
- runtime harness: passed, 4.2971776 seconds;
- `run_acoustoelastic_smoke_tests`: all 10 runner tests passed; the clean
  process wall time was 105.5 seconds.

Remaining limitation: the full historical 110-case diagnostic grid was not
rerun. The focused test covers the exact schema defect and the maintained AE
smoke runner covers the surrounding production path.

## Lightweight mRLFE numerical snapshot

### Observed failure and reproduction

The original assertion was:

```text
mRLFE A0Like Cp snapshot changed.
```

It failed at line 53 through local `assertNumericClose` with an empty error
identifier. The regression is called directly by `run_core_smoke_tests` and
is transitively reachable from `run_all_smoke_tests`.

The clean reproduction stack was `assert` at local `assertNumericClose` line
97, called from the script at line 53. The direct reproduction reached the
assertion in 1.842 seconds; the phase-1 harness had recorded 1.4954196 seconds
to failure.

The request uses 18 linearly spaced frequencies from 500 to 4000 Hz, material
`mu=158000 Pa`, `rho=1070 kg/m^3`, `nu=0.4999`, thickness `0.0005 m`, and
fluid density/sound speed `1000 kg/m^3` / `1500 m/s`. The maintained public
route uses fast `numericalPreset`, a 71-point internal grid `500:50:4000`,
`physicalTail` for A0Like, no termination cut for S0Like, and fallback `none`.
Both branches returned 18/18 valid points with accepted quality.

**Measured fact:** two solves in one MATLAB session and two clean-start solves
were bitwise identical in Cp and masks.

| Branch | Expected selected Cp (m/s) | Actual selected Cp (m/s) | RMSE (m/s) | Maximum absolute error (m/s) |
| --- | --- | --- | ---: | ---: |
| A0Like | 2.560317111928414, 5.386393893277469, 7.011010224801658 | 2.563075741553039, 5.385531761157373, 7.013850616841720 | 0.00233959655636 | 0.00284039204006 at 4000 Hz |
| S0Like | 24.284845559129135, 24.039695107953005, 23.481593219654226 | 24.282183296783170, 24.028758171168086, 23.468811073659403 | 0.00983340367097 | 0.0127821459948 at 4000 Hz |

The maximum relative differences were approximately 0.00107746 for A0Like
and 0.000544347 for S0Like. Differences were not confined to invalid points or
marginal branch tails; all selected points were valid and quality remained
accepted.

### History and root cause

**Historical evidence:** commit `5762b747` introduced the fixture on
2026-07-02 against the former `computeMRLFE` production route. Commit
`52a261fc` later replaced that legacy route with `mrlfeSolve`, introduced the
public Fast/Balanced/Robust numerical-preset architecture, requested-grid
projection, neutral robust-start tracking, and physical-tail termination. Git
blame shows the stale values were never refreshed after that production-core
migration.

**Maintained contract:** `rlComputeFundamentalLambModes` is now a compatibility
consumer of the public mRLFE solver and explicitly requests the fast preset.
The current public result is deterministic, uses the documented 50 Hz fast
grid in this frequency range, applies no fallback, and is accepted by the
current quality evaluator.

**Root cause:** the numerical fixture represented the superseded pre-public-API
solver state. There is no evidence of nondeterminism, a mask mismatch, an
implicit grid policy, or a current production-contract violation.

Classification: `intentional_maintained_numerical_change` and `stale_fixture`.

### Repair and tolerance

Production was not changed. The test now makes the material, fluid, viscosity,
requested grid, fast internal grid, preset, branch termination, fallback,
valid-mask, and quality assumptions explicit. Both stale A0Like and S0Like
selected values were updated because the next assertion would otherwise have
failed for the same proven cause.

The Cp tolerance is `1e-9 m/s`. Current same-route repeat error was exactly
zero. The tolerance is more than five orders of magnitude below the smallest
obsolete-fixture difference (`8.62e-4 m/s`), so it permits platform arithmetic
without accepting the architecture-scale drift diagnosed here.

Validation:

- individual test: passed;
- runtime harness: passed, 2.6547612 seconds;
- `run_core_smoke_tests`: passed, including RL and mRLFE synthetic fits; process
  wall time 71.9 seconds.

Remaining uncertainty: the fixture has not been sampled on a second MATLAB
release or platform. The explicit grid/policy assertions make any future
cross-platform deviation diagnosable rather than silently broadening the
tolerance.

## mRLFE fast fitting route equivalence

### Observed failure and reproduction

The original assertion was:

```text
Public fast fitting Cp RMSE differs from direct solver.
```

It failed at line 55 with an empty error identifier. The test is a standalone
regression with no executable maintained-runner registration.

The clean reproduction stack was `assert` followed by the script at line 55.
The phase-1 harness recorded 8.9309187 seconds to failure. The script clears
its workspace, so a surrounding in-workspace timer was not used as evidence.

The original comparison used the same requested ten frequencies from 1000 to
8000 Hz, A0Like, `mu=75000 Pa`, `etaS=0`, `rho=1070 kg/m^3`, `nu=0.4999`,
thickness `0.0005 m`, fluid density/sound speed `1000 kg/m^3` / `1500 m/s`,
adaptive selection, physical-tail termination, fast preset, and fallback
`none`. One material difference remained: the internal grid policy.

| Field | Public fitting value | Original direct value | Equivalent? |
| --- | --- | --- | --- |
| requested frequencies | 10 points, 1000 to 8000 Hz | same | yes |
| branch / material / fluid | A0Like / same request | same | yes |
| etaL / complex lambda | neutral/disabled by public request | same resolved configuration | yes |
| numerical preset | fast | fast | yes |
| grid policy | `fitOptimized` | `numericalPreset` | **no** |
| internal grid | 37 points, bounded and request-preserving | 141 points at 50 Hz | **no** |
| seed/tracking | adaptive public A0Like route | same route on different grid | policy same, trajectory not equivalent |
| termination / fallback | `physicalTail` / `none` | same | yes |
| requested-grid valid mask | 10/10 | 10/10 | yes |
| quality | not accepted, `large_relative_jump` | same | yes |
| requested-grid projection | public projection | public projection | yes |
| Cp normalization | public phase velocity in m/s, column output | same | yes |

**Measured fact, original non-equivalent comparison:** common valid count
10/10; RMSE `0.00263863949118 m/s`; maximum absolute difference
`0.00427439052951 m/s` at `2555.555555555556 Hz`; maximum relative difference
`0.000911613355913`. Both routes disclosed fallback `none`, no fallback was
applied, and both returned the same quality state. A repeated fit-optimized
evaluation was bitwise identical.

### History and root cause

**Historical evidence:** the test began as a comparison between legacy fast
and reference fitting configurations in commit `a444aa90`. Commit `52a261fc`
rewrote it around the public solver. Within that architecture series, commit
`9528338b` made repeated fitting evaluations default to `fitOptimized`, but the
new direct comparison built a request without the frequency override and
therefore used `numericalPreset`.

**Maintained contract:** fitting architecture documentation explicitly assigns
`fitOptimized` to repeated objective evaluations and `numericalPreset` to
requested display curves. Exact route equivalence is meaningful only when the
request and internal grid policy are equal.

**Root cause:** a comparison between non-equivalent grid policies, not a
production regression, tolerance failure, mask mismatch, hidden fallback, or
nondeterminism.

Classification: `grid_policy_mismatch`.

### Repair and tolerance

Production was not changed. The test now has two equivalence checks:

1. public fitting versus direct solving on the same explicit 37-point
   fit-optimized grid;
2. public requested-curve evaluation versus direct solving on the same
   141-point fast numerical-preset grid.

Both comparisons measured zero RMSE, zero maximum absolute error, zero maximum
relative error, and identical masks. Their tolerances are `1e-12 m/s` absolute
and `1e-12` relative because both sides execute the same deterministic request;
these are adapter-equivalence tolerances, not cross-grid solver tolerances.

The test separately verifies fit-grid bounds, preservation of requested
frequencies, disclosed policy metadata, fast preset, no fallback, and exact
quality-metadata forwarding. The non-equivalent cross-grid difference remains
printed as a diagnostic and has no equality assertion or hardware-sensitive
acceptance threshold.

Validation:

- individual test: passed; direct validation wall time 35.4 seconds;
- runtime harness: passed, 11.3965243 seconds;
- `run_mrlfe_fit_public_solver_tests`: all focused public-route,
  characterization, and parameter-regression cases passed; process wall time
  108 seconds.

Remaining limitation: the test does not declare either grid's
`large_relative_jump` result acceptable for every workflow. It verifies that
quality is reported faithfully and leaves any quality-policy redesign to a
separate task.

## Deferred work and validation boundaries

- Runner registration and quick/extended membership remain unchanged.
- `run_all_smoke_tests`, the 36-case execution-profile matrix, the obsolete
  mapped-to-Fast benchmark, execution-profile diagnostics, and broad fitting
  validation were not run.
- No benchmark was redesigned and no unrelated numerical fixture was updated.
- Runtime rows are one-repeat descriptive measurements with no hard timeout.
- Cross-platform repeatability and the full AE diagnostic grid remain future
  validation opportunities, not unresolved causes of these three failures.

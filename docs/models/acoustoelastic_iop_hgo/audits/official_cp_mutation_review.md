### Official Cp mutation review

This document reviews the files flagged by the structural audit as `MutatesOfficialCp`.

### Summary

The audit flag is useful, but the five flagged files are not all errors.

Current classification:

```text
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticAtlasBranch.m              KEEP_OFFICIAL_ASSIGNMENT
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticDispersion.m               KEEP_SOLVER_ASSIGNMENT
models/acoustoelastic_iop_hgo/solvers/solveAcoustoelasticComplexCDispersion.m       KEEP_DIAGNOSTIC_SOLVER_VALIDCP

tests/acoustoelastic_iop_hgo/test_acoustoelastic_iop_hgo_branch_persistence_refinement.m   FALSE_POSITIVE_TEST_FIXTURE
tests/acoustoelastic_iop_hgo/test_ae_analyze_truncation_recovery.m                         FALSE_POSITIVE_TEST_FIXTURE
```

### solveAcoustoelasticAtlasBranch

Classification:

```text
KEEP_OFFICIAL_ASSIGNMENT
```

This is the maintained official atlas-branch solver. It is expected to assign:

```matlab
result.Cp
result.validCp
```

The file explicitly states that `result.Cp` and `result.validCp` are assigned from the maintained atlas branch logic. Diagnostic identity-A0 information is stored separately under `result.identityA0`.

Decision:

```text
No change required.
This file is allowed to assign official Cp fields.
```

### solveAcoustoelasticDispersion

Classification:

```text
KEEP_SOLVER_ASSIGNMENT
```

This is a direct alpha-beta-gamma dispersion solver. It constructs its own solver result and assigns:

```matlab
result.Cp
result.validCp
```

This is legitimate solver-output construction, not post-hoc diagnostic mutation.

Decision:

```text
No change required for this audit item.
Future cleanup may clarify whether this solver is production, legacy, or diagnostic, but its result assignment is not an error.
```

### solveAcoustoelasticComplexCDispersion

Classification:

```text
KEEP_DIAGNOSTIC_SOLVER_VALIDCP
```

This complex-C solver does not assign `result.Cp`. It assigns:

```matlab
result.CpComplex
result.CpReal
result.CpImag
result.validCp
```

The audit likely flagged this file because it assigns `result.validCp`. This is acceptable for a solver result structure. It should remain clearly documented as a diagnostic/parallel strategy unless it becomes part of a production policy.

Decision:

```text
No change required.
Do not treat this as official atlasA0 production output.
```

### test_acoustoelastic_iop_hgo_branch_persistence_refinement

Classification:

```text
FALSE_POSITIVE_TEST_FIXTURE
```

This test constructs a synthetic `result` struct:

```matlab
result.Cp = [10 11 12 nan nan nan];
result.validCp = [true true true false false false];
```

It then asserts that the diagnostic refinement does not change the maintained `result.Cp`.

Decision:

```text
No change required.
This test protects the intended diagnostic-only behavior.
```

### test_ae_analyze_truncation_recovery

Classification:

```text
FALSE_POSITIVE_TEST_FIXTURE
```

This test constructs synthetic `Cp` and `validCp` arrays to validate recovery analysis. It does not mutate production solver output.

Decision:

```text
No change required.
This is a fixture, not a production-output mutation.
```

### Policy conclusion

The `MutatesOfficialCp` audit flag should not be interpreted as a direct bug list.

A file is problematic only if it modifies an existing official solver result after the official branch has been selected, especially inside diagnostics.

Allowed cases:

```text
1. Solvers constructing their own result.Cp and result.validCp.
2. Tests creating synthetic fixtures.
3. Diagnostic solvers assigning clearly separate diagnostic fields.
```

Disallowed cases:

```text
1. Diagnostics overwriting result.Cp.
2. Helper functions replacing result.validCp after production selection.
3. Scripts silently substituting identityA0 or raw-branch candidates into official Cp output.
```

### Cleanup decision

No code changes are required for the five current `MutatesOfficialCp` flags.

The next cleanup target should be legacy output paths, especially files flagged as `WritesLegacyResults`.

### atlasA0-only phase closure

This document closes the branch-policy cleanup phase for the acoustoelastic IOP/HGO module.

### Closure statement

The maintained production branch policy is now:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

This is the only production atlas-A0 policy name.

The official solver output remains:

```matlab
result.Cp
result.validCp
```

No diagnostic branch should overwrite or replace these fields.

### Removed legacy branch-policy alias

The previous branch-policy alias was removed:

```text
strictA0
```

It is no longer normalized to `atlasA0` and is no longer accepted as a maintained branch-policy name.

Unsupported policies now fail explicitly through:

```matlab
aeNormalizeBranchPolicy
```

### Retained diagnostic policies and branches

The following remain diagnostic only:

```text
identityA0Diagnostic
raw_branch1
branch_families
```

Their roles are:

```text
identityA0Diagnostic
  Candidate extension for inspecting missing atlasA0 points.
  It preserves result.Cp and result.validCp.

raw_branch1
  Independent raw modal-atlas reference used for validation.
  It is not a production branch policy.

branch_families
  Ambiguity diagnostic for difficult low-stiffness/high-IOP regimes.
```

### Why raw_branch1 remains retained

`raw_branch1` is kept only as diagnostic evidence. It helps determine whether the official `atlasA0` branch is aligned with a globally persistent raw modal-atlas branch in regimes where the raw branch itself is stable.

It should not appear in routine production workflows and should not be interpreted as a better branch than `atlasA0`.

### Current ambiguity boundary

The known ambiguity corner remains:

```matlab
IOP_mmHg = 35;
mu_kPa = 25;
k1_kPa = 25;
k2 = 100;
thickness_um = 550;
```

This corner should be reported as a modal-family ambiguity regime under residual-only tracking, not as evidence that the official policy should be made more permissive.

### Tests for closure

The closure is validated by:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_branch_policy_validation
test_acoustoelastic_iop_hgo_short_entrypoints
run_all_smoke_tests
```

The branch-policy validation test enforces that:

```text
atlasA0 is accepted
identityA0Diagnostic is accepted as diagnostic
strictA0 is rejected
smallGapInterpolation is rejected
raw_branch1 is rejected as a policy
```

### Final policy

Use `atlasA0` for production analyses.

Use `identityA0Diagnostic`, `raw_branch1`, and `branch_families` only to inspect, validate, or explain branch ambiguity.

Any future improvement inside the ambiguous corner should add a stronger modal-identity criterion, not another residual-only alias for the same branch policy.

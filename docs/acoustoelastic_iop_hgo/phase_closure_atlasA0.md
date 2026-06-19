### atlasA0 optimization phase closure

This note closes the current optimization phase for the acoustoelastic IOP/HGO solver branch policy.

### Closed phase

The closed phase is:

```text
atlasA0 conservative branch tracking and validation
```

The official production policy remains:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

The official production output remains:

```matlab
result.Cp
result.validCp
```

### Validation commands

The phase was closed after validating the maintained short entrypoints:

```matlab
clear functions
rehash toolboxcache
startup

test_acoustoelastic_iop_hgo_short_entrypoints
```

The expected smoke-test message is:

```text
Short acoustoelastic IOP/HGO entrypoint path test passed.
```

The main validation and diagnostic scripts for this phase are:

```matlab
compare_atlasA0_vs_raw_branch1
validate_atlas_raw_grid
diagnose_raw_branch_corner
diagnose_branch_families
```

### Policy decision

The validation evidence supports the following decision:

```text
Keep atlasA0 as the conservative official output.
Do not promote identityA0Diagnostic to production.
Do not promote raw_branch1 to production.
Do not promote branch_families to production.
```

### Ambiguity boundary

The low-stiffness/high-IOP corner is treated as an explicit ambiguity regime:

```matlab
IOP_mmHg = 35;
Mu_kPa = 25;
```

Use the helper below when scripts or reports need to mark this known validation limit:

```matlab
status = aeClassifyAmbiguityRegime(struct( ...
    'IOP_mmHg', 35, ...
    'Mu_kPa', 25));
```

Expected classification:

```text
status.isKnownAmbiguous = true
status.severity = "high"
status.label = "low_mu_high_iop_modal_family_ambiguity"
```

### What should not be changed in this closure

Do not change the following as part of this closed phase:

- Do not replace `atlasA0` with `identityA0Diagnostic`.
- Do not replace `atlasA0` with `raw_branch1`.
- Do not make `branch_families` a production selector.
- Do not mutate `result.Cp` or `result.validCp` from diagnostic code.
- Do not tune residual minima retention merely to force continuity in the ambiguous corner.

### What remains open

The following is outside the closed phase and should be treated as a future project phase:

```text
advanced modal identity resolution
```

That phase may require:

- modal-shape information;
- continuity across material-parameter sweeps;
- stronger low-frequency physical plausibility constraints;
- validation against FEM or an alternative formulation.

### Final status

The current solver optimization phase is closed under the conservative `atlasA0` policy.

Remaining work is framework hygiene and future optional modal-identity research, not further residual-tracking tuning.

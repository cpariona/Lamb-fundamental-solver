### identityA0Diagnostic policy

`identityA0Diagnostic` is an optional diagnostic branch policy for the acoustoelastic IOP/HGO atlas solver.

It does not replace the official maintained output.

The following fields remain the conservative atlas output:

- `result.phaseVelocity_mps`
- `result.validMask`
- `result.selectedBranch`
- `result.selectedBranchPoints`

The policy only adds a separate diagnostic branch under:

`result.diagnostics.identityA0`

### How to enable

```matlab
options = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
options.atlasBranchPolicy = "identityA0Diagnostic";
result = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, options);
```

The official production policy remains:

```matlab
options.atlasBranchPolicy = "atlasA0";
```

### Output fields

When `identityA0Diagnostic` is active, the solver adds:

```matlab
result.diagnostics.identityA0.policyName
result.diagnostics.identityA0.officialPolicyEquivalent
result.diagnostics.identityA0.note
result.diagnostics.identityA0.frequency
result.diagnostics.identityA0.CpCandidate
result.diagnostics.identityA0.validCandidate
result.diagnostics.identityA0.addedFromIdentityScore
result.diagnostics.identityA0.branchIdentityScore
result.diagnostics.identityA0.candidateRank
result.diagnostics.identityA0.candidateClass
result.diagnostics.identityA0.candidateSource
result.diagnostics.identityA0.score
result.diagnostics.identityA0.summary
```

### Meaning of the fields

`CpCandidate` starts from the official `result.phaseVelocity_mps` values and fills only missing frequencies where the branch-identity score finds a strong or caution candidate.

`validCandidate` is true where either the official branch is valid or a diagnostic candidate was added.

`addedFromIdentityScore` is true only at frequencies filled by the identity-score diagnostic.

`branchIdentityScore`, `candidateRank`, and `candidateClass` describe the accepted diagnostic candidate.

### Candidate classes

The diagnostic score uses:

- `strong_diagnostic_candidate`
- `caution_diagnostic_candidate`
- `not_recommended`

Only strong and caution candidates are allowed to fill `CpCandidate` at missing official frequencies.

### Safety rule

Do not use `result.diagnostics.identityA0.CpCandidate` as the official dispersion curve unless it has been explicitly validated for the parameter regime.

The official branch remains:

```matlab
result.phaseVelocity_mps
result.validMask
```

### Validation test

A dedicated test checks that the diagnostic policy does not modify official fields:

```matlab
test_acoustoelastic_iop_hgo_identityA0_diagnostic_policy
```

The test compares:

```matlab
resultAtlas.phaseVelocity_mps
resultAtlas.validMask
```

against the official fields returned when:

```matlab
options.atlasBranchPolicy = "identityA0Diagnostic";
```

and verifies that only `result.diagnostics.identityA0` is added.

### Recommended use

Use this policy for inspection, plotting, and validation of difficult regimes such as:

- low shear modulus;
- high IOP;
- crowded objective landscapes;
- terminal atlasA0 truncation.

Do not use it as a replacement for `atlasA0` in production analyses until broader validation confirms physical plausibility over complete branches.

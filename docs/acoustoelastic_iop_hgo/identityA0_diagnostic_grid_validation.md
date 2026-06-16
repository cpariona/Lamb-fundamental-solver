### identityA0Diagnostic grid validation

This diagnostic validates the optional `identityA0Diagnostic` policy over the same 110-case grid used for branch-identity score validation.

It is stricter than the score-only grid because it runs both policies:

```matlab
options.atlasBranchPolicy = "atlasA0";
options.atlasBranchPolicy = "identityA0Diagnostic";
```

and checks that the official fields are identical:

```matlab
resultAtlas.Cp == resultIdentity.Cp
resultAtlas.validCp == resultIdentity.validCp
```

If either official field changes, the script throws an error.

### Runnable script

`validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid`

Run from the desired output root:

```matlab
cd('E:\')
startup
validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
AcoustoelasticIOPHGOIdentityA0DiagnosticGridAggregate
```

Outputs are written under:

`Results/acoustoelastic_iop_hgo_identityA0_diagnostic_grid`

### Grid definition

The main grid uses:

```matlab
IOP_mmHg = [5, 15, 25, 35];
mu_kPa = [25, 50, 100];
k1_kPa = [10, 25, 50];
k2 = [50, 100, 200];
thickness_um = 550;
```

This gives 108 material/IOP cases.

A small thickness probe is also included:

```matlab
IOP_mmHg = 25;
mu_kPa = 50;
k1_kPa = 25;
k2 = 100;
thickness_um = [450, 650];
```

Total cases: 110.

### Output tables

The script writes:

- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_summary.csv`
- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_added_candidates.csv`
- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_aggregate.csv`
- `acoustoelastic_iop_hgo_identityA0_diagnostic_grid_workspace.mat`

Workspace variables:

- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridSummary`
- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridAddedCandidates`
- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridAggregate`
- `AcoustoelasticIOPHGOIdentityA0DiagnosticGridOutputFolder`

### Main metrics

Per case, the summary table reports:

- official valid points;
- candidate valid points;
- added diagnostic candidate points;
- official valid fraction;
- candidate valid fraction;
- valid-fraction gain;
- first official missing frequency;
- first candidate missing frequency;
- last official valid frequency;
- last candidate valid frequency;
- median score and rank of added candidate points;
- whether the official branch was truncated;
- whether the diagnostic candidate extends the official branch;
- whether the diagnostic candidate reaches the final frequency.

The aggregate table reports:

- number of cases;
- number of officially truncated cases;
- number of cases where `identityA0Diagnostic` extends the official branch;
- truncated cases extended and not extended;
- number of candidates reaching the final frequency;
- median official and candidate valid fractions;
- median valid-fraction gain;
- median number of added points;
- median score and rank of added points.

### Interpretation

This validation answers:

> Does `identityA0Diagnostic` preserve official atlas output while adding a useful separate candidate branch?

Possible outcomes:

- If official fields are preserved and most truncated cases are extended, the policy is useful for diagnostic plotting and inspection.
- If official fields change, the implementation is invalid.
- If many truncated cases are not extended, the score is not sufficiently useful as a diagnostic branch builder.

### Safety rule

The policy is still diagnostic. Even if `result.identityA0.CpCandidate` improves coverage, production analyses should continue to use:

```matlab
result.Cp
result.validCp
```

unless a later validation explicitly promotes the identity-scored branch.

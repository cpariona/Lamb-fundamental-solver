# Naming strategy

Maintained MATLAB responsibilities have one canonical command name. Git
history, not forwarding aliases, preserves removed names.

## Families

Model internals use `rl*`, `mrlfe*`, and `ae*`. Established explicit AE
scientific functions may retain their descriptive `Acoustoelastic` names.
Application translation and shared UI helpers use `gui*`; component builders
use `create*`.

Public solver APIs are:

```matlab
lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes
lamb.models.mrlfe.mrlfeSolve
lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch
```

Examples use `run_*`, `fit_*`, or `<model>_sweep_*`. Diagnostics use
`diagnose_*`, `validate_*`, or `summarize*`. Tests use `test_*`. The only
maintained runners are the six `run_*` validation tiers documented in
`../../tests/README.md`.

Every function filename must match its top-level function exactly, including
case. Names must be globally unambiguous across tracked MATLAB files and must
not exceed `namelengthmax`.

## Parameters and outputs

Parameter naming follows each maintained public contract; cross-family symmetry
does not require identical field spellings when the APIs intentionally differ.

The canonical mRLFE request uses unit-qualified fields:

```text
mu_Pa
etaS_Pas
rho_kgm3
thickness_m
fluid density_kgm3
fluid soundSpeed_mps
```

Rayleigh-Lamb and AE workflow/public parameter structs retain established SI
names such as `mu`, `rho`, and `thickness`. In every family, `thickness` or
`thickness_m` means the full physical plate thickness `2h`, not half-thickness.
Half-thickness is internal model state only.

Workflow/app aliases are translated at the model boundary rather than becoming
parallel public schemas. For mRLFE, `lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest` owns translation
from maintained aliases such as `mu`, `rho`, and `thickness` to the canonical
unit-qualified request.

Generated results use:

```text
Results/rayleigh_lamb/<task>
Results/mrlfe/<task>
Results/ae_iop_hgo/<task>
```

A rename must update callers, callbacks, tests, runners, and documentation in
the same branch. Compatibility aliases require a separately documented public
contract and removal plan.

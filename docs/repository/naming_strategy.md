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
rlComputeFundamentalLambModes
mrlfeSolve
solveAcoustoelasticIOPHGOBranch
```

Examples use `run_*`, `fit_*`, or `<model>_sweep_*`. Diagnostics use
`diagnose_*`, `validate_*`, or `summarize*`. Tests use `test_*`. The only
maintained runners are the six `run_*` validation tiers documented in
`../../tests/README.md`.

Every function filename must match its top-level function exactly, including
case. Names must be globally unambiguous across tracked MATLAB files and must
not exceed `namelengthmax`.

## Parameters and outputs

The request field `thickness_m` means total thickness `2h`; use `mu`, `nu`, and
`rho` for soft-material elastic inputs. Generated results use:

```text
Results/rayleigh_lamb/<task>
Results/mrlfe/<task>
Results/ae_iop_hgo/<task>
```

A rename must update callers, callbacks, tests, runners, and documentation in
the same branch. Compatibility aliases require a separately documented public
contract and removal plan.

# Execution-profile surface integration

The solver GUI defaults to Balanced and FitTool defaults to Fast. Both expose
Fast, Balanced, and Robust where supported. The field `executionProfile` is the
canonical app request; `robustness` remains an app-normalization compatibility
alias.

| Model | Solver GUI | FitTool |
| --- | --- | --- |
| Rayleigh-Lamb | direct Fast/Balanced/Robust solver options | same solver options through fitting |
| mRLFE | direct public numerical preset | direct public numerical preset through fitting |
| AE IOP/HGO | atlas preset plus explicit controls | atlas preset plus explicit controls |

## execution-profile metadata contract

App results record requested/effective profile, source/default, internal solver
or atlas preset, route policy, override status/reason, supported profiles, and
surface default. A requested profile does not alter physical parameters or
branch policy.

The retired sweep GUI is no longer an execution-profile surface. Sensitivity
studies configure canonical model options explicitly and remain outside the app
profile contract.

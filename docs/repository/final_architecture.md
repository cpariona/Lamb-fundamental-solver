# Architecture and ownership

## Repository domains

| Location | Responsibility |
| --- | --- |
| `src/+lamb/` | Forward science and inverse fitting |
| `app/` | Request translation, workflow coordination, presentation and persistence |
| `studies/` | Opt-in scientific investigations consuming production APIs |
| `examples/` | Opt-in usage examples consuming production APIs |
| `tests/` | Executable contracts, regressions, performance checks and tooling |

## Production ownership

| Package under `src/+lamb/` | Owner responsibility |
| --- | --- |
| `+models` | Forward physics, configuration, tracking, selection, validity, quality and canonical results |
| `+fitting` | Experimental-data validation, family adapters, objectives, optimization, metrics and sensitivity |
| `+elasticity` | Model-neutral material conversions |
| `+grids` | Model-neutral frequency-grid construction |
| `+sweeps` | Parameter-sweep execution through supplied production operations |

The model families are `rayleigh_lamb`, `mrlfe`, and
`acoustoelastic_iop_hgo`. Each owns its physical formulation and numerical
selection pipeline; their internal structures reflect different physics.

Rayleigh-Lamb keeps parameter validation, material/geometry construction,
physical branch identity, the regular boundary equation and continuation directly
in its family package. `rlComputeFundamentalLambModes` owns the complete solve,
with local option validation, result assembly and selected-mode quality assessment.
The `approximations` package retains its public analytical-reference operation.

mRLFE keeps request/preset resolution in `configuration`, problem construction
and residual physics in `core`, seed/discovery/refinement in `tracking`,
termination in `policies`, output assembly in `results` and selected-curve
assessment in `quality`. `mrlfeSolve` owns the branch workflow once; explicit
elastic and viscous option preparation feeds the same seed/tracking/policy chain.

Dependencies point toward scientific owners. Models do not depend on fitting,
app, studies, examples, tests or documentation. Fitting calls canonical public
model APIs. Production never depends on studies, examples, tests or documentation.
The sole intentional cross-family scientific dependency is the mRLFE seed through
the public Rayleigh-Lamb solver. Model-neutral utilities do not own family policy.

## Canonical scientific chains

Rayleigh-Lamb:

```text
request/config -> material + geometry -> physical A0/S0 identity
-> regular boundary equation / request-independent continuation -> canonical result
```

mRLFE:

```text
request/config -> problem -> public RL seed -> discrete candidate discovery
-> selection -> bounded selected-candidate refinement
-> validity/termination -> canonical result
```

AE IOP/HGO:

```text
request/config -> constitutive/prestress state -> fixed atlas -> minima/linking
-> atlasA0 selection -> bounded true-SVD refinement -> validity -> canonical result
```

Fitting:

```text
experimental fixed mask -> family adapter -> canonical public model
-> residual/objective -> optimizer -> metrics/sensitivity
```

Quality assesses an already selected curve. Diagnostic evidence remains separate
from official scientific arrays; AE official output is `atlasA0`.

## Presentation boundary

App translates UI state into requests and coordinates, presents or persists
already computed results. It never owns science. Physical parameters, numerical
options, execution profiles and UI state have distinct owners. Profiles vary
effort while preserving physical meaning. Public model and fitting entrypoints
are listed in [README](../../README.md); use MATLAB help for their SI inputs,
full physical thickness convention, unit-qualified outputs and validity contracts.

[AGENTS](../../AGENTS.md) owns modification policy and links to local invariants.
[Validation](validation_status.md) owns the canonical test contract.

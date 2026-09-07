# Rayleigh-Lamb solver

The maintained elastic A0/S0 solver lives in `src/+lamb/+models/+rayleigh_lamb/`.
Its public contract is in `public_api.md`.

## Scientific ownership

- `api/`: public defaults and the maintained model entrypoint.
- `configuration/`: frequency-grid construction and parameter/option validation.
- `core/`: material/geometry construction and branch specification.
- `solvers/`: model-level fundamental-mode solve orchestration.
- `equations/`: antisymmetric and symmetric Rayleigh-Lamb residuals.
- `tracking/`: `lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch`, the shared continuation owner.
- `quality/`: post-solve quality assessment through `lamb.models.rayleigh_lamb.quality.rlEvaluateModeQuality`.
- `approximations/`: A0 thin-plate and S0 extensional approximations.
- `results/`: canonical scientific result assembly.
- `src/+lamb/+elasticity/`: shared isotropic elastic-material conversions.

Soft-material inputs use `ShearPoisson`: mu, nu, and rho determine E,
lambda_Lame, K, CT, and CL through `lamb.elasticity.elasticFromMuNu`.
`LameParameters` is available for explicit formulation checks. Full
thickness is the public geometry input; half-thickness is internal.

The public API validates the request and delegates the numerical solve to the
model-level solver. Each enabled fundamental branch is tracked from a
branch-specific initial estimate using residual minima and continuation. Search
and acceptance controls are numerical options, not material parameters. RL has
no mRLFE flags or dependency. The reverse dependency is restricted to mRLFE
seed construction.

## Workflows

The opt-in `runRayleighLambSensitivity` study composes the
`lamb.sweeps.runParametricSweep` iterator and public
RL solver. Plot-data extraction owns branch selection and units; renderers
only display the already-computed curves.

`lamb.fitting.rayleigh_lamb.rlFitDispersionData` delegates optimization to the shared fitting owner.
Its evaluator uses the same model-layer `lamb.models.rayleigh_lamb.tracking.rlSolveFundamentalBranch`, with
an internal continuation grid retaining exact experimental frequencies and
prediction fallback disabled. It does not call the batch-grid public compute
API; replacing this route would change the established fitting semantics.
See `fitting_workflow.md`.

## Use and validation

Run `startup` for production APIs. Examples are not added globally:

```matlab
run('examples/rayleigh_lamb/basic/run_default_A0_S0.m')
run('examples/rayleigh_lamb/fitting/fit_default_A0.m')
run('studies/sensitivity/rayleigh_lamb/study_thickness_A0.m')
```

Numerical regression owns basic branch and synthetic recovery fixtures;
extended integration owns broader fitting cases. Complete validation uses
all six tiers listed in `tests/README.md`, not just the extended tier.

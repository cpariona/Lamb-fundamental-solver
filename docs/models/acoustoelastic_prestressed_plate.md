# Acoustoelastic prestressed plate: current A0 implementation

## Physical scope

Native inverse results, including rejected candidates, can be inspected with
`plotAePlateFitDiagnostics` and `plotAePlateParameterTrends` in
[the app visualization owner](../../app/visualization/README.md).
These operations do not fit data, change the fixed mask or recompute residuals.
The Li regression remains native and unweighted. A supported coefficient candidate
may be evaluated through `aePlateSolveDispersion`; an unsupported candidate must
not produce a forward curve. Diagnostic unconstrained lines are distinct from
physical acceptance. Display limits and source ridge flags are not eligibility
rules. Native acceptance and model-conditional alpha-minus-gamma interpretation
do not establish experimental A0 purity or physical validation.

The family and principal APIs describe the physical formulation. The current
implementation supports A0 only; the mode-specific mathematical helper is
`aePlateA0MasterCurve`. These names do not imply S0 or higher-mode support.

The model follows Li, Gower, Destrade and Yun, *Non-destructive mapping of
stress and strain in soft thin films through sound waves*, Communications
Physics 5, 231 (2022), [published article](https://www.nature.com/articles/s42005-022-01000-3).
The [published supplement](https://static-content.springer.com/esm/art%3A10.1038%2Fs42005-022-01000-3/MediaObjects/42005_2022_1000_MOESM1_ESM.pdf)
contains the derivation, sensitivity, regression and transverse-propagation
discussion in Notes 1, 2, 7 and 8. The authors' earlier
[preprint](https://arxiv.org/abs/2201.01847) gives the general principal
stress/stretch identities in Methods, Eqs. (3)-(6), sensitivity in its
Supplementary Note 1 and regression in Supplementary Fig. S6. Its numbering
differs from the published supplement.

The maintained equations follow Supplementary Note 1, Eqs. (S.2)-(S.8),
the sensitivity limitations in Note 2, Eqs. (S.11)-(S.18), the original
regression in Note 7, and the general/transverse identities in Note 8,
Eq. (S.22).

There is an apparent sign inconsistency in the printed two-point stress
formula (S.11) of Note 2. Set `x_i=eta_i^2`, `y_i=rho*Cp_i^2` and use its
printed `F=(x_1+x_2-2)/(x_1-x_2)`. Direct elimination from Note 7 gives
`alpha-gamma=(y_1+y_2)/2-(y_1-y_2)*F/2`, with a minus sign before the
last term. Equation (S.11) prints a plus. For the independent synthetic
`alpha=314300 Pa`, `gamma=147200 Pa`, `q=[0.1,5]` example, elimination gives
`167100 Pa`; the printed plus expression gives approximately `300091.328 Pa`.
This implementation uses the requested Note 7 regression directly. No printed
two-point stress or sensitivity formula is executed in production, and no
experimental uncertainty bounds are claimed here. The discrepancy is an
algebraic finding, not an author-issued correction.

Assumptions are a homogeneous elastic membrane, initially isotropic and
approximately incompressible, homogeneous principal predeformation, propagation
along a principal in-plane direction, and traction-free faces. The reduction
`2*beta = alpha + gamma` is the moderate-strain, third-order elastic
approximation used in the paper; it is not a general constitutive identity
for arbitrary finite strain or arbitrary hyperelastic materials. No material
constants or stress/stretch assignments are inferred from names or metadata.

This implementation supports the stable tensile or unstressed regime
`alpha >= gamma > 0`. It does not model compression/buckling, viscosity,
intrinsic anisotropy, fluid loading, corneal mechanics, S0 or higher modes.
Numerical acceptance cannot establish these assumptions from phase speeds.

## Units and physical branch

All dimensional inputs use SI. `thickness_m` is **current full physical
thickness**, not reference thickness and not optical path length. The equations
use `h = thickness_m/2`, `omega = 2*pi*frequency_Hz`, `k = omega/Cp`, and
`q = k*h = pi*frequency_Hz*thickness_m/Cp`. Density is current bulk mass
density in kg/m^3; moduli and stress differences are Pa; `Cp` is m/s.

The dimensionless equation is

```text
4*eta*tanh(eta*q)/tanh(q) = (1+eta^2)^2
rho*Cp^2 = alpha - gamma*eta^2
```

The physical A0 branch decreases from `eta=1` at `q=0` to
`etaInfinity=0.29559774252208477...` as `q` tends to infinity. The latter is the
positive root of `eta^3+eta^2+3*eta-1=0`. The constant solution `eta=1` at
positive `q` is spurious: its two thickness roots coincide and the unregularized
boundary determinant vanishes without a physical mode.

`aePlateA0MasterCurve(q)` divides the residual analytically by `1-eta^2`.
For `q <= 0.05` it solves for `z=(1-eta^2)/q^2` using the deflated tanh
series through its thirteenth-order term. This keeps the finite flexural
correction when subtracting two nearly equal floating-point values would
erase it. In particular, `1-eta^2 ~ (4/3)*q^2`. Intermediate arguments use
an exponential divided difference; at `q >= 64` the exponentially small
correction to the Rayleigh root is below double precision. Zero and positive
infinity are accepted as limits. Negative, NaN or complex arguments are
rejected. Output arrays retain input shape. Values smaller than floating-point
range cannot retain their correction.

`aePlateSolveDispersion(frequency_Hz, physical)` solves `omega*h = q*Cp(q)` in `log(q)`
to avoid an absolute tolerance erasing very small positive wavenumbers. Its
physical struct requires `alpha_Pa`, `gamma_Pa`, `density_kgpm3`, `thickness_m`.
Result vectors are columns in requested order, including duplicate frequencies.
Zero frequency returns `Cp(0)=sqrt((alpha-gamma)/rho)`, including zero for an
unstressed membrane. The high-frequency limit is
`sqrt((alpha-gamma*etaInfinity^2)/rho)`. Very large or small dimensional inputs
can exceed numerical range and are not production-qualified by the tests.

## Linear inverse API

```matlab
startup
physical = struct('density_kgpm3', 1070, 'thickness_m', 0.0005);
parameters = physical;
parameters.alpha_Pa = 314300;
parameters.gamma_Pa = 147200;
mode = lamb.models.acoustoelastic_prestressed_plate.aePlateSolveDispersion((2000:2000:20000)', parameters);

experimental = struct('frequency_Hz', mode.frequency_Hz, ...
    'Cp_mps', mode.phaseVelocity_mps, 'validMask', true(size(mode.frequency_Hz)), ...
    'conditionId', "single_state", 'directionId', "+principal_1");
fit = lamb.fitting.acoustoelastic_prestressed_plate.aePlateFitDispersion(experimental, physical);
assert(fit.accepted);
state = lamb.models.acoustoelastic_prestressed_plate.aePlateInterpretModuli(fit.alpha_Pa, fit.gamma_Pa);
```

Experimental vectors have equal lengths. `validMask` is required and logical.
The original experimental struct is retained unchanged in the result; calculated
vectors and `result.validMask` are columns with the same order and selection.
Selected observations require finite positive Hz and speeds. Invalid selected
inputs cause rejection by error; they are never silently removed. Excluded
values may be NaN and have NaN calculated outputs. The shared nonlinear-data
normalizer is deliberately not used because it can reduce a supplied mask.

`conditionId` and `directionId` are nonempty text, either scalar for the entire
dataset or one value per observation. All selected observations must have one
condition and one signed direction. Call separately for other conditions,
loads, regions, acquisition states or opposite directions. These labels record
caller-supplied grouping; the API cannot detect incorrectly labelled pooling.
Calling the fit asserts that the selected speeds belong to A0 and satisfy the
physical assumptions above.

For selected observations, the ordinary unweighted regression design is
`[ones(n,1), -etaSquared]`, the response is `density_kgpm3*Cp_mps.^2`, and
the parameters are `[alpha_Pa; gamma_Pa]`. Economy SVD solves the linear
problem directly, with no normal equations or nonlinear optimizer. There are
no statistical weights or automatic averaging, including when input metadata
contain speed standard errors.

Diagnostics expose singular values, numerical rank, the rank threshold
`max(size(design))*eps(largestSingularValue)`, condition number, observation
count, distinct-frequency count, replicate counts and distinct-frequency
coverage. Without `experimental.independentFrequencyGroupId`, exact supplied Hz
define distinct frequencies and the historical result fields remain unchanged.
No frequency rounding or instrument-resolution tolerance is introduced.

The optional `independentFrequencyGroupId` is a real double vector with exactly
one code per observation, in the original row order (no scalar broadcasting).
Codes are positive, finite integers no greater than `flintmax`; excluded rows may
instead use NaN. Invalid supplied codes are errors, never a reason to shrink the
mask or fall back to observed-Hz grouping. Codes have no units and identify
caller-declared physical excitation-frequency groups. They must not encode run,
repetition or Pulse period identity. The native API cannot authenticate the
physical meaning of caller-supplied codes or recover precision already lost in
metadata. Renumbering codes does not change the scientific partition.

For the selected partition, mean `eta^2` is used **only for coverage diagnostics**;
every observation remains a separate row in the original unweighted regression
at its actual observed Hz and speed. Observation-level rank two can arise from
within-group scatter; group-level rank, condition and span are separate screens.
Two declared groups alone do not establish identifiability, statistical independence
of repetitions, experimental validity or model support. Neither speeds nor
frequencies are averaged or substituted. Additional repetitions retain their
original contribution to the OLS objective; no group weighting is introduced.

The diagnostic indexing contract is:

| Field | Meaning |
| --- | --- |
| `uniqueFrequency_Hz` | Sorted unique selected **observed Hz**, in both modes |
| `frequencyGroup` | One index per selected observation, in selected-row order, into the coverage groups |
| `frequencyObservationCount`, `frequencyEtaSquared` | Count and mean `eta^2` per coverage group |
| `independentFrequencyCount` | Number of selected coverage groups |
| `frequencyDesignRank`, `frequencyConditionNumber`, `etaSquaredSpan` | Existing qualification diagnostics of the group-mean design |

With explicit codes, `frequencyGroupingSource="explicit_group_id"` and sorted
`independentFrequencyGroupId` identify those coverage groups:
`independentFrequencyGroupId(frequencyGroup)` reconstructs the selected input codes.
The additional `observedFrequencyGroup` indexes `uniqueFrequency_Hz`, so
`uniqueFrequency_Hz(observedFrequencyGroup)` reconstructs the selected observed Hz.
These three additional diagnostic fields are present only in explicit mode.
The observed-Hz list can have a different length from the coverage-group arrays;
it must not be indexed with physical group assignments. Without explicit codes,
`frequencyGroup` retains its historical index into `uniqueFrequency_Hz`.

Default numerical qualification requires at least two independent frequency groups,
rank two in both designs, condition numbers at most `1e6`, and a per-frequency
`eta^2` span of at least `1e-3`. The optional struct fields
`maximumConditionNumber` and `minimumEtaSquaredSpan` expose those two thresholds.
They are engineering screens, not universal experimental identifiability bounds.
Low-`kh` data mainly identify `alpha-gamma`; high-`kh` data mainly identify
`alpha-etaInfinity^2*gamma`. Data confined to either plateau cannot reliably
separate both parameters. Repeating a frequency does not add frequency coverage.

Rank-deficient fits return NaN parameters. Full-rank but poorly conditioned,
insufficiently dispersed, or nonphysical fits retain unconstrained candidate
moduli and residuals for diagnosis with `accepted=false` and explicit `reasons`.
No coefficients are clipped, no masks are changed and no alternative fit is
substituted. `alpha < gamma` is outside the maintained tensile model support.
Callers must check `accepted` before interpreting candidate moduli. If both
moduli are positive but their difference is negative within the roundoff screen
`32*eps(max(abs(candidate)))*conditionNumber` Pa, the fit remains unaccepted
with `tensile_boundary_unresolved` instead of classifying a resolved physical
violation. The screen is reported in `stressDifferenceRoundoffBound_Pa` when
physical support fails; it is not an experimental error or confidence bound.
This can occur at zero true stress. No coefficient or stress is rounded to zero.

The fitting result identifies its family as
`result.model="acoustoelastic_prestressed_plate"`. Family-specific exceptions
use `lamb:aePlate:` identifiers. These identifiers and the public operation
names follow the physical formulation; the cited publication remains scientific
provenance. Callers must use the documented package/API names directly.

`regressionResidual_Pa` is fitted minus observed `rho*Cp^2` at the **measured**
`kh`. `regressionRMSE_Pa` uses the number of selected observations; the sum of
squares is `sumSquaredResidual_Pa2`. These are not speed residuals or
frequency-domain forward-prediction residuals. Use `aePlateSolveDispersion` separately
for a forward curve. Both response and predictor depend on measured speed;
the original OLS fit therefore has errors in variables. It provides no
calibrated uncertainty interval or statistical independence claim for repeated
observations. Thickness/density uncertainty and mode assignment remain caller
responsibilities.

## Physical interpretation

Under the stated principal-axis isotropic incompressible assumptions,

```text
alpha-gamma = sigma_propagation-sigma_normal
sqrt(alpha/gamma) = lambda_propagation/lambda_normal
```

`aePlateInterpretModuli(alpha_Pa, gamma_Pa)` returns exactly these two quantities.
It requires positive finite moduli and does not return an absolute stress.
A known normal traction is needed to set an absolute stress; in a verified
traction-free membrane `sigma_normal=0`, so the difference equals the in-plane
principal stress. An arbitrary directional stress component or a general
hydrostatic stress is not identified by this operation.

By default absolute stretches are NaN. Passing the explicit third argument
`"uniaxial"` asserts uniaxial deformation **along propagation** with equal
transverse and thickness stretches. Only then does it return
`lambda_propagation=(alpha/gamma)^(1/3)` and transverse stretches
`lambda_propagation^(-1/2)`. This cubic relation is not valid for general
biaxial deformation. A measurement transverse to uniaxial tension has
`lambda_propagation=lambda_normal`, so its modulus ratio cannot recover the
applied longitudinal stretch. Separate principal-direction measurements can
provide two ratios; their combination with incompressibility is outside this
single-direction API.

## Validation

Maintained model and fitting suites are registered in the canonical numerical
regression group. They test independent 80-digit roots of the original
equation, limits, full/half-thickness and angular conversions, independent
forward values, SVD versus QR, synthetic recovery, masks, repeat counts,
single-frequency scatter, plateau rank/conditioning, rejected coefficients,
and general versus explicitly uniaxial interpretation. Existing physics,
golden references and tolerances are unchanged.

From the repository root, targeted execution is:

```matlab
startup;
addpath(fullfile(pwd, 'tests', 'tooling'));
configureTestPath;
results = runtests({'tests/models/acoustoelastic_prestressed_plate/test_ae_plate_model.m', ...
    'tests/fitting/acoustoelastic_prestressed_plate/test_ae_plate_fitting.m'});
assertSuccess(results);
```

Then run the full [maintained gate](../repository/validation_status.md).

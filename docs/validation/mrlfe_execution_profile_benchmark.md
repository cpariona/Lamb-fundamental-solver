# mRLFE Execution Profile Benchmark

This document records the controlled mRLFE execution-profile evaluation added
after manual GUI validation.

## Purpose

Manual testing showed that mRLFE reports:

```text
Fast     -> requested/effective Fast/Fast
Balanced -> requested/effective Balanced/Fast
Robust   -> requested/effective Robust/Fast
```

but elapsed time appeared to change between profiles. This benchmark checks
whether those differences are caused by:

- effective options changing;
- curve or route changes;
- or timing variability.

No new mRLFE profiles are introduced here.

## Script

Run:

```matlab
clear; clc; close all;
startup
[resultsTable, summaryTable] = benchmarkMRLFEExecutionProfiles( ...
    'Repeats', 5, ...
    'FitRepeats', 3, ...
    'WriteCsv', false);
```

CSV output is opt-in:

```matlab
benchmarkMRLFEExecutionProfiles('WriteCsv', true)
```

## Method

Cases:

```text
Surface: Main, Sweep, Fit
Requested profile: Fast, Balanced, Robust
Viscosity: etaS = 0, etaS = 0.05 Pa*s
```

The benchmark performs a warm-up call for each route before measuring.

Metrics:

- requested/effective profile;
- support mode;
- internal preset;
- actual route;
- elapsed time;
- median/min/max time;
- relative spread;
- options equality versus Fast;
- curve difference versus Fast;
- valid mask equality;
- route equality;
- metadata consistency.

Informational profile fields such as `executionProfile`, `robustness`, and
`effectiveExecutionProfile` are ignored when comparing effective options.

## Result Summary

Latest controlled run:

| Surface | Requested | etaS | Median time [s] | Options equal to Fast | Max abs Cp diff vs Fast [m/s] | Route equal |
| --- | --- | ---: | ---: | --- | ---: | --- |
| Fit | Fast | 0 | 0.102 | true | 0 | true |
| Fit | Balanced | 0 | 0.098 | true | 0 | true |
| Fit | Robust | 0 | 0.094 | true | 0 | true |
| Fit | Fast | 0.05 | 0.101 | true | 0 | true |
| Fit | Balanced | 0.05 | 0.101 | true | 0 | true |
| Fit | Robust | 0.05 | 0.101 | true | 0 | true |
| Main | Fast | 0 | 0.098 | true | 0 | true |
| Main | Balanced | 0 | 0.098 | false | 2.31e-05 | true |
| Main | Robust | 0 | 0.123 | false | 2.38e-06 | true |
| Main | Fast | 0.05 | 0.100 | true | 0 | true |
| Main | Balanced | 0.05 | 0.116 | false | 3.92e-05 | true |
| Main | Robust | 0.05 | 0.141 | false | 1.56e-05 | true |
| Sweep | Fast | 0 | 2.148 | true | 0 | true |
| Sweep | Balanced | 0 | 2.441 | false | 0.00719 | true |
| Sweep | Robust | 0 | 2.832 | false | 2.38e-06 | true |
| Sweep | Fast | 0.05 | 2.424 | true | 0 | true |
| Sweep | Balanced | 0.05 | 2.625 | false | 0.00655 | true |
| Sweep | Robust | 0.05 | 3.069 | false | 2.38e-06 | true |

## Option Differences

For Main and Sweep non-Fast requests, the options that differ from Fast are:

```text
gridPointsInitial
gridPointsTracking
jumpTol
mrlfeComplexMaxFunEvals
mrlfeComplexMaxIter
mrlfeGridPoints
searchFactors
```

These are inherited Rayleigh-Lamb seed/search options from the requested
profile. The mRLFE atlas presets still remain fast:

```text
fast_zero_viscosity_adaptive
fast_viscous
```

For Fit, Fast/Balanced/Robust are option-equivalent after ignoring the
informational requested-profile fields. Fit uses:

```text
fast_fit_atlas
```

## Curve and Route Comparison

Routes and valid masks matched Fast in all benchmark rows.

Curve differences were:

- exactly zero for Fit;
- very small but nonzero for Main and Sweep non-Fast requests, consistent with
  changed seed/search options rather than changed atlas presets.

## Conclusion

1. Main, Sweep, and Fit all keep mRLFE effective profile metadata as `Fast`.
2. Fit treats Balanced and Robust as true effective aliases of Fast for the
   measured options and curves.
3. Main and Sweep keep fast atlas presets but are not fully option-identical to
   Fast because the Rayleigh-Lamb seed/search options still follow the
   requested profile.
4. SweepTool's perceived timing differences are not only random variability;
   non-Fast requests change seed/search options even though the mRLFE atlas
   preset is mapped to Fast.
5. This does not justify adding dense mRLFE profiles in this branch.

## Recommendation

Keep Balanced and Robust visible as `mapped_to_fast` for now, but document the
current nuance:

```text
mRLFE fast atlas route is preserved, while Main/Sweep seed/search options may
still follow the requested profile.
```

Before introducing real mRLFE profiles, validate:

- which seed/search options should belong to mRLFE execution profiles;
- whether atlas density, candidate count, refinement, and A0 windows can be
  densified without branch switching;
- physical validity for `etaS = 0` and `etaS > 0`;
- cost impact for Main, Sweep, and Fit separately.

Do not decide based on elapsed time alone.

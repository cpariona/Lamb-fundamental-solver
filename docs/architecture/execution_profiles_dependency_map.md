# Execution Profile Dependency Map

Last updated: 2026-07-12

Execution profile is a user-facing density/performance preference. It is kept
separate from model route, branch selection, termination policy, fallback
policy, and optimizer settings.

## Rayleigh-Lamb

```text
requested Fast/Balanced/Robust
  -> rlResolveExecutionProfile
  -> rlDefaultOptions(profile)
  -> rlComputeFundamentalLambModes
```

Rayleigh-Lamb applies the requested profile directly.

## mRLFE

All maintained app surfaces route through the public production API:

```text
Main GUI  -> guiRunMRLFEModel      -> mrlfeSolve
SweepTool -> guiRunMRLFESweep      -> mrlfeSolve per point
FitTool   -> mrlfeEvaluateFitModel -> mrlfeSolve
```

The selected execution profile is applied directly to the public numerical
preset:

```text
Fast     -> fast     -> 50 Hz post-500-Hz solve step
Balanced -> balanced -> 25 Hz post-500-Hz solve step
Robust   -> robust   -> 20 Hz post-500-Hz solve step
```

The maintained app metadata contract is:

```text
requestedExecutionProfile = Fast | Balanced | Robust
effectiveExecutionProfile = requestedExecutionProfile
requestedNumericalPreset  = fast | balanced | robust
effectiveNumericalPreset  = requestedNumericalPreset
profileSupportMode        = direct
profileOverrideApplied    = false
```

Each app adapter writes the selected public preset into
`request.numerics.preset` after constructing the request. This explicit final
assignment prevents historical builders from silently restoring `fast`.

Branch policy is independent:

```text
A0Like -> selection adaptive, termination physicalTail, fallback none
S0Like -> selection adaptive, termination none, fallback none
```

Effective engines are neutral:

```text
etaS = 0 -> elastic_adaptive
etaS > 0 -> viscoelastic_adaptive
```

Historical route flags and metadata such as atlas route selectors, GUI fallback
fields, legacy fitting presets, and the former `mapped_to_fast` policy are not
maintained control flow.

## AE IOP/HGO

```text
requested Fast/Balanced/Robust
  -> aeResolveExecutionProfile
  -> atlas density mapping
```

AE IOP/HGO applies the requested profile directly to atlas density.

## Optimizers

Fit optimizers retain their explicit options:

```text
MaxIter
MaxFunEvals
TolX
```

These are not execution-profile aliases and are not changed by mRLFE route
cleanup.
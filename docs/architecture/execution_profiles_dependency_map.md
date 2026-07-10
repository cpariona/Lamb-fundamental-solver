# Execution Profile Dependency Map

Last updated: 2026-07-09

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
Main GUI  -> guiRunMRLFEModel  -> mrlfeSolve
SweepTool -> guiRunMRLFESweep  -> mrlfeSolve per point
FitTool   -> mrlfeEvaluateFitModel -> mrlfeSolve
```

mRLFE preserves the requested execution profile in metadata, but maps the
effective numerical preset to public `fast` for maintained app workflows.

```text
requestedExecutionProfile = Fast | Balanced | Robust
effectiveExecutionProfile = Fast
effectiveNumericalPreset  = fast
profileSupportMode        = mapped_to_fast
```

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
fields, and legacy fitting presets are not maintained control flow.

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

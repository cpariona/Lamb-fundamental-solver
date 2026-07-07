# mRLFE solver-route quick audit results

## Scope

This note records the first executable audit of the current mRLFE route matrix.

The quick matrix covered:

```text
branches:  A0Like, S0Like
etaS:      0, 0.05 Pa·s
mu:        75 kPa
thickness: 0.5 mm
frequency: 1–6 kHz, 10 points
```

Compared routes:

```text
main_gui
fit_fast_atlas
unified_atlas
legacy_compute
```

No route evaluation raised a MATLAB error.

## FitTool fast-atlas baseline

The `fast_fit_atlas` route completed successfully for all four quick cases.

Observed runtimes:

| Branch | etaS | Runtime |
| --- | ---: | ---: |
| A0Like | 0 | 0.326 s |
| S0Like | 0 | 0.273 s |
| A0Like | 0.05 | 0.386 s |
| S0Like | 0.05 | 0.310 s |

The fast route was consistently close to the Main GUI route:

| Branch | etaS | Max absolute Cp difference | Max relative difference |
| --- | ---: | ---: | ---: |
| A0Like | 0 | 0.00443 m/s | 0.000757 |
| S0Like | 0 | 0 | 0 |
| A0Like | 0.05 | 0 | 0 |
| S0Like | 0.05 | 0 | 0 |

This confirms that the FitTool fast-atlas implementation is not a separate physical model in the tested range. It is a reduced numerical preset for the same adaptive/unified route family.

It should be preserved as the reference performance baseline during restructuring.

## Critical zero-viscosity A0 finding

For `A0Like`, `etaS = 0`, the direct `solveMRLFEAtlasUnified` route disagreed strongly with all adaptive/reference routes.

Compared with Main GUI:

```text
maximum absolute difference: 5.29 m/s
RMS difference:              3.48 m/s
maximum relative difference: 0.632
```

Compared with FitTool fast atlas:

```text
maximum absolute difference: 5.29 m/s
RMS difference:              3.34 m/s
maximum relative difference: 0.632
```

This is not a small fast-versus-dense difference. The direct unified solver is selecting a materially different A0-like solution at zero viscosity.

The likely architectural cause is already visible in the current code:

```text
solveMRLFEAtlasUnified, etaS = 0
    -> solveMRLFEBranchModalAtlas

Main GUI / FitTool, etaS = 0
    -> solveMRLFEBranchAdaptiveAtlas
    -> physical tail policy
```

Therefore, the current `solveMRLFEAtlasUnified` function is not actually the unified production route for zero-viscosity A0.

It must not become the sole public solver without changing or replacing its elastic branch behavior.

## Main GUI zero-viscosity fallback

For `A0Like`, `etaS = 0`, Main GUI reported:

```text
actual route = zero_viscosity_adaptive_fallback
fallback     = true
validity     = 10/10
```

FitTool used the adaptive route without fallback:

```text
actual route = zero_viscosity_adaptive_atlas
validity     = 9/10
```

The Main GUI fallback curve was numerically identical to `legacy_compute` on the common valid points.

Main GUI versus legacy:

```text
maximum absolute difference = 0
RMS difference              = 0
```

Main GUI versus FitTool differed only slightly:

```text
maximum absolute difference = 0.00443 m/s
```

Interpretation:

- the Main GUI adaptive candidate failed its quality guard;
- the interface silently replaced it with the legacy reference route;
- FitTool retained the adaptive candidate;
- both outputs remain numerically close on their common valid points in this test;
- the interface route metadata is therefore essential and must not be discarded during cleanup.

The future architecture must make fallback an explicit solver policy rather than adapter-local behavior.

## Viscous A0 and S0 findings

For `etaS = 0.05`, Main GUI and FitTool were identical for both branches.

```text
A0Like: maximum difference = 0
S0Like: maximum difference = 0
```

The direct unified route differed from the fast routes by less than approximately `0.0008` relative error.

For A0Like:

```text
maximum absolute difference ≈ 0.00411 m/s
maximum relative difference ≈ 0.000698
```

For S0Like:

```text
maximum absolute difference ≈ 0.01246 m/s
maximum relative difference ≈ 0.000760
```

The direct unified and legacy-compute routes were effectively identical in the viscous cases:

```text
A0Like maximum difference ≈ 2.35e-7 m/s
S0Like maximum difference ≈ 3.57e-7 m/s
```

This indicates that, for the tested viscous configuration, `computeMRLFE` with its current options reaches the same dense unified-atlas solution.

The main distinction is numerical preset and runtime, not selected physical branch.

## S0 zero-viscosity finding

All four S0Like zero-viscosity routes were close.

The largest observed relative difference was below `0.00086`.

Main GUI and FitTool were identical.

This suggests that the major zero-viscosity inconsistency is currently specific to A0Like, not a general elastic mRLFE failure.

## Runtime comparison

Representative quick-case runtime ranges:

```text
FitTool fast atlas: 0.273–0.386 s
Main GUI:           0.288–0.621 s
Legacy compute:     0.250–0.337 s
Unified defaults:   0.837–1.109 s
```

The dense unified route was approximately two to four times slower than the fast routes in the quick matrix.

Replacing `fast_fit_atlas` with solver defaults would therefore be a material fitting regression.

The legacy route was also fast in this small matrix, but it does not provide the same route semantics across all regimes and should not be selected solely from these timing results.

## Architectural conclusions

The quick audit supports the following conclusions:

1. `fast_fit_atlas` must be preserved as a named numerical preset or equivalent configuration.
2. Main GUI and FitTool already share the same viscous physical route.
3. Main GUI and FitTool also share the same zero-viscosity adaptive implementation conceptually, but it is duplicated and their fallback behavior differs.
4. The direct unified solver cannot currently be treated as the canonical zero-viscosity A0 solver.
5. `computeMRLFE` and direct unified atlas are effectively duplicates for the tested viscous cases.
6. `computeMRLFE` still has operational value as the current Main GUI zero-viscosity fallback.
7. Fallback behavior, route selection, and numerical preset must be separated in the future API.
8. Existing wrapper names are not reliable indicators of numerical role.

## Immediate implications for restructuring

A destructive cleanup should not preserve the current wrapper hierarchy.

The future mRLFE implementation should instead centralize:

```text
physical regime selection
branch engine selection
numerical preset selection
branch policy
quality assessment
fallback policy
result metadata
```

A single production facade should be able to reproduce at least these explicit configurations:

```text
A0Like, etaS = 0, adaptive fast, no fallback
A0Like, etaS = 0, adaptive fast, fallback on failed quality
A0Like, etaS > 0, unified adaptive fast
A0Like, etaS > 0, unified adaptive dense
S0Like, etaS = 0, adaptive fast
S0Like, etaS > 0, unified adaptive fast
```

The current names `computeMRLFE`, `solveMRLFEAtlasUnified`, and the GUI/Fit wrappers should not be used as the final conceptual API.

## Next validation

Before implementation, run the full matrix:

```matlab
MRLFESolverRouteAuditFull = auditMRLFESolverRoutes('Mode', "full");
```

The full run is needed to determine:

- whether Main GUI fallback is frequent or isolated;
- whether fast and dense atlas routes diverge in soft/high-loss A0 cases;
- whether the unified elastic A0 disagreement persists across shear modulus;
- whether S0 remains stable over the expanded matrix;
- whether any legacy route can be removed immediately;
- suitable numerical tolerances for characterization tests.

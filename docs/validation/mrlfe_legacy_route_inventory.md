# mRLFE legacy route cleanup inventory

Date: 2026-07-09

This inventory records the pre-deletion caller review for obsolete mRLFE route
symbols after Main GUI, SweepTool, and FitTool migrated to `mrlfeSolve`.

| Symbol/file | Callers | Current role before cleanup | Decision | Replacement | Validation |
| --- | --- | --- | --- | --- | --- |
| `computeMRLFE` | Rayleigh-Lamb optional mRLFE embedding, obsolete tests, historical audits | Legacy real-k/complex-k route wrapper | Deleted | `mrlfeSolve`; Rayleigh-Lamb optional real-k embedding now adapts public results | `test_mrlfe_no_legacy_routes`, public/core/GUI migration suites |
| `solveMRLFEAtlasUnified` | `computeMRLFE`, deleted fitting oracle, obsolete tests, historical audits | Legacy unified atlas route | Deleted | `mrlfeSolve -> mrlfeSolveBranch` | cleanup and production-core characterization tests |
| `solveMRLFEViscoBranchAtlas` | `solveMRLFEAtlasUnified`, obsolete direct-visco diagnostics/tests | Legacy viscous atlas branch route | Deleted | `mrlfeSolveViscoelasticBranch -> mrlfeTrackBranchAdaptive` | cleanup and public solver tests |
| `solveMRLFEBranchModalAtlas` | `solveMRLFEAtlasUnified`, obsolete modal atlas tests | Legacy modal atlas branch route | Deleted | `mrlfeSolveElasticBranch` and neutral tracker | cleanup and public solver tests |
| `solveMRLFEBranchDP` | `computeMRLFE`, `solveMRLFEViscoBranchAtlas` | Legacy DP branch tracker | Deleted | `mrlfeTrackBranchAdaptive` | neutral helper tests and cleanup tests |
| `mrlfeEvaluateAtlasFitModel` | characterization tests, docs, historical audits | Transitional FitTool oracle | Deleted | `mrlfeEvaluateFitModel -> mrlfeSolve`; direct comparisons against `mrlfeSolve` | FitTool public solver tests |
| `mrlfeMakeDirectViscoAtlasBranchOptions` | obsolete direct-visco diagnostics/tests | Legacy direct-visco option mapper | Deleted | public request mappers | cleanup tests |
| `mrlfeApplyDelayedViscoModalCut` | obsolete delayed-cut tests/diagnostics | Legacy delayed-cut helper | Deleted | `mrlfeApplyTerminationPolicy -> mrlfeEvaluatePhysicalTail` | neutral helper and cleanup tests |
| `mrlfeUseAtlasFitRoute` | FitTool tests/options before cleanup | Legacy fitting route selector | Removed from maintained control flow | single `mrlfeSolve` production path | no-legacy-route-flags test |
| `mrlfeUseLegacyFitRoute` | historical option searches only | Legacy opt-out selector | Removed | none | static grep |
| `mrlfeUseDirectViscoAtlas` | obsolete direct-visco tests | Legacy diagnostic selector | Removed with diagnostic route | none | static grep |
| `mrlfeUseUnifiedAtlasRoute` | GUI/Sweep/Fit setup before cleanup | Legacy atlas route selector | Removed from maintained control flow | branch/etaS are mapped by public request | no-legacy-route-flags test |
| `mrlfeGuiActualRoute`, `mrlfeGuiAtlasPreset`, `mrlfeZeroViscosityAdaptiveFallback` | old GUI diagnostics | Legacy GUI metadata | Removed from maintained metadata | `execution.internalEngine`, `execution.effectivePreset`, `fallback.applied` | GUI public solver tests |
| `fast_fit_atlas`, `viscous_unified_atlas`, `zero_viscosity_adaptive_fallback` | old metadata/docs/tests | Historical route/preset names | Removed from maintained metadata | `fast`, `elastic_adaptive`, `viscoelastic_adaptive` | public/core/cleanup tests |
| `adaptivePhysicalTail`, `delayedCut` | old UI/test policy values | Historical policy labels | Removed from maintained UI/control flow | `physicalTail` | SweepTool/FitTool/Main GUI tests |

Historical audit documents may still mention old route names as pre-migration
evidence. They are not maintained entrypoints or production configuration.

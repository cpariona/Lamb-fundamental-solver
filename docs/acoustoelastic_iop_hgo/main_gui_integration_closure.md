### AE IOP/HGO main GUI integration closure

This document closes the first integration pass between `LambFundamental_GUI` and the Acoustoelastic IOP/HGO solver.

The goal of this phase was not to finalize the solver behavior. The goal was to make the model reachable from the main GUI through the maintained adapter surface and to identify the remaining solver-interface issues clearly.

### Current status

The main GUI now exposes an `AE IOP/HGO` model tab and can dispatch a single-case run through:

```text
LambFundamental_GUI
    -> guiRunAcoustoelasticIOPHGOModel
    -> solveAcoustoelasticIOPHGOBranch
    -> solveAcoustoelasticIOPHGOAtlasBranch
```

The GUI currently treats AE IOP/HGO as an exclusive run mode. When AE is enabled, Rayleigh-Lamb and mRLFE are not computed in the same run.

This is intentional for the initial integration because the AE model uses different physical assumptions, different parameters, and different branch-selection logic.

### Confirmed working pieces

```text
- AE-specific GUI controls exist in the main model-specific panel.
- Shared material/geometric values come from Setup where possible: rho, mu, thickness, fmin, fmax.
- AE-specific fields are kept in the AE tab: IOP, R, k1, k2, rhoF, fluid bulk modulus.
- The main GUI calls the maintained AE adapter, not example scripts.
- Results are stored in LambResults, GuiResults, GuiBranchTables, and AcoustoelasticIOPHGOResults.
- Basic normalized plotting works for the AE branch output.
- A main-adapter smoke test exists: tests/test_gui_acoustoelastic_iop_hgo_main_adapter_smoke.m.
```

### Known non-closure items

The integration is not considered numerically final. The following issues must be resolved before UI optimization or model-comparison features are expanded.

### 1. Branch-selection sensitivity

Observed concern:

```text
The official AE output may depend unexpectedly on the starting frequency or requested frequency vector.
```

Potential symptoms:

```text
- nearly constant branch in some cases;
- branch changes when the frequency range changes;
- atlasA0 may not be initialized from sufficiently low frequency;
- branch identity may differ between official output and diagnostic candidates.
```

Required next work:

```text
- reproduce the suspicious constant-branch case with a small script;
- compare official atlasA0 against raw_branch1, identityA0Diagnostic, and branch_families diagnostics;
- verify whether atlasA0 selection depends on the first requested frequency point;
- decide whether the solver needs an internal low-frequency initialization grid independent of the requested output grid.
```

### 2. Output frequency grid and density

Observed concern:

```text
Robust mode appears to increase solver-search settings but does not necessarily produce a sufficiently dense output curve.
```

Required next work:

```text
- separate output frequency resolution from internal atlas search resolution;
- make the GUI pass an explicit requested output grid or output-resolution policy;
- ensure the solver returns Cp on the requested output grid;
- avoid fixed hidden output point counts unless documented.
```

### 3. Remove raw atlas controls from the GUI

Current transitional controls:

```text
atlas y-points
atlas minima
```

These must be removed from the user-facing GUI. They are solver internals, not model parameters.

Required direction:

```text
- expose model-neutral controls only;
- use the same numerical-control structure across Rayleigh-Lamb, mRLFE, and AE when possible;
- keep solver-specific variables internal and derived from shared presets;
- document any unavoidable divergence explicitly.
```

### 4. Naming cleanup

Current transitional UI wording includes `atlasA0` in visible labels.

This should be revised because `atlasA0` is a solver branch-selection policy, not a physical mode label.

Required direction:

```text
Physical result label: A0-like / acoustoelastic A0-like
Solver strategy label: atlas tracking / branch policy
```

### Boundary for next development stage

Further work should not focus first on UI polish. The next stage should focus on solver-interface correctness:

```text
1. Build a reproducible AE branch-sensitivity diagnostic.
2. Fix or formalize atlasA0 initialization and tracking behavior.
3. Standardize output frequency-grid control.
4. Remove atlas-internal GUI controls.
5. Only then optimize visual layout and model-comparison features.
```

### Recommended validation commands

```matlab
clear functions
rehash toolboxcache
startup
run_all_smoke_tests
LambFundamental_GUI
```

Manual AE check:

```text
Setup:
  rho, mu, thickness, fmin, fmax

AE IOP/HGO:
  enable AE run
  set IOP, R, k1, k2, rhoF, fluid bulk modulus

Advanced:
  compare Fast, Balanced, Robust
```

When reviewing the result, check not only whether the curve exists, but also whether the selected branch is physically plausible and robust to the requested frequency range.

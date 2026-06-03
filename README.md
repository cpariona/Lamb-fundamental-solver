# Lamb Fundamental Solver

MATLAB project for computing and plotting fundamental Lamb-wave phase velocity curves for soft, nearly incompressible materials.

Current scope:

- A0 phase velocity calculation using the antisymmetric Rayleigh-Lamb residual.
- Experimental S0 phase velocity calculation using the symmetric Rayleigh-Lamb residual.
- GUI plotting of Cp versus frequency, angular frequency, wavenumber, or `kThickness`.
- Export of `LambResults`, `A0_table`, and, when available, `S0_table` to the MATLAB workspace.

## Naming convention

This project uses explicit thickness naming to avoid ambiguity with classical Rayleigh-Lamb notation:

- `thickness`: total plate thickness.
- `halfThickness`: `thickness / 2`, used internally by Rayleigh-Lamb equations.
- `kThickness`: dimensionless wavenumber, computed as `k * thickness`.

Public GUI labels, exported tables, and result structures should use `thickness` and `kThickness`, not `h`, `kh`, or `kH`.

## Launching the GUI

From the repository root, run:

```matlab
runApp
```

This calls `startup`, adds the project folders to the MATLAB path, and launches the GUI.

Alternatively:

```matlab
startup
LambFundamental_GUI
```

## Manual validation examples

Run these from the repository root:

```matlab
examples/run_default_A0
examples/run_default_A0_S0
examples/check_default_outputs
```

`check_default_outputs` prints valid point counts, Cp ranges, residuals, and finite `kThickness` counts for the default configuration.

## Current limitations

- S0 is implemented but should be treated as experimental until benchmarked against a trusted reference.
- Group velocity is not implemented yet.
- Modal structure and displacement animations are not implemented yet.
- Higher modes such as A1 and S1 are not implemented yet.

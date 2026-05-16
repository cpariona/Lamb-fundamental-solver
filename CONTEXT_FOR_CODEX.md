# Context for Codex: Fundamental Lamb Wave Solver in MATLAB

## Project objective

Develop a modular MATLAB project to compute and plot the fundamental Lamb wave modes A0 and S0 for soft, nearly incompressible materials.

The first version must focus only on phase velocity Cp.

Do not implement yet:
- group velocity Cg,
- higher modes A1/S1,
- modal structure,
- displacement animations,
- wave fields,
- advanced diagnostics,
- material presets,
- multi-simulation comparison.

## Existing starting point

There is an existing MATLAB GUI file:

GUI_current/LambA0_GUI_current.m

It currently computes only A0 using an antisymmetric Rayleigh-Lamb residual and a continuation-style numerical strategy.

The GUI already has:
- Material tab,
- Geometry / Frequency tab,
- Numerical tab,
- fixed Run / Export section,
- Young/Poisson + fixed CL material model,
- Lamé parameter material model,
- A0 phase velocity plot,
- residual plot,
- export to workspace.

This file should be used as a starting point, but the new architecture must not remain as one large file.

## Important naming convention

Use:

- thickness: total plate thickness.
- halfThickness: thickness / 2, used only inside Rayleigh-Lamb equations.
- kThickness: k * thickness, dimensionless wavenumber based on total thickness.

Do not use these names in public GUI/results/export structures:

- h
- kh
- kH

Rayleigh-Lamb equations internally use halfThickness.

Plots, exported data, and postprocessing use kThickness.

## Material models

The GUI should support two material input models.

### Young/Poisson + fixed CL

Inputs:
- E
- nu
- rho
- CL

Derived:
- mu = E / (2*(1 + nu))
- lambda = E*nu / ((1 + nu)*(1 - 2*nu))
- CT = sqrt(mu/rho)

### Lamé parameters

Inputs:
- lambda
- mu
- rho

Derived:
- E = mu*(3*lambda + 2*mu)/(lambda + mu)
- nu = lambda/(2*(lambda + mu))
- CL = sqrt((lambda + 2*mu)/rho)
- CT = sqrt(mu/rho)

## Required first-version GUI

The simplified GUI should include:

### Material
- material model selector,
- rho,
- E,
- nu,
- fixed CL,
- lambda,
- mu.

### Geometry / Frequency
- thickness [mm],
- f min [Hz],
- f max [Hz],
- number of frequency points,
- frequency spacing: logspace or linspace.

### Modes
- checkbox A0,
- checkbox S0.

### Plot
- x-axis selector:
  - frequency,
  - angularFrequency,
  - wavenumber,
  - kThickness.
- y-axis is Cp only.
- axis limits:
  - auto/manual x,
  - auto/manual y.

### Run / Export
- Compute selected modes.
- Export results.
- Material info.
- Solver status.

## Numerical strategy

Use independent branch tracking.

A0:
- antisymmetric Rayleigh-Lamb residual.
- initialized as a low-velocity/flexural branch.
- continuation in frequency.

S0:
- symmetric Rayleigh-Lamb residual.
- initialized near low-frequency extensional plate velocity.
- continuation in frequency.

Do not use a full multimodal root sweep as the main strategy.

## Required solver architecture

Separate GUI from physical/numerical core.

Suggested folders:

core/
equations/
tracking/
postprocess/
visualization/
app/
io/
examples/

Main solver function:

results = computeFundamentalLambModes(params, options)

Expected results structure:

results.material
results.geometry
results.grid.frequency
results.grid.omega
results.modes.A0
results.modes.S0

Each mode should contain:
- frequency
- omega
- Cp
- k
- kThickness
- residual
- valid

## Python reference repository

Reference only:

https://github.com/franciscorotea/Lamb-Wave-Dispersion

Relevant files:
- lambwaves/lambwaves.py
- lambwaves/utils.py
- lambwaves/plot_utils.py

Use conceptually:
- separation of symmetric and antisymmetric equations,
- common computation of omega, k, p, q,
- residual validation,
- mode-organized results.

Do not port the full Python architecture.
Do not implement higher modes yet.
Do not implement animations yet.

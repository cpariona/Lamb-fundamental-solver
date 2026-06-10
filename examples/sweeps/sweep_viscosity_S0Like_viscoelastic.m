clear; clc; close all;
startup

% Sweep example:
% Effect of shear viscosity etaS on the viscoelastic S0-like mRLFE branch.
%
% This case is complementary to sweep_viscosity_A0Like_viscoelastic.m.
% The Han viscoelastic real-k branch is conservative: curves may terminate
% when no mode-relevant continuous real-k local minimum remains.

params = defaultParams();
params.modelType = "YoungPoissonFixedCL";
params.rho = 1070;
params.E = 475e3;
params.nu = 0.4999;
params.CL = 1500;
params.thickness = 0.5e-3;
params.fmin = 100;
params.fmax = 16000;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

options = defaultOptions("Fast");
options.computeA0 = false;
options.computeS0 = true;
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = false;
options.mrlfeComputeS0Like = true;
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;
options.mrlfeParams.etaS = 0;

sweepSpec = struct();
sweepSpec.parameter = "etaS";
sweepSpec.values = [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50];
sweepSpec.label = "etaS";
sweepSpec.units = "Pa*s";
sweepSpec.displayScale = 1;

sweepResults = runParametricSweep(params, options, sweepSpec);

plotParametricSweepCp(sweepResults, "mRLFEHanViscoRealK", "S0Like", ...
    "Title", "Viscoelastic S0-like Cp sensitivity to etaS");

assignin('base', 'ViscositySweepS0LikeResults', sweepResults);

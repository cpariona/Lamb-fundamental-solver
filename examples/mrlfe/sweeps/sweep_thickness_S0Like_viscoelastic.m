clear; clc; close all;
startup

% Sweep example:
% Effect of layer thickness on the viscoelastic S0-like mRLFE branch.
%
% This sweep complements the A0-like thickness sweep and is useful for
% checking how the higher-speed S0-like branch changes with k*thickness.

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
options.mrlfeParams.etaS = 0.05;  % Pa*s, fixed viscosity for thickness sweep

sweepSpec = struct();
sweepSpec.parameter = "thickness";
sweepSpec.values = [0.3, 0.5, 0.7, 1.0] * 1e-3;
sweepSpec.label = "thickness";
sweepSpec.units = "mm";
sweepSpec.displayScale = 1e-3;

sweepResults = runParametricSweep(params, options, sweepSpec);

plotParametricSweepCp(sweepResults, "mRLFEHanViscoRealK", "S0Like", ...
    "Title", "Viscoelastic S0-like Cp sensitivity to thickness", ...
    "ShowLastValidPoint", true);

sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    "mRLFEHanViscoRealK", "S0Like");

assignin('base', 'ThicknessSweepS0LikeResults', sweepResults);
assignin('base', 'ThicknessSweepS0LikeSummary', sweepSummary);

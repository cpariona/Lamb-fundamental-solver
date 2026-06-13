clear; clc; close all;
startup

% Sweep example:
% Effect of layer thickness on the viscoelastic A0-like mRLFE branch.
%
% This sweep is useful for Lamb-wave/OCE sensitivity analysis because A0-like
% dispersion depends strongly on thickness and k*thickness.

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
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.computeMRLFEHanViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
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

plotParametricSweepCp(sweepResults, "mRLFEHanViscoRealK", "A0Like", ...
    "Title", "Viscoelastic A0-like Cp sensitivity to thickness", ...
    "ShowLastValidPoint", true);

sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    "mRLFEHanViscoRealK", "A0Like");

assignin('base', 'ThicknessSweepA0LikeResults', sweepResults);
assignin('base', 'ThicknessSweepA0LikeSummary', sweepSummary);

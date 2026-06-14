clear; clc; close all;
startup

% Sweep example:
% Effect of shear viscosity etaS on the viscoelastic A0-like mRLFE branch.

params = rlDefaultParams();
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

options = rlDefaultOptions("Fast");
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
options.mrlfeParams.etaS = 0;

sweepSpec = struct();
sweepSpec.parameter = "etaS";
sweepSpec.values = [0, 0.01, 0.05, 0.10, 0.20, 0.30, 0.50];
sweepSpec.label = "etaS";
sweepSpec.units = "Pa*s";
sweepSpec.displayScale = 1;

sweepResults = runParametricSweep(params, options, sweepSpec);

plotParametricSweepCp(sweepResults, "mRLFEHanViscoRealK", "A0Like", ...
    "Title", "Viscoelastic A0-like Cp sensitivity to etaS");

sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    "mRLFEHanViscoRealK", "A0Like");

assignin('base', 'ViscositySweepResults', sweepResults);
assignin('base', 'ViscositySweepSummary', sweepSummary);

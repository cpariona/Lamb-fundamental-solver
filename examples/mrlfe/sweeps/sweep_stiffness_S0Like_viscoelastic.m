clear; clc; close all;
startup

% Sweep example:
% Effect of Young's modulus E on the viscoelastic S0-like mRLFE branch.
%
% etaS is kept fixed so this sweep isolates stiffness sensitivity.
% The Han viscoelastic real-k branch is conservative: curves may terminate
% when no mode-relevant continuous real-k local minimum remains.

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
options.mrlfeParams.etaS = 0.05;  % Pa*s, fixed viscosity for stiffness sweep

sweepSpec = struct();
sweepSpec.parameter = "E";
sweepSpec.values = [50, 100, 300, 500, 1000, 1500] * 1e3;
sweepSpec.label = "E";
sweepSpec.units = "kPa";
sweepSpec.displayScale = 1e3;

sweepResults = runParametricSweep(params, options, sweepSpec);

plotParametricSweepCp(sweepResults, "mRLFEHanViscoRealK", "S0Like", ...
    "Title", "Viscoelastic S0-like Cp sensitivity to stiffness E");

sweepSummary = summarizeParametricSweepBranch(sweepResults, ...
    "mRLFEHanViscoRealK", "S0Like");

assignin('base', 'StiffnessSweepS0LikeResults', sweepResults);
assignin('base', 'StiffnessSweepS0LikeSummary', sweepSummary);

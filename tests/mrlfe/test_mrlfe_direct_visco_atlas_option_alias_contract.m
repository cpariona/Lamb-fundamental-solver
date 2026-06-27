clear; clc;
startup

fprintf('\nRunning direct viscous mRLFE atlas option-alias contract test...\n');
fprintf('----------------------------------------------------------------\n');

branchName = "A0Like";
etaS = 0.12;
frequency_Hz = linspace(1000, 8000, 10).';

params = mrlfeDefaultSweepParams();
params.mu = 75e3;
params.thickness = 0.50e-3;
params.rho = 1070;
params.nu = 0.4999;
params.etaS = etaS;

options = mrlfeDefaultSweepOptions(branchName, 'EtaS', etaS);
options.mrlfeUseDirectViscoAtlas = true;

% Canonical values should take priority over legacy mrlfeViscoAtlas* aliases.
options.mrlfeA0DPCpScanPoints = 321;
options.mrlfeViscoAtlasCpScanPoints = 111;
options.mrlfeA0DPCandidates = 7;
options.mrlfeViscoAtlasCandidates = 3;
options.mrlfeViscoA0ModalCpWindow = [0.25, 3.00];
options.mrlfeViscoAtlasCpWindow = [0.40, 1.20];
options.mrlfeA0DPSeedWeight = 0.10;
options.mrlfeViscoAtlasSeedWeight = 0.90;
options.mrlfeA0DPResidualWeight = 0.45;
options.mrlfeViscoAtlasResidualWeight = 0.05;
options.mrlfeA0DPJumpWeight = 18.0;
options.mrlfeViscoAtlasJumpWeight = 2.0;
options.mrlfeA0DPCurvatureWeight = 12.0;
options.mrlfeViscoAtlasCurvatureWeight = 3.0;
options.mrlfeResidualTolerance = 1e-3;
options.mrlfeViscoAtlasResidualTolerance = 1e-1;

[~, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
summary = rawAtlas.branch.viscoAtlas.options;

assert(rawAtlas.evaluationPath.path == "direct_viscous_atlas", 'Expected direct atlas path.');
assert(summary.cpScanPoints == options.mrlfeA0DPCpScanPoints, 'Canonical cpScanPoints should override legacy alias.');
assert(summary.maxCandidates == options.mrlfeA0DPCandidates, 'Canonical candidate count should override legacy alias.');
assert(abs(summary.cpMinFactor - options.mrlfeViscoA0ModalCpWindow(1)) < eps, 'Canonical modal Cp window lower bound should override legacy alias.');
assert(abs(summary.cpMaxFactor - options.mrlfeViscoA0ModalCpWindow(2)) < eps, 'Canonical modal Cp window upper bound should override legacy alias.');
assert(abs(summary.seedWeight - options.mrlfeA0DPSeedWeight) < eps, 'Canonical seed weight should override legacy alias.');
assert(abs(summary.residualWeight - options.mrlfeA0DPResidualWeight) < eps, 'Canonical residual weight should override legacy alias.');
assert(abs(summary.jumpWeight - options.mrlfeA0DPJumpWeight) < eps, 'Canonical jump weight should override legacy alias.');
assert(abs(summary.curvatureWeight - options.mrlfeA0DPCurvatureWeight) < eps, 'Canonical curvature weight should override legacy alias.');
assert(abs(summary.residualTolerance - options.mrlfeResidualTolerance) < eps, 'Canonical residual tolerance should override legacy alias.');

fprintf('cpScanPoints:      %g\n', summary.cpScanPoints);
fprintf('maxCandidates:     %g\n', summary.maxCandidates);
fprintf('modal Cp window:   [%.6g %.6g]\n', summary.cpMinFactor, summary.cpMaxFactor);
fprintf('seedWeight:        %.6g\n', summary.seedWeight);
fprintf('residualWeight:    %.6g\n', summary.residualWeight);
fprintf('jumpWeight:        %.6g\n', summary.jumpWeight);
fprintf('curvatureWeight:   %.6g\n', summary.curvatureWeight);
fprintf('residualTolerance: %.6g\n', summary.residualTolerance);
fprintf('\nDirect viscous mRLFE atlas option-alias contract test passed.\n');

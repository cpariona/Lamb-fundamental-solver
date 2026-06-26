clear; clc;
startup

fprintf('\nRunning direct viscous mRLFE atlas modal-cut policy test...\n');
fprintf('-------------------------------------------------------------\n');

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
options.mrlfeViscoAtlasCpScanPoints = 900;
options.mrlfeViscoAtlasCandidates = 8;
options.mrlfeViscoAtlasCpWindow = [0.25, 3.00];
options.mrlfeViscoAtlasSeedWeight = 0.10;
options.mrlfeViscoAtlasResidualWeight = 0.45;
options.mrlfeViscoAtlasJumpWeight = 18.0;
options.mrlfeViscoAtlasCurvatureWeight = 12.0;

% Use an intentionally strict residual tolerance to force a deterministic modal
% cut. This verifies the direct atlas honors the maintained
% mrlfeRealKStopAtFirstMissingModalMinimum policy and records the tail cutoff
% through firstMissingModalMinimumIndex/Frequency.
options.mrlfeViscoAtlasResidualTolerance = realmin('double');
options.mrlfeRealKStopAtFirstMissingModalMinimum = true;

[CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
branch = rawAtlas.branch;

assert(rawAtlas.evaluationPath.path == "direct_viscous_atlas", 'Expected the direct viscous atlas evaluation path.');
assert(isfield(branch, 'firstMissingModalMinimumIndex'), 'Direct atlas branch must expose firstMissingModalMinimumIndex.');
assert(isfinite(branch.firstMissingModalMinimumIndex), 'Strict residual policy should trigger a modal cut.');
assert(branch.firstMissingModalMinimumIndex >= 1, 'The modal cut index should be positive for this forced case.');
assert(branch.modalCutReason == "missing_modal_minimum", 'Unexpected modal cut reason.');
assert(any(~isfinite(CpAtlas)), 'Cp should be truncated after the forced modal cut.');
assert(all(~branch.validCp(branch.firstMissingModalMinimumIndex:end)), 'Cp validity must be false after the modal cut.');
assert(branch.viscoAtlas.modalCutPolicy.stopAtFirstMissingModalMinimum == true, ...
    'Modal-cut diagnostics must report the maintained stop-at-first-missing policy.');

fprintf('First missing index: %g\n', branch.firstMissingModalMinimumIndex);
fprintf('First missing frequency: %.6g Hz\n', branch.firstMissingModalMinimumFrequency);
fprintf('Modal cut reason: %s\n', branch.modalCutReason);
fprintf('\nDirect viscous mRLFE atlas modal-cut policy test passed.\n');

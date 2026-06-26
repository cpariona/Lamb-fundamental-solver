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
options.mrlfeViscoAtlasResidualTolerance = 1e-3;

% Use the maintained viscous jump-limit field with an intentionally strict value
% to force a controlled modal cut. This verifies the direct atlas honors the
% existing viscous tracking policy naming rather than introducing a separate
% tail-cut control surface.
options.mrlfeViscoPreviousCpMaxRelativeJump = 1e-6;

[CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
branch = rawAtlas.branch;

assert(rawAtlas.evaluationPath.path == "direct_viscous_atlas", 'Expected the direct viscous atlas evaluation path.');
assert(isfield(branch, 'firstMissingModalMinimumIndex'), 'Direct atlas branch must expose firstMissingModalMinimumIndex.');
assert(isfinite(branch.firstMissingModalMinimumIndex), 'Strict viscous jump policy should trigger a modal cut.');
assert(branch.firstMissingModalMinimumIndex > 1, 'The modal cut should occur after the first point for this baseline case.');
assert(branch.modalCutReason == "cp_jump_exceeds_viscous_limit", 'Unexpected modal cut reason.');
assert(any(~isfinite(CpAtlas)), 'Cp should be truncated after the forced modal cut.');
assert(all(~branch.validCp(branch.firstMissingModalMinimumIndex:end)), 'Cp validity must be false after the modal cut.');
assert(branch.viscoAtlas.modalCutPolicy.previousCpMaxRelativeJump == options.mrlfeViscoPreviousCpMaxRelativeJump, ...
    'Modal-cut diagnostics must report the maintained viscous jump limit.');

fprintf('First missing index: %g\n', branch.firstMissingModalMinimumIndex);
fprintf('First missing frequency: %.6g Hz\n', branch.firstMissingModalMinimumFrequency);
fprintf('Modal cut reason: %s\n', branch.modalCutReason);
fprintf('\nDirect viscous mRLFE atlas modal-cut policy test passed.\n');

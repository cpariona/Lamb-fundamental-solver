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
options.mrlfeA0DPCpScanPoints = 900;
options.mrlfeA0DPCandidates = 8;
options.mrlfeViscoA0ModalCpWindow = [0.25, 3.00];
options.mrlfeA0DPSeedWeight = 0.10;
options.mrlfeA0DPResidualWeight = 0.45;
options.mrlfeA0DPJumpWeight = 18.0;
options.mrlfeA0DPCurvatureWeight = 12.0;

% Force a deterministic modal cut using maintained viscous policy controls. The
% first trigger may be either a missing/weak modal minimum or the maintained
% previous-Cp jump gate, depending on the DP-selected path. The test validates
% controlled tail truncation rather than a single hard-coded reason.
options.mrlfeResidualTolerance = realmin('double');
options.mrlfeViscoPreviousCpMaxRelativeJump = 1e-6;
options.mrlfeRealKStopAtFirstMissingModalMinimum = true;

[CpAtlas, rawAtlas] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, options);
branch = rawAtlas.branch;
acceptedReasons = ["missing_modal_minimum", "cp_jump_exceeds_viscous_limit"];

assert(rawAtlas.evaluationPath.path == "direct_viscous_atlas", 'Expected the direct viscous atlas evaluation path.');
assert(isfield(branch, 'firstMissingModalMinimumIndex'), 'Direct atlas branch must expose firstMissingModalMinimumIndex.');
assert(isfinite(branch.firstMissingModalMinimumIndex), 'Forced viscous policy should trigger a modal cut.');
assert(branch.firstMissingModalMinimumIndex >= 1, 'The modal cut index should be positive for this forced case.');
assert(any(branch.modalCutReason == acceptedReasons), 'Unexpected modal cut reason.');
assert(any(~isfinite(CpAtlas)), 'Cp should be truncated after the forced modal cut.');
assert(all(~branch.validCp(branch.firstMissingModalMinimumIndex:end)), 'Cp validity must be false after the modal cut.');
assert(branch.viscoAtlas.modalCutPolicy.stopAtFirstMissingModalMinimum == true, ...
    'Modal-cut diagnostics must report the maintained stop-at-first-missing policy.');
assert(branch.viscoAtlas.modalCutPolicy.previousCpMaxRelativeJump == options.mrlfeViscoPreviousCpMaxRelativeJump, ...
    'Modal-cut diagnostics must report the maintained viscous Cp jump limit.');

fprintf('First missing index: %g\n', branch.firstMissingModalMinimumIndex);
fprintf('First missing frequency: %.6g Hz\n', branch.firstMissingModalMinimumFrequency);
fprintf('Modal cut reason: %s\n', branch.modalCutReason);
fprintf('\nDirect viscous mRLFE atlas modal-cut policy test passed.\n');

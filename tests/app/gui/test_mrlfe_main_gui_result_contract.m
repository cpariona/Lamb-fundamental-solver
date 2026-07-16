clear; clc;
startup

fprintf('\nRunning mRLFE Main GUI result contract test...\n');
fprintf('----------------------------------------------\n');

params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 12000;
params.numFrequencyPoints = 20;
params.frequencySpacing = "linspace";
params.mu = 75e3;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;

options = rlDefaultOptions("Balanced");
options.executionProfile = "Balanced";
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeA0Policy = "physicalTail";
options.mrlfeParams = mrlfeDefaultInternalParameters();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

out = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', false));

assert(isfield(out, 'branches') && numel(out.branches) == 1, ...
    'Main GUI must expose one visible mRLFE branch for A0Like.');
assert(out.branches(1).modelName == "mRLFERealK", 'Visible model name changed.');
assert(out.branches(1).branchName == "A0Like", 'Visible branch name changed.');
assert(isequal(size(out.branches(1).frequency), size(out.branches(1).phaseVelocity)), ...
    'Plotting frequency and phase velocity sizes must match.');
assert(isfield(out.branches(1).diagnostics, 'validCp'), ...
    'Normalized branch must retain validCp diagnostics for export validity.');

qualityAccepted = logical(out.metadata.modelResult.quality.accepted);
expectedStatus = "partial";
if qualityAccepted
    expectedStatus = "success";
end
assert(out.metadata.status == expectedStatus, ...
    'Main GUI status must remain consistent with public-result quality acceptance.');
assert(out.metadata.executionProfile.qualityAccepted == qualityAccepted, ...
    'Execution-profile quality metadata must match the public model result.');
assert(out.metadata.executionProfile.qualityReason == out.metadata.modelResult.quality.reason, ...
    'Execution-profile quality reason must match the public model result.');
assert(out.metadata.modelResult.fallback.policy == "none" && ...
    out.metadata.modelResult.fallback.applied == false, ...
    'Public result must not apply fallback.');

assert(out.metadata.executionProfile.requestedExecutionProfile == "Balanced", ...
    'Requested execution profile must be preserved.');
assert(out.metadata.executionProfile.effectiveExecutionProfile == "Balanced", ...
    'Balanced must be applied directly as the effective execution profile.');
assert(out.metadata.executionProfile.profileOverrideApplied == false, ...
    'Direct Balanced support must not report a profile override.');
assert(out.metadata.executionProfile.effectiveNumericalPreset == "balanced", ...
    'Effective public numerical preset must be balanced.');
assert(out.metadata.executionProfile.profileSupportMode == "direct", ...
    'Main GUI must report direct execution-profile support.');

exportPayload = guiBuildMainResultExport(out, struct('modelType', "ShearPoisson", ...
    'rho_kg_m3', params.rho, 'mu_Pa', params.mu, 'nu', params.nu, ...
    'thickness_m', params.thickness, 'etaS_Pa_s', 0, ...
    'fluidDensity_kg_m3', 1000, 'fluidSoundSpeed_m_s', 1500));
assert(numel(exportPayload.curves) == 1, 'Export must include the visible mRLFE curve.');
assert(ismember('Valid', exportPayload.curves(1).data.Properties.VariableNames), ...
    'Export must retain validity column.');

fprintf('mRLFE Main GUI result contract test passed.\n');

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
options.mrlfeParams = defaultMRLFEParams();
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

assert(out.metadata.status == "partial", ...
    'Known low-quality public result should be reported as partial, not replaced.');
assert(out.metadata.modelResult.quality.accepted == false, ...
    'Partial quality state must be preserved.');
assert(out.metadata.modelResult.quality.reason == "large_relative_jump", ...
    'Partial quality reason must be preserved.');
assert(out.metadata.modelResult.fallback.policy == "none" && ...
    out.metadata.modelResult.fallback.applied == false, ...
    'Partial result must not apply fallback.');

assert(out.metadata.executionProfile.requestedExecutionProfile == "Balanced", ...
    'Requested execution profile must be preserved.');
assert(out.metadata.executionProfile.effectiveExecutionProfile == "Fast", ...
    'Effective execution profile must be Fast.');
assert(out.metadata.executionProfile.profileOverrideApplied == true, ...
    'Balanced-to-Fast mapping must be explicit.');
assert(out.metadata.executionProfile.effectiveNumericalPreset == "fast", ...
    'Effective public numerical preset must be fast.');

exportPayload = guiBuildMainResultExport(out, struct('modelType', "ShearPoisson", ...
    'rho_kg_m3', params.rho, 'mu_Pa', params.mu, 'nu', params.nu, ...
    'thickness_m', params.thickness, 'etaS_Pa_s', 0, ...
    'fluidDensity_kg_m3', 1000, 'fluidSoundSpeed_m_s', 1500));
assert(numel(exportPayload.curves) == 1, 'Export must include the visible mRLFE curve.');
assert(ismember('Valid', exportPayload.curves(1).data.Properties.VariableNames), ...
    'Export must retain validity column.');

fprintf('mRLFE Main GUI result contract test passed.\n');

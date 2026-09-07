function test_mrlfe_main_gui_result_contract()
%TEST_MRLFE_MAIN_GUI_RESULT_CONTRACT Validate canonical mRLFE Main GUI output.

fprintf('\nRunning mRLFE Main GUI result contract test...\n');
fprintf('----------------------------------------------\n');

params = lamb.models.rayleigh_lamb.rlDefaultParams();
params.fmin = 1000;
params.fmax = 12000;
params.numFrequencyPoints = 20;
params.frequencySpacing = "linspace";
params.mu = 75e3;
params.thickness = 0.5e-3;
params.rho = 1070;
params.nu = 0.4999;

options = lamb.fitting.mrlfe.mrlfeDefaultFitOptions("A0Like", 'EtaS', 0);
options.executionProfile = "Balanced";
options.effectiveExecutionProfile = "Balanced";
options.robustness = "Balanced";
options.branchNames = "A0Like";
options.mrlfeA0Policy = "physicalTail";
options.mrlfeParams = lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters();
options.mrlfeParams.etaS = 0;
options.mrlfeParams.fluidDensity = 1000;
options.mrlfeParams.fluidSoundSpeed = 1500;

out = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', false));

assert(isfield(out, 'branches') && isscalar(out.branches), ...
    'Main GUI must expose one visible mRLFE branch for A0Like.');
assert(out.branches.modelName == "mRLFERealK", 'Visible model name changed.');
assert(out.branches.branchName == "A0Like", 'Visible branch name changed.');
assert(out.branchName == "A0Like", 'Single-branch normalized view must expose its branch name.');
assert(isequal(out.frequency, out.branches.frequency));
assert(isequal(out.phaseVelocity, out.branches.phaseVelocity));
assert(isequal(size(out.branches.frequency), size(out.branches.phaseVelocity)), ...
    'Plotting frequency and phase velocity sizes must match.');

canonical = out.metadata.modelResult;
assert(isequaln(out.branches.kThickness, ...
    canonical.wavenumber_radpm(:) * canonical.configuration.effective.parameters.thickness_m), ...
    'Dimensionless plotting coordinate must use canonical wavenumber and full thickness.');
for axisName = ["frequency", "angularFrequency", "wavenumber", "kThickness"]
    plotData = guiGetNormalizedBranchPlotData(out.branches, axisName);
    assert(numel(plotData.x) == numel(canonical.frequency_Hz));
    assert(isequal(plotData.validMask, canonical.validMask));
    assert(isequaln(plotData.y, canonical.phaseVelocity_mps));
end
assert(isfield(out.branches.diagnostics, 'valid') && ...
    isequal(out.branches.diagnostics.valid(:), canonical.validMask(:)), ...
    'Presentation validity must be a shallow copy of the canonical validMask.');

qualityAccepted = logical(canonical.quality.accepted);
expectedStatus = "partial";
if qualityAccepted
    expectedStatus = "success";
end
assert(out.metadata.status == expectedStatus, ...
    'Main GUI status must remain consistent with public-result quality acceptance.');
assert(out.metadata.executionProfile.qualityAccepted == qualityAccepted, ...
    'Execution-profile quality metadata must match the public model result.');
assert(out.metadata.executionProfile.qualityReason == canonical.quality.reason, ...
    'Execution-profile quality reason must match the public model result.');
assert(canonical.fallback.policy == "none" && canonical.fallback.applied == false, ...
    'Public result must not apply fallback.');

assert(out.metadata.executionProfile.requestedExecutionProfile == "Balanced");
assert(out.metadata.executionProfile.effectiveExecutionProfile == "Balanced");
assert(out.metadata.executionProfile.profileOverrideApplied == false);
assert(out.metadata.executionProfile.effectiveNumericalPreset == "balanced");
assert(out.metadata.executionProfile.profileSupportMode == "direct");

exportPayload = guiBuildMainResultExport(out, struct('modelType', "ShearPoisson", ...
    'rho_kg_m3', params.rho, 'mu_Pa', params.mu, 'nu', params.nu, ...
    'thickness_m', params.thickness, 'etaS_Pa_s', 0, ...
    'fluidDensity_kg_m3', 1000, 'fluidSoundSpeed_m_s', 1500));
assert(isscalar(exportPayload.curves), 'Export must include the visible mRLFE curve.');
assert(ismember('Valid', exportPayload.curves.data.Properties.VariableNames), ...
    'Export must retain validity column.');

fprintf('mRLFE Main GUI result contract test passed.\n');
end

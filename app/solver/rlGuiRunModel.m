function result = rlGuiRunModel(guiRequest)
%RLGUIRUNMODEL Run the Rayleigh-Lamb model for solver-GUI workflows.
%
% This adapter translates app inputs and metadata without changing the
% numerical solver configuration supplied in guiRequest.options.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(lamb.models.rayleigh_lamb.rlDefaultParams(), ...
    guiGetStructField(guiRequest, 'params', struct()));
options = guiMergeStructs(lamb.models.rayleigh_lamb.rlDefaultOptions(), ...
    guiGetStructField(guiRequest, 'options', struct()));
[profile, profileMetadata] = guiNormalizeExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default");
options.executionProfile = profile;
options.robustness = profile;
profileMetadata.internalSolverPreset = profile;
profileMetadata.internalAtlasPreset = "";
profileMetadata.profileOverrideApplied = false;
profileMetadata.profileOverrideReason = "";
profileMetadata.routePolicy = "direct";
profileMetadata.optimizerProfile = "";
profileMetadata.gridPointsInitial = options.gridPointsInitial;
profileMetadata.gridPointsTracking = options.gridPointsTracking;
profileMetadata.jumpTol = options.jumpTol;
profileMetadata.searchFactors = options.searchFactors;
profileMetadata.supportedExecutionProfiles = guiExecutionProfileValues();
profileMetadata.profileSupportMode = "fully_supported";
profileMetadata.surfaceDefaultExecutionProfile = "Balanced";

elapsedTimer = tic;
modelResult = lamb.models.rayleigh_lamb.rlComputeFundamentalLambModes(params, options);
elapsedSeconds = toc(elapsedTimer);

result = guiBuildModelResultView(modelResult, mfilename);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.executionProfile = profileMetadata;
result.diagnostics.executionProfile = profileMetadata;
end

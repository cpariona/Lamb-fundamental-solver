function result = guiRunRayleighLambModel(guiRequest)
%GUIRUNRAYLEIGHLAMBMODEL Run the Rayleigh-Lamb model for GUI workflows.
%
% result = guiRunRayleighLambModel(guiRequest) converts a GUI request struct
% into Rayleigh-Lamb params/options, calls the maintained rl* API, and returns
% normalized branch results for later plotting/export layers.
%
% Expected optional guiRequest fields:
%   params  - struct overlay for lamb.models.rayleigh_lamb.rlDefaultParams()
%   options - struct overlay for lamb.models.rayleigh_lamb.rlDefaultOptions()
%
% This adapter does not change numerical solver behavior.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(lamb.models.rayleigh_lamb.rlDefaultParams(), guiGetStructField(guiRequest, 'params', struct()));
options = guiMergeStructs(lamb.models.rayleigh_lamb.rlDefaultOptions(), guiGetStructField(guiRequest, 'options', struct()));
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

function result = guiRunAcoustoelasticIOPHGOModel(guiRequest)
%GUIRUNACOUSTOELASTICIOPHGOMODEL Run Acoustoelastic IOP/HGO for GUI usage.
%
% The adapter resolves the surface execution profile, calls the canonical
% model API, and delegates presentation normalization to guiBuildModelResultView.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end
if ~isfield(guiRequest, 'params') || ~isstruct(guiRequest.params)
    error('guiRunAcoustoelasticIOPHGOModel:MissingParams', ...
        'guiRequest.params is required for Acoustoelastic IOP/HGO GUI runs.');
end

params = guiRequest.params;
options = guiMergeStructs(defaultAcoustoelasticIOPHGOOptions(), ...
    guiGetStructField(guiRequest, 'options', struct()));
[options, profileMetadata] = aeResolveExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default", ...
    'Surface', "MainGUI", ...
    'Overrides', options, ...
    'ApplyNumericalPreset', false);

timerStart = tic;
modelResult = solveAcoustoelasticIOPHGOBranch(params, options);
elapsedSeconds = toc(timerStart);

result = guiBuildModelResultView(modelResult, mfilename);
result.metadata.params = params;
result.metadata.options = options;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.executionProfile = profileMetadata;
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.executionProfile = profileMetadata;
result.diagnostics.quality = modelResult.quality;
end

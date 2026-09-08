function result = aeGuiRunModel(guiRequest)
%AEGUIRUNMODEL Run AE IOP/HGO for solver-GUI usage.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end
if ~isfield(guiRequest, 'params') || ~isstruct(guiRequest.params)
    error('aeGuiRunModel:MissingParams', ...
        'guiRequest.params is required for AE IOP/HGO GUI runs.');
end

params = guiRequest.params;
options = guiMergeStructs(lamb.models.acoustoelastic_iop_hgo.aeDefaultOptions(), ...
    guiGetStructField(guiRequest, 'options', struct()));
[options, profileMetadata] = aeResolveExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default", ...
    'Surface', "SolverGUI", ...
    'Overrides', options, ...
    'ApplyNumericalPreset', false);

timerStart = tic;
modelResult = lamb.models.acoustoelastic_iop_hgo.aeSolveBranch(params, options);
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

function result = rlGuiRunModel(guiRequest)
%RLG UIRUNMODEL Run the Rayleigh-Lamb model for solver-GUI workflows.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(lamb.models.rayleigh_lamb.rlDefaultParams(), guiGetStructField(guiRequest, 'params', struct()));
profileInput = guiGetStructField(guiRequest, 'executionProfile', guiGetStructField(guiRequest, 'options', struct()));
[options, profileMetadata] = rlResolveExecutionProfile(profileInput, ...
    'DefaultProfile', "Balanced", ...
    'DefaultSource', "Solver GUI default");
requestedOptions = guiGetStructField(guiRequest, 'options', struct());
requestedOptions = rmExecutionProfileFields(requestedOptions);
options = guiMergeStructs(options, requestedOptions);

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

function options = rmExecutionProfileFields(options)
for name = ["executionProfile", "effectiveExecutionProfile"]
    fieldName = char(name);
    if isfield(options, fieldName)
        options = rmfield(options, fieldName);
    end
end
end

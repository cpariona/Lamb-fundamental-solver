function sweepOutput = guiRunRLSweep(request)
%GUIRUNRLSWEEP Run a Rayleigh-Lamb one-parameter sweep from SweepTool.

params = request.baseParams;
if ~isfield(params, 'numFrequencyPoints') || isempty(params.numFrequencyPoints)
    params.numFrequencyPoints = "auto";
end
if ~isfield(params, 'frequencySpacing') || isempty(params.frequencySpacing)
    params.frequencySpacing = "hybrid";
end

controls = request.controls;
[options, profileMetadata] = rlResolveExecutionProfile(controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "SweepTool default");
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
branchName = string(request.branchName);
options.computeA0 = branchName == "A0";
options.computeS0 = branchName == "S0";
if ~(options.computeA0 || options.computeS0)
    error('Unsupported Rayleigh-Lamb branchName. Use A0 or S0.');
end

sweepSpec = struct();
sweepSpec.parameter = string(request.sweepField);
sweepSpec.values = request.sweepValuesDisplay .* request.displayScale;
sweepSpec.label = string(request.sweepLabel);
sweepSpec.units = string(request.displayUnit);
sweepSpec.displayScale = request.displayScale;

modelName = "RayleighLamb";
rawResults = runParametricSweep(params, options, sweepSpec);
summaryTable = summarizeParametricSweepBranch(rawResults, modelName, branchName, 'Print', false);
normalized = guiNormalizeRLSweep(rawResults, summaryTable, request, modelName, branchName);
normalized.metadata.executionProfile = profileMetadata;
normalized.metadata.elapsedSeconds = sum(rawResults.elapsedSeconds, 'omitnan');

sweepOutput = struct();
sweepOutput.request = request;
sweepOutput.request.controls = controls;
sweepOutput.modelFamily = "rayleigh_lamb";
sweepOutput.modelName = modelName;
sweepOutput.branchName = branchName;
sweepOutput.sweepSpec = sweepSpec;
sweepOutput.rawResults = rawResults;
sweepOutput.summaryTable = summaryTable;
sweepOutput.normalized = normalized;
sweepOutput.executionProfile = profileMetadata;
sweepOutput.elapsedSeconds = normalized.metadata.elapsedSeconds;
end

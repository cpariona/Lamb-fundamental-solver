function sweepOutput = guiRunMRLFESweep(request)
%GUIRUNMRLFESWEEP Run an mRLFE one-parameter sweep from a GUI request.
%
% The adapter owns mRLFE-specific options, solver calls, and summary generation.
% It routes each sweep point through guiRunMRLFEModel so SweepTool follows the
% same GUI route policy as the main GUI.

params = request.baseParams;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

controls = request.controls;
[baseOptions, profileMetadata] = mrlfeResolveExecutionProfile(string(request.branchName), controls, ...
    'Surface', "sweep", ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "SweepTool default", ...
    'EtaS', getControlValue(controls, 'etaS', 0.05), ...
    'UseUnifiedAtlasRoute', logical(getControlValue(controls, 'mrlfeUseUnifiedAtlasRoute', true)), ...
    'A0Policy', string(getControlValue(controls, 'mrlfeA0Policy', "adaptivePhysicalTail")));
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
baseOptions.computeMRLFEComplexK = false;
baseOptions.mrlfeUseUnifiedAtlasRoute = logical(getControlValue(controls, 'mrlfeUseUnifiedAtlasRoute', true));
baseOptions.mrlfeA0Policy = string(getControlValue(controls, 'mrlfeA0Policy', "adaptivePhysicalTail"));
baseOptions.mrlfeParams = defaultMRLFEParams();
baseOptions.mrlfeParams.fluidDensity = getControlValue(controls, 'fluidDensity', 1000);
baseOptions.mrlfeParams.fluidSoundSpeed = getControlValue(controls, 'fluidSoundSpeed', 1500);
baseOptions.mrlfeParams.etaS = getControlValue(controls, 'etaS', 0.05);
baseOptions.mrlfeParams.etaL = 0;
baseOptions.mrlfeParams.useComplexLambda = false;

branchName = string(request.branchName);
baseOptions.computeA0 = branchName == "A0Like";
baseOptions.computeS0 = branchName == "S0Like";
baseOptions.mrlfeComputeA0Like = branchName == "A0Like";
baseOptions.mrlfeComputeS0Like = branchName == "S0Like";
baseOptions.computeMRLFERealK = true;
baseOptions.computeMRLFEElasticRealK = false;
baseOptions.computeMRLFEViscoRealK = false;

modelName = "mRLFERealK";
summaryModelName = "mRLFERealK";
[valuesSolver, displayScale, units] = convertRequestDisplayValues(request);

sweepSpec = struct();
sweepSpec.parameter = string(request.sweepField);
sweepSpec.values = valuesSolver;
sweepSpec.label = string(request.sweepLabel);
sweepSpec.units = units;
sweepSpec.displayScale = displayScale;

rawResults = runMRLFEGuiAdapterSweep(params, baseOptions, sweepSpec);
summaryTable = summarizeParametricSweepBranch(rawResults, summaryModelName, branchName, 'Print', false);
normalized = guiNormalizeMRLFESweep(rawResults, summaryTable, request, modelName, branchName);
profileMetadata.internalAtlasPreset = inferSweepAtlasPreset(rawResults, profileMetadata.internalAtlasPreset);
profileMetadata.actualRoute = inferSweepActualRoute(rawResults, "");
profileMetadata.fallback = inferSweepFallback(rawResults, false);
normalized.metadata.executionProfile = profileMetadata;
normalized.metadata.elapsedSeconds = sum(rawResults.elapsedSeconds, 'omitnan');

sweepOutput = struct();
sweepOutput.request = request;
sweepOutput.request.controls = controls;
sweepOutput.modelFamily = "mrlfe";
sweepOutput.modelName = modelName;
sweepOutput.branchName = branchName;
sweepOutput.sweepSpec = sweepSpec;
sweepOutput.rawResults = rawResults;
sweepOutput.summaryTable = summaryTable;
sweepOutput.normalized = normalized;
sweepOutput.atlasPolicy = struct('mrlfeUseUnifiedAtlasRoute', baseOptions.mrlfeUseUnifiedAtlasRoute, ...
    'mrlfeA0Policy', baseOptions.mrlfeA0Policy, ...
    'guiRoutePolicy', "guiRunMRLFEModel");
sweepOutput.executionProfile = profileMetadata;
sweepOutput.elapsedSeconds = normalized.metadata.elapsedSeconds;
end

function sweepResults = runMRLFEGuiAdapterSweep(baseParams, baseOptions, sweepSpec)
paramName = char(sweepSpec.parameter);
values = sweepSpec.values(:).';
n = numel(values);

sweepResults = struct();
sweepResults.spec = sweepSpec;
sweepResults.parameter = string(paramName);
sweepResults.values = values;
sweepResults.displayValues = values ./ sweepSpec.displayScale;
sweepResults.results = cell(1, n);
sweepResults.params = cell(1, n);
sweepResults.options = cell(1, n);
sweepResults.elapsedSeconds = nan(1, n);
sweepResults.guiResults = cell(1, n);

for i = 1:n
    params = baseParams;
    options = baseOptions;
    [params, options] = setSweepValue(params, options, paramName, values(i));

    guiRequest = struct();
    guiRequest.params = params;
    guiRequest.options = options;
    guiRequest.mrlfeParams = options.mrlfeParams;
    guiRequest.computeElastic = true;
    guiRequest.computeVisco = options.mrlfeParams.etaS > 0;

    t = tic;
    guiResult = guiRunMRLFEModel(guiRequest);
    elapsed = toc(t);

    sweepResults.results{i} = guiResult.metadata.rawResult;
    sweepResults.params{i} = params;
    sweepResults.options{i} = options;
    sweepResults.elapsedSeconds(i) = elapsed;
    sweepResults.guiResults{i} = guiResult;

    fprintf('Sweep %s = %.6g complete in %.2f s (%d/%d).\n', ...
        paramName, values(i), sweepResults.elapsedSeconds(i), i, n);
end
end

function [params, options] = setSweepValue(params, options, paramName, value)
if isfield(params, paramName)
    params.(paramName) = value;
    return;
end
if ~isfield(options, 'mrlfeParams') || isempty(options.mrlfeParams)
    options.mrlfeParams = defaultMRLFEParams();
end
if isfield(options.mrlfeParams, paramName)
    options.mrlfeParams.(paramName) = value;
    options.mrlfeUseUnifiedAtlasRoute = options.mrlfeParams.etaS > 0;
    return;
end
error('Sweep parameter "%s" was not found in params or options.mrlfeParams.', paramName);
end

function value = getControlValue(controls, fieldName, defaultValue)
if isstruct(controls) && isfield(controls, fieldName) && ~isempty(controls.(fieldName))
    value = controls.(fieldName);
else
    value = defaultValue;
end
end

function [valuesSolver, displayScale, units] = convertRequestDisplayValues(request)
displayScale = getRequestField(request, 'displayScale', 1);
units = string(getRequestField(request, 'displayUnit', ""));
valuesSolver = request.sweepValuesDisplay .* displayScale;
end

function value = getRequestField(request, fieldName, defaultValue)
if isstruct(request) && isfield(request, fieldName) && ~isempty(request.(fieldName))
    value = request.(fieldName);
else
    value = defaultValue;
end
end

function preset = inferSweepAtlasPreset(rawResults, defaultPreset)
preset = string(defaultPreset);
if ~isfield(rawResults, 'guiResults') || isempty(rawResults.guiResults)
    return;
end
for i = 1:numel(rawResults.guiResults)
    guiResult = rawResults.guiResults{i};
    if isstruct(guiResult) && isfield(guiResult, 'metadata') && ...
            isfield(guiResult.metadata, 'mrlfeGuiAtlasPreset')
        preset = string(guiResult.metadata.mrlfeGuiAtlasPreset);
        return;
    end
end
end

function route = inferSweepActualRoute(rawResults, defaultRoute)
route = string(defaultRoute);
if ~isfield(rawResults, 'guiResults') || isempty(rawResults.guiResults)
    return;
end
for i = 1:numel(rawResults.guiResults)
    guiResult = rawResults.guiResults{i};
    if isstruct(guiResult) && isfield(guiResult, 'metadata') && ...
            isfield(guiResult.metadata, 'mrlfeGuiActualRoute')
        route = string(guiResult.metadata.mrlfeGuiActualRoute);
        return;
    end
end
end

function fallback = inferSweepFallback(rawResults, defaultFallback)
fallback = logical(defaultFallback);
if ~isfield(rawResults, 'guiResults') || isempty(rawResults.guiResults)
    return;
end
for i = 1:numel(rawResults.guiResults)
    guiResult = rawResults.guiResults{i};
    if isstruct(guiResult) && isfield(guiResult, 'metadata') && ...
            isfield(guiResult.metadata, 'mrlfeZeroViscosityAdaptiveFallback')
        fallback = logical(guiResult.metadata.mrlfeZeroViscosityAdaptiveFallback);
        return;
    end
end
end

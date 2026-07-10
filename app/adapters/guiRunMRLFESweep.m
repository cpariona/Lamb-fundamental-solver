function sweepOutput = guiRunMRLFESweep(request)
%GUIRUNMRLFESWEEP Run an mRLFE one-parameter sweep from a GUI request.
%
% The adapter owns mRLFE-specific sweep mapping, public solver calls, and
% summary generation. Each sweep point is evaluated through mrlfeSolve.

params = request.baseParams;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";

controls = request.controls;
[baseOptions, profileMetadata] = mrlfeResolveExecutionProfile(string(request.branchName), controls, ...
    'Surface', "sweep", ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "SweepTool default", ...
    'EtaS', getControlValue(controls, 'etaS', 0.05), ...
    'A0Policy', string(getControlValue(controls, 'mrlfeA0Policy', "physicalTail")));
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
baseOptions.mrlfeA0Policy = string(getControlValue(controls, 'mrlfeA0Policy', "physicalTail"));
baseOptions.mrlfeParams = defaultMRLFEParams();
baseOptions.mrlfeParams.fluidDensity = getControlValue(controls, 'fluidDensity', 1000);
baseOptions.mrlfeParams.fluidSoundSpeed = getControlValue(controls, 'fluidSoundSpeed', 1500);
baseOptions.mrlfeParams.etaS = getControlValue(controls, 'etaS', 0.05);
baseOptions.mrlfeParams.etaL = 0;
baseOptions.mrlfeParams.useComplexLambda = false;

branchName = string(request.branchName);

modelName = "mRLFERealK";
summaryModelName = "mRLFERealK";
[valuesSolver, displayScale, units] = convertRequestDisplayValues(request);

sweepSpec = struct();
sweepSpec.parameter = string(request.sweepField);
sweepSpec.values = valuesSolver;
sweepSpec.label = string(request.sweepLabel);
sweepSpec.units = units;
sweepSpec.displayScale = displayScale;

rawResults = runMRLFEGuiAdapterSweep(params, baseOptions, sweepSpec, branchName);
summaryTable = summarizeParametricSweepBranch(rawResults, summaryModelName, branchName, 'Print', false);
normalized = guiNormalizeMRLFESweep(rawResults, summaryTable, request, modelName, branchName);
aggregateMetadata = aggregateSweepMetadata(rawResults, profileMetadata);
profileMetadata.internalAtlasPreset = "fast";
profileMetadata.actualRoute = "mrlfeSolve";
profileMetadata.fallback = aggregateMetadata.anyFallbackApplied;
profileMetadata.effectiveNumericalPreset = "fast";
profileMetadata.effectiveNumericalPresets = aggregateMetadata.effectiveNumericalPresets;
profileMetadata.internalEngines = aggregateMetadata.internalEngines;
profileMetadata.terminationPolicies = aggregateMetadata.terminationPolicies;
profileMetadata.fallbackPolicies = aggregateMetadata.fallbackPolicies;
profileMetadata.anyFallbackApplied = aggregateMetadata.anyFallbackApplied;
profileMetadata.pointCount = aggregateMetadata.pointCount;
profileMetadata.failedPointCount = aggregateMetadata.failedPointCount;
profileMetadata.validPointCount = aggregateMetadata.validPointCount;
profileMetadata.requestedA0Policy = string(getControlValue(controls, 'mrlfeA0Policy', "physicalTail"));
profileMetadata.effectiveA0Policy = "physicalTail";
normalized.metadata.executionProfile = profileMetadata;
normalized.metadata.sweep = aggregateMetadata;
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
sweepOutput.atlasPolicy = struct( ...
    'mrlfeA0Policy', baseOptions.mrlfeA0Policy, ...
    'effectiveA0Policy', "physicalTail", ...
    'guiRoutePolicy', "mrlfeSolve");
sweepOutput.executionProfile = profileMetadata;
sweepOutput.metadata = aggregateMetadata;
sweepOutput.elapsedSeconds = normalized.metadata.elapsedSeconds;
end

function sweepResults = runMRLFEGuiAdapterSweep(baseParams, baseOptions, sweepSpec, branchName)
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
sweepResults.points = cell(1, n);
sweepResults.requests = cell(1, n);

for i = 1:n
    params = baseParams;
    options = baseOptions;
    [params, options] = setSweepValue(params, options, paramName, values(i));

    t = tic;
    point = initializePoint(sweepSpec, i);
    try
        frequency_Hz = rlBuildFrequencyVector(params).';
        pointRequest = mrlfeBuildSweepSolveRequest(params, ...
            struct('parameterName', sweepSpec.parameter, 'parameterValue', values(i)), ...
            frequency_Hz, branchName, options);
        modelResult = mrlfeSolve(pointRequest);
        elapsed = toc(t);
        point = completePoint(point, modelResult);
        sweepResults.results{i} = adaptPublicResultForSweepRaw(modelResult);
        sweepResults.requests{i} = pointRequest;
    catch ME
        elapsed = toc(t);
        point.status = "failed";
        point.errorIdentifier = string(ME.identifier);
        point.errorMessage = string(ME.message);
        sweepResults.results{i} = struct();
        sweepResults.requests{i} = [];
    end
    sweepResults.params{i} = params;
    sweepResults.options{i} = options;
    sweepResults.elapsedSeconds(i) = elapsed;
    point.elapsedSeconds = elapsed;
    sweepResults.points{i} = point;

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
    return;
end
error('Sweep parameter "%s" was not found in params or options.mrlfeParams.', paramName);
end

function point = initializePoint(sweepSpec, idx)
point = struct();
point.parameterName = string(sweepSpec.parameter);
point.parameterValue = sweepSpec.values(idx);
point.parameterValueDisplay = sweepSpec.values(idx) ./ sweepSpec.displayScale;
point.parameterUnits = string(sweepSpec.units);
point.modelResult = [];
point.frequency_Hz = [];
point.phaseVelocity_mps = [];
point.validMask = [];
point.quality = struct();
point.termination = struct();
point.fallback = struct();
point.execution = struct();
point.configuration = struct();
point.status = "notRun";
point.errorIdentifier = "";
point.errorMessage = "";
point.elapsedSeconds = nan;
end

function point = completePoint(point, modelResult)
point.modelResult = modelResult;
point.frequency_Hz = modelResult.frequency_Hz(:);
point.phaseVelocity_mps = modelResult.phaseVelocity_mps(:);
point.validMask = modelResult.validMask(:);
point.quality = modelResult.quality;
point.termination = modelResult.termination;
point.fallback = modelResult.fallback;
point.execution = modelResult.execution;
point.configuration = modelResult.configuration;
point.status = "ok";
end

function rawResult = adaptPublicResultForSweepRaw(modelResult)
internal = modelResult.diagnostics.rawInternalResult;
rawResult = internal.rawFullResult;
rawResult.publicModelResult = modelResult;
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

function metadata = aggregateSweepMetadata(rawResults, profileMetadata)
points = rawResults.points;
n = numel(points);
engines = strings(1, 0);
presets = strings(1, 0);
terminationPolicies = strings(1, 0);
fallbackPolicies = strings(1, 0);
fallbackApplied = false(1, n);
validPointCount = 0;
failedPointCount = 0;

for i = 1:n
    point = points{i};
    if ~isstruct(point) || ~isfield(point, 'status') || point.status ~= "ok"
        failedPointCount = failedPointCount + 1;
        continue;
    end
    engines(end+1) = string(point.execution.internalEngine); %#ok<AGROW>
    presets(end+1) = string(point.execution.effectivePreset); %#ok<AGROW>
    terminationPolicies(end+1) = string(point.termination.policy); %#ok<AGROW>
    fallbackPolicies(end+1) = string(point.fallback.policy); %#ok<AGROW>
    fallbackApplied(i) = logical(point.fallback.applied);
    validPointCount = validPointCount + double(any(point.validMask(:)));
end

metadata = struct();
metadata.requestedExecutionProfile = profileMetadata.requestedExecutionProfile;
metadata.effectiveExecutionProfile = profileMetadata.effectiveExecutionProfile;
metadata.effectiveNumericalPresets = unique(presets, 'stable');
metadata.internalEngines = unique(engines, 'stable');
metadata.terminationPolicies = unique(terminationPolicies, 'stable');
metadata.fallbackPolicies = unique(fallbackPolicies, 'stable');
metadata.anyFallbackApplied = any(fallbackApplied);
metadata.pointCount = n;
metadata.failedPointCount = failedPointCount;
metadata.validPointCount = validPointCount;
end

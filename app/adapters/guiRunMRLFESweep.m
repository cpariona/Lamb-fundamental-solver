function sweepOutput = guiRunMRLFESweep(request)
%GUIRUNMRLFESWEEP Run an mRLFE one-parameter sweep through mrlfeSolve.

params = request.baseParams;
params.numFrequencyPoints = "auto";
params.frequencySpacing = "hybrid";
controls = request.controls;
[baseOptions, profileMetadata] = mrlfeResolveExecutionProfile(string(request.branchName), controls, ...
    'Surface', "sweep", 'DefaultProfile', "Fast", ...
    'DefaultSource', "SweepTool default", ...
    'EtaS', controlValue(controls, 'etaS', 0.05), ...
    'A0Policy', string(controlValue(controls, 'mrlfeA0Policy', "physicalTail")));
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
baseOptions.mrlfeParams.fluidDensity = controlValue(controls, 'fluidDensity', 1000);
baseOptions.mrlfeParams.fluidSoundSpeed = controlValue(controls, 'fluidSoundSpeed', 1500);
baseOptions.mrlfeParams.etaS = controlValue(controls, 'etaS', 0.05);

branchName = string(request.branchName);
[values, displayScale, units] = displayValues(request);
sweepSpec = struct('parameter', string(request.sweepField), ...
    'values', values, 'label', string(request.sweepLabel), ...
    'units', units, 'displayScale', displayScale);

rawResults = executeSweep(params, baseOptions, sweepSpec, branchName);
summaryTable = summarizeParametricSweepBranch(rawResults, "mRLFERealK", branchName, 'Print', false);
normalized = guiNormalizeMRLFESweep(rawResults, summaryTable, request, "mRLFERealK", branchName);
aggregateMetadata = buildSweepMetadata(rawResults, profileMetadata);
profileMetadata = guiMergeStructs(profileMetadata, aggregateMetadata);
profileMetadata.requestedA0Policy = string(controlValue(controls, 'mrlfeA0Policy', "physicalTail"));
normalized.metadata.executionProfile = profileMetadata;
normalized.metadata.sweep = aggregateMetadata;
normalized.metadata.elapsedSeconds = sum(rawResults.elapsedSeconds, 'omitnan');

sweepOutput = struct( ...
    'request', request, 'modelFamily', "mrlfe", 'modelName', "mRLFERealK", ...
    'branchName', branchName, 'sweepSpec', sweepSpec, 'rawResults', rawResults, ...
    'summaryTable', summaryTable, 'normalized', normalized, ...
    'atlasPolicy', struct('mrlfeA0Policy', baseOptions.mrlfeA0Policy, ...
        'effectiveA0Policy', "physicalTail", 'guiRoutePolicy', "mrlfeSolve"), ...
    'executionProfile', profileMetadata, 'metadata', aggregateMetadata, ...
    'elapsedSeconds', normalized.metadata.elapsedSeconds);
sweepOutput.request.controls = controls;
end

function sweep = executeSweep(baseParams, baseOptions, spec, branchName)
parameter = char(spec.parameter);
values = spec.values(:).';
n = numel(values);
sweep = struct('spec', spec, 'parameter', string(parameter), 'values', values, ...
    'displayValues', values ./ spec.displayScale, 'results', {cell(1, n)}, ...
    'params', {cell(1, n)}, 'options', {cell(1, n)}, ...
    'elapsedSeconds', nan(1, n), 'points', {cell(1, n)}, 'requests', {cell(1, n)});

for i = 1:n
    params = baseParams;
    options = baseOptions;
    [params, options] = setSweepValue(params, options, parameter, values(i));
    point = newPoint(spec, i);
    timerStart = tic;
    try
        frequency_Hz = rlBuildFrequencyVector(params).';
        solveRequest = mrlfeBuildSweepSolveRequest(params, ...
            struct('parameterName', spec.parameter, 'parameterValue', values(i)), ...
            frequency_Hz, branchName, options);
        modelResult = mrlfeSolve(solveRequest);
        point = completePoint(point, modelResult);
        sweep.results{i} = guiBuildMRLFECompatibilityResult(modelResult);
        sweep.requests{i} = solveRequest;
    catch err
        point.status = "failed";
        point.errorIdentifier = string(err.identifier);
        point.errorMessage = string(err.message);
        sweep.results{i} = struct();
        sweep.requests{i} = [];
    end
    elapsed = toc(timerStart);
    point.elapsedSeconds = elapsed;
    sweep.params{i} = params;
    sweep.options{i} = options;
    sweep.elapsedSeconds(i) = elapsed;
    sweep.points{i} = point;
    fprintf('Sweep %s = %.6g complete in %.2f s (%d/%d).\n', parameter, values(i), elapsed, i, n);
end
end

function [params, options] = setSweepValue(params, options, parameter, value)
if isfield(params, parameter)
    params.(parameter) = value;
elseif isfield(options.mrlfeParams, parameter)
    options.mrlfeParams.(parameter) = value;
else
    error('Sweep parameter "%s" was not found in params or options.mrlfeParams.', parameter);
end
end

function point = newPoint(spec, idx)
point = struct( ...
    'parameterName', string(spec.parameter), 'parameterValue', spec.values(idx), ...
    'parameterValueDisplay', spec.values(idx) ./ spec.displayScale, ...
    'parameterUnits', string(spec.units), 'modelResult', [], ...
    'frequency_Hz', [], 'phaseVelocity_mps', [], 'validMask', [], ...
    'quality', struct(), 'termination', struct(), 'fallback', struct(), ...
    'execution', struct(), 'configuration', struct(), 'status', "notRun", ...
    'errorIdentifier', "", 'errorMessage', "", 'elapsedSeconds', nan);
end

function point = completePoint(point, result)
point.modelResult = result;
point.frequency_Hz = result.frequency_Hz(:);
point.phaseVelocity_mps = result.phaseVelocity_mps(:);
point.validMask = result.validMask(:);
point.quality = result.quality;
point.termination = result.termination;
point.fallback = result.fallback;
point.execution = result.execution;
point.configuration = result.configuration;
point.status = "ok";
end

function metadata = buildSweepMetadata(rawResults, profileMetadata)
successful = cell(1, 0);
validPointCount = 0;
failedPointCount = 0;
for i = 1:numel(rawResults.points)
    point = rawResults.points{i};
    if point.status == "ok"
        successful{end+1} = point.modelResult; %#ok<AGROW>
        validPointCount = validPointCount + double(any(point.validMask));
    else
        failedPointCount = failedPointCount + 1;
    end
end
metadata = mrlfeBuildSurfaceExecutionMetadata(profileMetadata, successful, ...
    'SurfaceDefault', "Fast", 'RoutePolicy', "mrlfeSolve", 'A0Policy', "physicalTail");
metadata.pointCount = numel(rawResults.points);
metadata.failedPointCount = failedPointCount;
metadata.validPointCount = validPointCount;
end

function value = controlValue(controls, fieldName, defaultValue)
value = defaultValue;
if isstruct(controls) && isfield(controls, fieldName) && ~isempty(controls.(fieldName))
    value = controls.(fieldName);
end
end

function [values, displayScale, units] = displayValues(request)
displayScale = requestValue(request, 'displayScale', 1);
units = string(requestValue(request, 'displayUnit', ""));
values = request.sweepValuesDisplay .* displayScale;
end

function value = requestValue(request, fieldName, defaultValue)
value = defaultValue;
if isstruct(request) && isfield(request, fieldName) && ~isempty(request.(fieldName))
    value = request.(fieldName);
end
end

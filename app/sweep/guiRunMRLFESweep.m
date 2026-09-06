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
    'units', units, 'displayScale', displayScale, ...
    'parameterPath', sweepParameterPath(params, baseOptions, request.sweepField), ...
    'continueOnError', true);

sweepResults = runParametricSweep(params, baseOptions, sweepSpec, ...
    @(pointParams, pointOptions)evaluateMRLFE(pointParams, pointOptions, branchName));
summaryTable = summarizeParametricSweepBranch(sweepResults, "mRLFERealK", branchName, 'Print', false);
normalized = guiNormalizeMRLFESweep(sweepResults, summaryTable, request, "mRLFERealK", branchName);
aggregateMetadata = buildSweepMetadata(sweepResults, profileMetadata);
profileMetadata = guiMergeStructs(profileMetadata, aggregateMetadata);
profileMetadata.requestedA0Policy = string(controlValue(controls, 'mrlfeA0Policy', "physicalTail"));
normalized.metadata.executionProfile = profileMetadata;
normalized.metadata.sweep = aggregateMetadata;
normalized.metadata.elapsedSeconds = sum(sweepResults.elapsedSeconds, 'omitnan');

sweepOutput = struct( ...
    'request', request, 'modelFamily', "mrlfe", 'modelName', "mRLFERealK", ...
    'branchName', branchName, 'sweepSpec', sweepSpec, 'sweepResult', sweepResults, ...
    'summaryTable', summaryTable, 'normalized', normalized, ...
    'atlasPolicy', struct('mrlfeA0Policy', baseOptions.mrlfeA0Policy, ...
        'effectiveA0Policy', "physicalTail", 'guiRoutePolicy', "mrlfeSolve"), ...
    'executionProfile', profileMetadata, 'metadata', aggregateMetadata, ...
    'elapsedSeconds', normalized.metadata.elapsedSeconds);
sweepOutput.request.controls = controls;
end

function path = sweepParameterPath(params, options, parameter)
parameter = char(string(parameter));
if isfield(params, parameter)
    path = "params." + string(parameter);
elseif isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, parameter)
    path = "options.mrlfeParams." + string(parameter);
else
    error('mrlfe:UnsupportedSweepParameter', ...
        'Unsupported mRLFE sweep parameter "%s".', parameter);
end
end

function result = evaluateMRLFE(params, options, branchName)
frequency_Hz = buildFrequencyVector(params).';
request = mrlfeBuildSolveRequest(params, frequency_Hz, branchName, options);
result = mrlfeSolve(request);
end

function metadata = buildSweepMetadata(sweepResults, profileMetadata)
successful = cell(1, 0);
validPointCount = 0;
failedPointCount = 0;
for i = 1:numel(sweepResults.points)
    point = sweepResults.points{i};
    if point.status == "ok"
        successful{end+1} = point.modelResult; %#ok<AGROW>
        validPointCount = validPointCount + double(any(point.modelResult.validMask));
    else
        failedPointCount = failedPointCount + 1;
    end
end
metadata = mrlfeBuildSurfaceExecutionMetadata(profileMetadata, successful, ...
    'SurfaceDefault', "Fast", 'RoutePolicy', "mrlfeSolve", 'A0Policy', "physicalTail");
metadata.pointCount = numel(sweepResults.points);
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

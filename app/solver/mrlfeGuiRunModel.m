function result = mrlfeGuiRunModel(guiRequest)
%MRLFEGUIRUNMODEL Run solver-GUI mRLFE through the public API.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(lamb.models.mrlfe.configuration.mrlfeDefaultWorkflowParams(), ...
    guiGetStructField(guiRequest, 'params', struct()));
options = guiGetStructField(guiRequest, 'options', struct());
[profile, profileMetadata] = guiNormalizeExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default");
options.executionProfile = profile;
options.effectiveExecutionProfile = profile;
options.robustness = profile;
options.mrlfeParams = mrlfeResolveParams(guiRequest, options);
options.mrlfeA0Policy = mrlfeNormalizeA0Policy(guiGetStructField(options, 'mrlfeA0Policy', "physicalTail"));

branchNames = mrlfeSelectedBranches(options);
[resolvedProfileOptions, ~] = mrlfeResolveExecutionProfile(branchNames(1), profile, ...
    'Surface', "solver", ...
    'DefaultProfile', "Balanced", ...
    'DefaultSource', "model default", ...
    'EtaS', options.mrlfeParams.etaS, ...
    'A0Policy', options.mrlfeA0Policy);
options.mrlfeNumericalPreset = resolvedProfileOptions.mrlfeNumericalPreset;
frequency_Hz = lamb.grids.buildFrequencyVector(params);
[modelResults, requests, elapsedSeconds] = mrlfeSolveBranches(params, options, frequency_Hz, branchNames);

result = mrlfeNormalizeModelResults(modelResults);
result.modelResult = modelResults{1};
result.modelResults = mrlfeCellsByBranch(modelResults);
result.requests = mrlfeCellsByBranch(requests);

profileMetadata.effectiveExecutionProfile = profile;
profileMetadata.internalSolverPreset = profile;
profileMetadata = mrlfeBuildSurfaceExecutionMetadata(profileMetadata, modelResults, ...
    'SurfaceDefault', "Balanced", 'RoutePolicy', "lamb.models.mrlfe.mrlfeSolve", ...
    'EtaS', modelResults{1}.configuration.effective.parameters.etaS_Pas, ...
    'A0Policy', "physicalTail");
status = "success";
if ~profileMetadata.qualityAccepted
    status = "partial";
end

result.diagnostics = guiMergeStructs(result.diagnostics, struct( ...
    'branchCount', numel(result.branches), ...
    'elapsedSeconds', elapsedSeconds, ...
    'seedBranchesHiddenFromPlotSurface', true, ...
    'status', status, ...
    'qualityAccepted', profileMetadata.qualityAccepted, ...
    'qualityReason', profileMetadata.qualityReason, ...
    'executionProfile', profileMetadata, ...
    'modelResults', result.modelResults));
result.metadata = struct( ...
    'params', params, 'options', options, ...
    'modelResult', modelResults{1}, 'modelResults', result.modelResults, ...
    'requests', result.requests, 'elapsedSeconds', elapsedSeconds, ...
    'seedBranchesHiddenFromPlotSurface', true, 'status', status, ...
    'quality', mrlfeCollectBranchField(modelResults, 'quality'), ...
    'termination', mrlfeCollectBranchField(modelResults, 'termination'), ...
    'fallback', mrlfeCollectBranchField(modelResults, 'fallback'), ...
    'execution', mrlfeCollectBranchField(modelResults, 'execution'), ...
    'configuration', mrlfeCollectBranchField(modelResults, 'configuration'), ...
    'executionProfile', profileMetadata);
end

function mrlfeParams = mrlfeResolveParams(guiRequest, options)
mrlfeParams = guiGetStructField(options, 'mrlfeParams', lamb.models.mrlfe.configuration.mrlfeDefaultInternalParameters());
if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    mrlfeParams = guiRequest.mrlfeParams;
end
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
end

function [results, requests, elapsedSeconds] = mrlfeSolveBranches(params, options, frequency_Hz, branchNames)
results = cell(1, numel(branchNames));
requests = cell(1, numel(branchNames));
timerStart = tic;
for i = 1:numel(branchNames)
    requests{i} = lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest(params, frequency_Hz, branchNames(i), options);
    results{i} = lamb.models.mrlfe.mrlfeSolve(requests{i});
end
elapsedSeconds = toc(timerStart);
end

function branchNames = mrlfeSelectedBranches(options)
branchNames = string(guiGetStructField(options, 'branchNames', ...
    guiGetStructField(options, 'branchName', "A0Like")));
branchNames = unique(branchNames(:).', 'stable');
if isempty(branchNames)
    error('mrlfe:InvalidGuiBranchSelection', 'Solver GUI mRLFE requires A0Like or S0Like selection.');
end
if any(~ismember(branchNames, ["A0Like", "S0Like"]))
    error('mrlfe:InvalidGuiBranchSelection', 'Solver GUI mRLFE branches must be A0Like or S0Like.');
end
end

function out = mrlfeCellsByBranch(items)
out = struct();
for i = 1:numel(items)
    out.(char(items{i}.branch)) = items{i};
end
end

function out = mrlfeCollectBranchField(results, fieldName)
out = struct();
for i = 1:numel(results)
    out.(char(results{i}.branch)) = results{i}.(fieldName);
end
end

function result = mrlfeNormalizeModelResults(modelResults)
result = guiBuildModelResultView(modelResults{1}, mfilename);
for i = 2:numel(modelResults)
    view = guiBuildModelResultView(modelResults{i}, mfilename);
    result.branches = [result.branches; view.branches]; %#ok<AGROW>
end
result.diagnostics.branchCount = numel(result.branches);
end

function policy = mrlfeNormalizeA0Policy(policy)
policy = string(policy);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
end

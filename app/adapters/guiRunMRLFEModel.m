function result = guiRunMRLFEModel(guiRequest)
%GUIRUNMRLFEMODEL Run Main GUI mRLFE solving through the public API.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(rlDefaultParams(), guiGetStructField(guiRequest, 'params', struct()));
options = guiMergeStructs(rlDefaultOptions(), guiGetStructField(guiRequest, 'options', struct()));
[profile, profileMetadata] = guiNormalizeExecutionProfile(options, ...
    'DefaultProfile', guiGetStructField(options, 'robustness', "Balanced"), ...
    'DefaultSource', "model default");
options.executionProfile = profile;
options.effectiveExecutionProfile = profile;
options.robustness = profile;
options.mrlfeNumericalPreset = profileToNumericalPreset(profile);
options.mrlfeParams = resolveMRLFEParams(guiRequest, options);
options.mrlfeA0Policy = normalizeA0Policy(guiGetStructField(options, 'mrlfeA0Policy', "physicalTail"));

branchNames = selectedBranches(options);
frequency_Hz = rlBuildFrequencyVector(params);
[modelResults, requests, elapsedSeconds] = solveBranches(params, options, frequency_Hz, branchNames);

rawResult = guiBuildMRLFECompatibilityResult(modelResults);
result = guiNormalizeRawResult(rawResult, mfilename);
result.branches = filterMRLFEBranches(result.branches);
result.modelResult = modelResults{1};
result.modelResults = cellsByBranch(modelResults);
result.requests = cellsByBranch(requests);

profileMetadata.effectiveExecutionProfile = profile;
profileMetadata.internalSolverPreset = profile;
profileMetadata = mrlfeBuildSurfaceExecutionMetadata(profileMetadata, modelResults, ...
    'SurfaceDefault', "Balanced", 'RoutePolicy', "mrlfeSolve", ...
    'EtaS', modelResults{1}.configuration.parameters.etaS_Pas, ...
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
    'params', params, 'options', options, 'rawResult', rawResult, ...
    'modelResult', modelResults{1}, 'modelResults', result.modelResults, ...
    'requests', result.requests, 'elapsedSeconds', elapsedSeconds, ...
    'seedBranchesHiddenFromPlotSurface', true, 'status', status, ...
    'quality', collectBranchField(modelResults, 'quality'), ...
    'termination', collectBranchField(modelResults, 'termination'), ...
    'fallback', collectBranchField(modelResults, 'fallback'), ...
    'execution', collectBranchField(modelResults, 'execution'), ...
    'configuration', collectBranchField(modelResults, 'configuration'), ...
    'executionProfile', profileMetadata);
end

function mrlfeParams = resolveMRLFEParams(guiRequest, options)
mrlfeParams = guiGetStructField(options, 'mrlfeParams', defaultMRLFEParams());
if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    mrlfeParams = guiRequest.mrlfeParams;
end
mrlfeParams.solveComplexK = false;
mrlfeParams.etaL = 0;
mrlfeParams.useComplexLambda = false;
end

function [results, requests, elapsedSeconds] = solveBranches(params, options, frequency_Hz, branchNames)
results = cell(1, numel(branchNames));
requests = cell(1, numel(branchNames));
timerStart = tic;
for i = 1:numel(branchNames)
    requests{i} = mrlfeBuildGuiSolveRequest(params, frequency_Hz, branchNames(i), options);
    results{i} = mrlfeSolve(requests{i});
end
elapsedSeconds = toc(timerStart);
end

function branchNames = selectedBranches(options)
computeA0 = logical(guiGetStructField(options, 'mrlfeComputeA0Like', guiGetStructField(options, 'computeA0', true)));
computeS0 = logical(guiGetStructField(options, 'mrlfeComputeS0Like', guiGetStructField(options, 'computeS0', false)));
branchNames = [repmat("A0Like", 1, double(computeA0)), repmat("S0Like", 1, double(computeS0))];
if isempty(branchNames)
    error('mrlfe:InvalidGuiBranchSelection', 'Main GUI mRLFE requires A0Like or S0Like selection.');
end
end

function out = cellsByBranch(items)
out = struct();
for i = 1:numel(items)
    out.(char(items{i}.branch)) = items{i};
end
end

function out = collectBranchField(results, fieldName)
out = struct();
for i = 1:numel(results)
    out.(char(results{i}.branch)) = results{i}.(fieldName);
end
end

function branches = filterMRLFEBranches(branches)
if ~isempty(branches)
    branches = branches(string({branches.modelName}) == "mRLFERealK");
end
end

function policy = normalizeA0Policy(policy)
policy = string(policy);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
end

function preset = profileToNumericalPreset(profile)
profiles = ["Fast", "Balanced", "Robust"];
presets = ["fast", "balanced", "robust"];
idx = find(string(profile) == profiles, 1);
if isempty(idx)
    error('mrlfe:InvalidExecutionProfile', ...
        'Unsupported mRLFE execution profile "%s".', string(profile));
end
preset = presets(idx);
end

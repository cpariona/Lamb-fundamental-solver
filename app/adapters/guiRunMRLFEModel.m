function result = guiRunMRLFEModel(guiRequest)
%GUIRUNMRLFEMODEL Run Main GUI mRLFE solving through the public API.

if nargin < 1 || isempty(guiRequest)
    guiRequest = struct();
end

params = guiMergeStructs(rlDefaultParams(), guiGetStructField(guiRequest, 'params', struct()));
options = guiGetStructField(guiRequest, 'options', struct());
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

result = normalizeModelResults(modelResults);
result.modelResult = modelResults{1};
result.modelResults = cellsByBranch(modelResults);
result.requests = cellsByBranch(requests);

profileMetadata.effectiveExecutionProfile = profile;
profileMetadata.internalSolverPreset = profile;
profileMetadata = mrlfeBuildSurfaceExecutionMetadata(profileMetadata, modelResults, ...
    'SurfaceDefault', "Balanced", 'RoutePolicy', "mrlfeSolve", ...
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
    'quality', collectBranchField(modelResults, 'quality'), ...
    'termination', collectBranchField(modelResults, 'termination'), ...
    'fallback', collectBranchField(modelResults, 'fallback'), ...
    'execution', collectBranchField(modelResults, 'execution'), ...
    'configuration', collectBranchField(modelResults, 'configuration'), ...
    'executionProfile', profileMetadata);
end

function mrlfeParams = resolveMRLFEParams(guiRequest, options)
mrlfeParams = guiGetStructField(options, 'mrlfeParams', mrlfeDefaultInternalParameters());
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
branchNames = string(guiGetStructField(options, 'branchNames', ...
    guiGetStructField(options, 'branchName', "A0Like")));
branchNames = unique(branchNames(:).', 'stable');
if isempty(branchNames)
    error('mrlfe:InvalidGuiBranchSelection', 'Main GUI mRLFE requires A0Like or S0Like selection.');
end
if any(~ismember(branchNames, ["A0Like", "S0Like"]))
    error('mrlfe:InvalidGuiBranchSelection', 'Main GUI mRLFE branches must be A0Like or S0Like.');
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

function result = normalizeModelResults(modelResults)
result = guiBuildModelResultView(modelResults{1}, mfilename);
for i = 2:numel(modelResults)
    view = guiBuildModelResultView(modelResults{i}, mfilename);
    result.branches = [result.branches; view.branches]; %#ok<AGROW>
end
result.diagnostics.branchCount = numel(result.branches);
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

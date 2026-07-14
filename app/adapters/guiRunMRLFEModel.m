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
numericalPreset = profileToNumericalPreset(profile);
options.executionProfile = profile;
options.effectiveExecutionProfile = profile;
options.robustness = profile;
options.mrlfeNumericalPreset = numericalPreset;

if isfield(guiRequest, 'mrlfeParams') && isstruct(guiRequest.mrlfeParams)
    options.mrlfeParams = guiRequest.mrlfeParams;
end
if ~isfield(options, 'mrlfeParams') || isempty(options.mrlfeParams)
    options.mrlfeParams = defaultMRLFEParams();
end
options.mrlfeParams.solveComplexK = false;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
options.mrlfeA0Policy = normalizeA0Policy(guiGetStructField(options, 'mrlfeA0Policy', "physicalTail"));

branchNames = selectedBranches(options);
frequency_Hz = rlBuildFrequencyVector(params);

timerStart = tic;
modelResults = cell(1, numel(branchNames));
requests = cell(1, numel(branchNames));
for i = 1:numel(branchNames)
    requests{i} = mrlfeBuildGuiSolveRequest(params, frequency_Hz, branchNames(i), options);
    requests{i}.numerics.preset = numericalPreset;
    modelResults{i} = mrlfeSolve(requests{i});
end
elapsedSeconds = toc(timerStart);

rawResult = adaptPublicResultsForMainGui(modelResults);
result = guiNormalizeRawResult(rawResult, mfilename);
result.branches = filterMRLFEBranches(result.branches);
result.modelResult = modelResults{1};
result.modelResults = modelResultsByBranch(modelResults);
result.requests = requestsByBranch(requests);

qualityAccepted = all(cellfun(@(r) logical(r.quality.accepted), modelResults));
status = "success";
if ~qualityAccepted
    status = "partial";
end

profileMetadata.effectiveExecutionProfile = profile;
profileMetadata.requestedNumericalPreset = numericalPreset;
profileMetadata.effectiveNumericalPreset = numericalPreset;
profileMetadata.internalSolverPreset = profile;
profileMetadata.internalAtlasPreset = numericalPreset;
profileMetadata.profileOverrideApplied = false;
profileMetadata.profileOverrideReason = "";
profileMetadata.routePolicy = "mrlfeSolve";
profileMetadata.optimizerProfile = "";
profileMetadata.supportedExecutionProfiles = ["Fast", "Balanced", "Robust"];
profileMetadata.profileSupportMode = "direct";
profileMetadata.surfaceDefaultExecutionProfile = "Balanced";
profileMetadata.etaS = modelResults{1}.configuration.parameters.etaS_Pas;
profileMetadata.a0Policy = "physicalTail";
profileMetadata.fallback = false;
profileMetadata.internalEngines = unique(cellfun(@(r) string(r.execution.internalEngine), modelResults), 'stable');
profileMetadata.terminationPolicies = unique(cellfun(@(r) string(r.termination.policy), modelResults), 'stable');
profileMetadata.fallbackPolicies = unique(cellfun(@(r) string(r.fallback.policy), modelResults), 'stable');
profileMetadata.anyFallbackApplied = false;
profileMetadata.qualityAccepted = qualityAccepted;
profileMetadata.qualityReason = strjoin(unique(cellfun(@(r) string(r.quality.reason), modelResults), 'stable'), ", ");

result.diagnostics.branchCount = numel(result.branches);
result.diagnostics.elapsedSeconds = elapsedSeconds;
result.diagnostics.seedBranchesHiddenFromPlotSurface = true;
result.diagnostics.status = status;
result.diagnostics.qualityAccepted = qualityAccepted;
result.diagnostics.qualityReason = profileMetadata.qualityReason;
result.diagnostics.executionProfile = profileMetadata;
result.diagnostics.modelResults = result.modelResults;

result.metadata.params = params;
result.metadata.options = options;
result.metadata.rawResult = rawResult;
result.metadata.modelResult = modelResults{1};
result.metadata.modelResults = result.modelResults;
result.metadata.requests = result.requests;
result.metadata.elapsedSeconds = elapsedSeconds;
result.metadata.seedBranchesHiddenFromPlotSurface = true;
result.metadata.status = status;
result.metadata.quality = collectQuality(modelResults);
result.metadata.termination = collectField(modelResults, 'termination');
result.metadata.fallback = collectField(modelResults, 'fallback');
result.metadata.execution = collectField(modelResults, 'execution');
result.metadata.configuration = collectField(modelResults, 'configuration');
result.metadata.executionProfile = profileMetadata;
end

function branchNames = selectedBranches(options)
computeA0Like = logical(guiGetStructField(options, 'mrlfeComputeA0Like', guiGetStructField(options, 'computeA0', true)));
computeS0Like = logical(guiGetStructField(options, 'mrlfeComputeS0Like', guiGetStructField(options, 'computeS0', false)));

branchNames = strings(1, 0);
if computeA0Like
    branchNames(end+1) = "A0Like"; %#ok<AGROW>
end
if computeS0Like
    branchNames(end+1) = "S0Like"; %#ok<AGROW>
end
if isempty(branchNames)
    error('mrlfe:InvalidGuiBranchSelection', 'Main GUI mRLFE requires A0Like or S0Like selection.');
end
end

function rawResult = adaptPublicResultsForMainGui(modelResults)
rawResult = modelResults{1}.diagnostics.rawInternalResult.rawFullResult;
rawResult.models.mRLFERealK.branches = struct();
rawResult.models.mRLFE.branches = struct();
for i = 1:numel(modelResults)
    modelResult = modelResults{i};
    branchName = char(modelResult.branch);
    branch = modelResult.diagnostics.rawInternalResult.branch;
    rawResult.models.mRLFERealK.branches.(branchName) = branch;
    rawResult.models.mRLFE.branches.(branchName) = branch;
end
rawResult.models.mRLFERealK.publicModelResults = modelResultsByBranch(modelResults);
rawResult.models.mRLFE.publicModelResults = rawResult.models.mRLFERealK.publicModelResults;
end

function out = modelResultsByBranch(modelResults)
out = struct();
for i = 1:numel(modelResults)
    out.(char(modelResults{i}.branch)) = modelResults{i};
end
end

function out = requestsByBranch(requests)
out = struct();
for i = 1:numel(requests)
    out.(char(requests{i}.branch)) = requests{i};
end
end

function out = collectQuality(modelResults)
out = struct();
for i = 1:numel(modelResults)
    out.(char(modelResults{i}.branch)) = modelResults{i}.quality;
end
end

function out = collectField(modelResults, fieldName)
out = struct();
for i = 1:numel(modelResults)
    out.(char(modelResults{i}.branch)) = modelResults{i}.(fieldName);
end
end

function branches = filterMRLFEBranches(branches)
if isempty(branches)
    return;
end
modelNames = string({branches.modelName});
branches = branches(modelNames == "mRLFERealK");
end

function policy = normalizeA0Policy(policyIn)
policy = string(policyIn);
if policy ~= "physicalTail"
    policy = "physicalTail";
end
end

function preset = profileToNumericalPreset(profile)
switch string(profile)
    case "Fast"
        preset = "fast";
    case "Balanced"
        preset = "balanced";
    case "Robust"
        preset = "robust";
    otherwise
        error('mrlfe:InvalidExecutionProfile', ...
            'Unsupported mRLFE execution profile "%s".', string(profile));
end
end
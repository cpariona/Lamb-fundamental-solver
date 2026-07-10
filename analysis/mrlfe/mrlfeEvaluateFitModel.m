function [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%MRLFEEVALUATEFITMODEL Evaluate mRLFE Cp on a fitting frequency grid.
%
% [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%
% The maintained fitting path builds a public mRLFE request and evaluates it
% through mrlfeSolve. Compatibility metadata is kept for FitTool diagnostics.
%
if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 4 || isempty(solverOptions)
    solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0.05, ...
        'A0Policy', "physicalTail");
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

request = mrlfeBuildFitSolveRequest(params, frequencyInput, branchName, solverOptions);
modelResult = mrlfeSolve(request);
Cp_mps = modelResult.phaseVelocity_mps(:);
rawResult = localAdaptPublicResultForFitWorkflow(modelResult, params, solverOptions);
end

function rawResult = localAdaptPublicResultForFitWorkflow(modelResult, params, solverOptions)
internal = modelResult.diagnostics.rawInternalResult;
rawResult = struct();
rawResult.modelFamily = "mrlfe";
rawResult.modelName = "mRLFERealK";
rawResult.branchName = modelResult.branch;
rawResult.frequency_Hz = modelResult.frequency_Hz(:);
rawResult.frequencySolve_Hz = internal.frequencySolve_Hz(:);
rawResult.Cp_mps = modelResult.phaseVelocity_mps(:);
rawResult.validMask = modelResult.validMask(:);
rawResult.branch = internal.branch;
rawResult.branchSolve = internal.branchSolve;
rawResult.rawFullResult = internal.rawFullResult;
rawResult.rawFullResult = localAddCompatibilityModelAliases(rawResult.rawFullResult, modelResult);
rawResult.params = params;
rawResult.options = localMergeReportedOptions(solverOptions, internal.options);
rawResult.modelResult = modelResult;
rawResult.fitPerformanceDefaults = localBuildPublicFitPerformanceSummary(modelResult);
rawResult.evaluationPath = localPublicEvaluationPathSummary(modelResult, internal);
end

function rawFullResult = localAddCompatibilityModelAliases(rawFullResult, modelResult)
if ~isstruct(rawFullResult) || ~isfield(rawFullResult, 'models') || ...
        ~isfield(rawFullResult.models, 'mRLFERealK')
    return;
end

switch string(modelResult.execution.internalEngine)
    case "elastic_adaptive"
        rawFullResult.models.mRLFEElasticRealK = rawFullResult.models.mRLFERealK;
    case "viscoelastic_adaptive"
        rawFullResult.models.mRLFEViscoRealK = rawFullResult.models.mRLFERealK;
end
end

function options = localMergeReportedOptions(inputOptions, internalOptions)
options = internalOptions;
if ~isstruct(inputOptions)
    return;
end
names = fieldnames(inputOptions);
for i = 1:numel(names)
    name = names{i};
    if startsWith(name, 'mrlfeElasticReferenceResult')
        options.(name) = inputOptions.(name);
    end
end
end

function summary = localBuildPublicFitPerformanceSummary(modelResult)
preset = modelResult.configuration.numericalPreset;
summary = struct();
summary.routeFamily = "public_solver";
summary.useFitAtlasPreset = logical(preset.useFitAtlasPreset);
summary.preset = string(modelResult.execution.effectivePreset);
summary.publicPreset = string(modelResult.execution.effectivePreset);
summary.internalFitAtlasPreset = string(modelResult.execution.effectivePreset);
summary.atlasCpScanPoints = preset.scanPoints;
summary.a0DpCandidates = preset.candidateCount;
summary.adaptiveWindows = preset.adaptiveWindows;
summary.requestedPreset = string(modelResult.execution.requestedPreset);
summary.effectivePreset = string(modelResult.execution.effectivePreset);
end

function summary = localPublicEvaluationPathSummary(modelResult, internal)
summary = struct();
summary.routeFamily = "public_solver";
summary.path = string(modelResult.execution.internalEngine);
summary.actualPath = summary.path;
summary.expectedPath = "mrlfe_public_solver";
summary.requestedAtlasFitRoute = false;
summary.usedAtlasFitRoute = false;
summary.usedPublicSolver = true;
summary.requestedUnifiedAtlas = false;
summary.usedUnifiedAtlas = false;
summary.requestedDirectViscoAtlas = false;
summary.usedDirectViscoAtlas = false;
summary.etaS = modelResult.configuration.parameters.etaS_Pas;
summary.mrlfeA0Policy = modelResult.termination.policy;
summary.fitAtlasPreset = string(modelResult.execution.effectivePreset);
summary.internalFitAtlasPreset = string(modelResult.execution.effectivePreset);
summary.requestedPreset = string(modelResult.execution.requestedPreset);
summary.effectivePreset = string(modelResult.execution.effectivePreset);
summary.internalEngine = string(modelResult.execution.internalEngine);
summary.terminationPolicy = string(modelResult.termination.policy);
summary.fallbackPolicy = string(modelResult.fallback.policy);
summary.fallbackApplied = logical(modelResult.fallback.applied);
summary.quality = modelResult.quality;
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

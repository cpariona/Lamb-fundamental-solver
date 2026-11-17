function [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%MRLFEEVALUATEFITMODEL Evaluate mRLFE Cp on a fitting frequency grid.
%
% Repeated optimizer evaluations use forwardModel.gridPolicy = "fitOptimized"
% by default. Explicit requested-curve evaluations set the policy to
% "numericalPreset" and therefore use the selected Fast/Balanced/Robust grid.

if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 4 || isempty(solverOptions)
    solverOptions = lamb.fitting.mrlfe.mrlfeDefaultFitOptions(branchName, 'EtaS', 0.05, ...
        'A0Policy', "physicalTail");
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

% The public solver needs a strictly ascending axis. Joint repetitions may
% repeat or interleave frequencies, so solve each distinct frequency once and
% map the prediction back to every requested row (no averaging, no row loss).
frequencySolveInput = unique(frequencyInput, 'sorted');
[~, rowIndex] = ismember(frequencyInput, frequencySolveInput);

request = lamb.models.mrlfe.configuration.mrlfeBuildSolveRequest(params, frequencySolveInput, branchName, solverOptions);
[request, fitGridMetadata] = applyForwardGridPolicy(request, frequencySolveInput, solverOptions);
modelResult = lamb.models.mrlfe.mrlfeSolve(request);
Cp_mps = modelResult.phaseVelocity_mps(:);
rawResult = localAdaptPublicResultForFitWorkflow(modelResult, params, solverOptions, fitGridMetadata);
if ~isequal(frequencyInput, frequencySolveInput)
    % Only observation-aligned arrays are expanded; modelResult, fitGrid and
    % solver diagnostics retain the official unique-frequency solve.
    Cp_mps = Cp_mps(rowIndex);
    rawResult.frequency_Hz = frequencyInput;
    rawResult.Cp_mps = Cp_mps;
    rawResult.validMask = rawResult.validMask(rowIndex);
end
end

function [request, metadata] = applyForwardGridPolicy(request, frequencyInput, options)
forwardModel = struct();
if isstruct(options) && isfield(options, 'forwardModel') && isstruct(options.forwardModel)
    forwardModel = options.forwardModel;
end
policy = string(getStructField(forwardModel, 'gridPolicy', "fitOptimized"));
metadata = struct('gridPolicy', policy);

switch policy
    case "fitOptimized"
        [frequencySolve_Hz, metadata] = lamb.fitting.mrlfe.mrlfeBuildFitFrequencyGrid(frequencyInput, forwardModel);
        request.numerics.frequencySolveOverride_Hz = frequencySolve_Hz;
    case "numericalPreset"
        % No override: the production solver resolves the selected preset.
    otherwise
        error('mrlfe:InvalidFitGridPolicy', ...
            'Unsupported mRLFE forwardModel.gridPolicy "%s". Use "fitOptimized" or "numericalPreset".', policy);
end
end

function rawResult = localAdaptPublicResultForFitWorkflow(modelResult, params, solverOptions, fitGridMetadata)
internal = modelResult.debug.solverResult;
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
rawResult.elasticReferenceResult = internal.branchSolve;
rawResult.params = params;
rawResult.options = localMergeReportedOptions(solverOptions, internal.options);
rawResult.modelResult = modelResult;
rawResult.fitGrid = fitGridMetadata;
rawResult.fitPerformanceDefaults = localBuildPublicFitPerformanceSummary(modelResult, fitGridMetadata);
rawResult.evaluationPath = localPublicEvaluationPathSummary(modelResult, fitGridMetadata);
end

function options = localMergeReportedOptions(inputOptions, internalOptions)
options = internalOptions;
if ~isstruct(inputOptions)
    return;
end
names = fieldnames(inputOptions);
for i = 1:numel(names)
    name = names{i};
    if startsWith(name, 'mrlfeElasticReferenceResult') || strcmp(name, 'forwardModel')
        options.(name) = inputOptions.(name);
    end
end
end

function summary = localBuildPublicFitPerformanceSummary(modelResult, fitGridMetadata)
preset = modelResult.configuration.effective.options.numericalPreset;
summary = struct();
summary.routeFamily = "public_solver";
summary.useFitAtlasPreset = logical(preset.useFitAtlasPreset);
summary.preset = string(modelResult.execution.effectivePreset);
summary.publicPreset = string(modelResult.execution.effectivePreset);
summary.internalFitAtlasPreset = string(modelResult.execution.effectivePreset);
summary.atlasCpScanPoints = preset.scanPoints;
summary.rescueCpScanPoints = preset.rescueScanPoints;
summary.a0DpCandidates = preset.candidateCount;
summary.adaptiveWindows = preset.adaptiveWindows;
summary.requestedPreset = string(modelResult.execution.requestedPreset);
summary.effectivePreset = string(modelResult.execution.effectivePreset);
summary.gridPolicy = string(fitGridMetadata.gridPolicy);
end

function summary = localPublicEvaluationPathSummary(modelResult, fitGridMetadata)
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
summary.etaS = modelResult.configuration.effective.parameters.etaS_Pas;
summary.mrlfeA0Policy = modelResult.termination.policy;
summary.fitAtlasPreset = string(modelResult.execution.effectivePreset);
summary.internalFitAtlasPreset = string(modelResult.execution.effectivePreset);
summary.requestedPreset = string(modelResult.execution.requestedPreset);
summary.effectivePreset = string(modelResult.execution.effectivePreset);
summary.gridPolicy = string(fitGridMetadata.gridPolicy);
summary.internalEngine = string(modelResult.execution.internalEngine);
summary.terminationPolicy = string(modelResult.termination.policy);
summary.fallbackPolicy = string(modelResult.fallback.policy);
summary.fallbackApplied = logical(modelResult.fallback.applied);
summary.quality = modelResult.quality;
end

function value = getStructField(s, fieldName, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
end
end

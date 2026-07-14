function fitOutput = guiFitMRLFESolver(request)
%GUIFITMRLFESOLVER Run mRLFE fitting from an app-level request.

request = guiBuildFitRequest(request.modelFamily, ...
    'branchName', request.branchName, ...
    'mode', request.mode, ...
    'experimental', request.experimental, ...
    'fixedParams', request.fixedParams, ...
    'freeParams', request.freeParams, ...
    'initialGuess', request.initialGuess, ...
    'bounds', request.bounds, ...
    'controls', request.controls, ...
    'fitOptions', request.fitOptions, ...
    'outputMode', request.outputMode);

branchName = string(request.branchName);
if strlength(branchName) == 0
    branchName = "A0Like";
end
if ~(branchName == "A0Like" || branchName == "S0Like")
    error('Unsupported mRLFE fitting branchName. Use A0Like or S0Like.');
end

controls = request.controls;
if ~isfield(controls, 'etaS') || isempty(controls.etaS)
    controls.etaS = 0.05;
end
if ~isfield(controls, 'fluidDensity') || isempty(controls.fluidDensity)
    controls.fluidDensity = 1000;
end
if ~isfield(controls, 'fluidSoundSpeed') || isempty(controls.fluidSoundSpeed)
    controls.fluidSoundSpeed = 1500;
end
if ~isfield(controls, 'mrlfeA0Policy') || isempty(controls.mrlfeA0Policy)
    controls.mrlfeA0Policy = "physicalTail";
end

[solverOptions, profileMetadata] = mrlfeResolveExecutionProfile(branchName, controls, ...
    'Surface', "fit", ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default", ...
    'EtaS', controls.etaS, ...
    'A0Policy', string(controls.mrlfeA0Policy));
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
request.controls = controls;
solverOptions.mrlfeParams.fluidDensity = controls.fluidDensity;
solverOptions.mrlfeParams.fluidSoundSpeed = controls.fluidSoundSpeed;
solverOptions.forwardModel = localForwardModelPolicy(request.fitOptions);

routePolicy = localRoutePolicy(branchName, request.freeParams, controls);

fixedParams = request.fixedParams;
if ~any(string(request.freeParams) == "etaS") && ~isfield(fixedParams, 'etaS')
    fixedParams.etaS = controls.etaS;
end

fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = request.freeParams;
fitConfig.fixedParams = fixedParams;
fitConfig.initialGuess = request.initialGuess;
fitConfig.bounds = request.bounds;
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = request.fitOptions;

 tFit = tic;
fitResult = mrlfeFitDispersionData(request.experimental, fitConfig);
fitElapsedSeconds = toc(tFit);
normalized = guiNormalizeFitResult(fitResult, request);
profileMetadata.internalAtlasPreset = localFitAtlasPreset(fitResult);
profileMetadata.routePolicy = localActualEvaluationPath(fitResult);
profileMetadata.forwardGridPolicy = string(solverOptions.forwardModel.gridPolicy);
normalized.executionProfile = profileMetadata;
normalized.fullCurve.executionProfile = profileMetadata;
normalized.fitElapsedSeconds = fitElapsedSeconds;

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "mrlfe";
fitOutput.modelName = "mRLFERealK";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
fitOutput.routePolicy = routePolicy;
fitOutput.routePolicy.actualPath = localActualEvaluationPath(fitResult);
fitOutput.routePolicy.mrlfeA0Policy = string(controls.mrlfeA0Policy);
fitOutput.routePolicy.etaS = localActualEtaS(fitResult, controls.etaS);
fitOutput.routePolicy.fitAtlasPreset = localFitAtlasPreset(fitResult);
fitOutput.routePolicy.forwardGridPolicy = string(solverOptions.forwardModel.gridPolicy);
fitOutput.executionProfile = profileMetadata;
fitOutput.fitElapsedSeconds = fitElapsedSeconds;
end

function forwardModel = localForwardModelPolicy(fitOptions)
forwardModel = struct();
forwardModel.gridPolicy = "fitOptimized";
forwardModel.minimumPointCount = 12;
forwardModel.maximumPointCount = 40;
forwardModel.maximumStep_Hz = 250;
if isstruct(fitOptions) && isfield(fitOptions, 'forwardModel') && isstruct(fitOptions.forwardModel)
    names = fieldnames(fitOptions.forwardModel);
    for i = 1:numel(names)
        forwardModel.(names{i}) = fitOptions.forwardModel.(names{i});
    end
end
end

function policy = localRoutePolicy(branchName, freeParams, controls)
freeParams = string(freeParams(:));
policy = struct();
policy.branchName = string(branchName);
policy.freeParams = freeParams;
policy.routeFamily = "public_solver";
policy.expectedPath = "mrlfe_public_solver";
policy.description = "mRLFE fitting uses the public mrlfeSolve production API.";
policy.terminationPolicy = terminationPolicyForBranch(branchName);
policy.fallbackPolicy = "none";
end

function path = localActualEvaluationPath(fitResult)
path = "unknown";
try
    if isfield(fitResult, 'rawSolverResult') && isfield(fitResult.rawSolverResult, 'evaluationPath') && ...
            isfield(fitResult.rawSolverResult.evaluationPath, 'path')
        path = string(fitResult.rawSolverResult.evaluationPath.path);
    end
catch
    path = "unknown";
end
end

function etaS = localActualEtaS(fitResult, defaultEtaS)
etaS = defaultEtaS;
try
    if isfield(fitResult, 'allParams') && isfield(fitResult.allParams, 'etaS')
        etaS = fitResult.allParams.etaS;
    end
catch
end
end

function preset = localFitAtlasPreset(fitResult)
preset = "unknown";
try
    if isfield(fitResult, 'rawSolverResult') && isfield(fitResult.rawSolverResult, 'evaluationPath') && ...
            isfield(fitResult.rawSolverResult.evaluationPath, 'fitAtlasPreset')
        preset = string(fitResult.rawSolverResult.evaluationPath.fitAtlasPreset);
    elseif isfield(fitResult, 'rawSolverResult') && isfield(fitResult.rawSolverResult, 'fitPerformanceDefaults') && ...
            isfield(fitResult.rawSolverResult.fitPerformanceDefaults, 'preset')
        preset = string(fitResult.rawSolverResult.fitPerformanceDefaults.preset);
    end
catch
    preset = "unknown";
end
end

function policy = terminationPolicyForBranch(branchName)
if string(branchName) == "A0Like"
    policy = "physicalTail";
else
    policy = "none";
end
end

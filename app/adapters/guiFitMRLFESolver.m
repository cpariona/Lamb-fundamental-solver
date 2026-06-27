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
if ~isfield(controls, 'robustness') || strlength(string(controls.robustness)) == 0
    controls.robustness = "Fast";
end
if ~isfield(controls, 'etaS') || isempty(controls.etaS)
    controls.etaS = 0.05;
end
if ~isfield(controls, 'fluidDensity') || isempty(controls.fluidDensity)
    controls.fluidDensity = 1000;
end
if ~isfield(controls, 'fluidSoundSpeed') || isempty(controls.fluidSoundSpeed)
    controls.fluidSoundSpeed = 1500;
end

solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', controls.etaS);
solverOptions.mrlfeParams.fluidDensity = controls.fluidDensity;
solverOptions.mrlfeParams.fluidSoundSpeed = controls.fluidSoundSpeed;
routePolicy = localRoutePolicy(branchName, request.freeParams);
if routePolicy.requestDirectViscoAtlas
    solverOptions.mrlfeUseDirectViscoAtlas = true;
    solverOptions.mrlfeDisableForwardCache = true;
end

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

fitResult = mrlfeFitDispersionData(request.experimental, fitConfig);
normalized = guiNormalizeFitResult(fitResult, request);

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "mrlfe";
fitOutput.modelName = "mRLFERealK";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
fitOutput.routePolicy = routePolicy;
fitOutput.routePolicy.actualPath = localActualEvaluationPath(fitResult);
end

function policy = localRoutePolicy(branchName, freeParams)
freeParams = string(freeParams(:));
policy = struct();
policy.branchName = string(branchName);
policy.freeParams = freeParams;
policy.requestDirectViscoAtlas = branchName == "A0Like" && numel(freeParams) == 1 && freeParams(1) == "etaS";
if policy.requestDirectViscoAtlas
    policy.expectedPath = "direct_viscous_atlas";
    policy.description = "A0Like etaS fitting uses the validated direct viscous atlas route.";
else
    policy.expectedPath = "maintained_rl_mrlfe_workflow";
    policy.description = "mRLFE fitting uses the maintained reference-based workflow.";
end
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

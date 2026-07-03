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
if ~isfield(controls, 'mrlfeUseUnifiedAtlasRoute') || isempty(controls.mrlfeUseUnifiedAtlasRoute)
    controls.mrlfeUseUnifiedAtlasRoute = true;
end
if ~isfield(controls, 'mrlfeA0Policy') || isempty(controls.mrlfeA0Policy)
    controls.mrlfeA0Policy = "adaptivePhysicalTail";
end
if ~isfield(controls, 'mrlfeUseAtlasFitRoute') || isempty(controls.mrlfeUseAtlasFitRoute)
    controls.mrlfeUseAtlasFitRoute = true;
end

[solverOptions, profileMetadata] = mrlfeResolveExecutionProfile(branchName, controls, ...
    'Surface', "fit", ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default", ...
    'EtaS', controls.etaS, ...
    'UseUnifiedAtlasRoute', logical(controls.mrlfeUseUnifiedAtlasRoute), ...
    'A0Policy', string(controls.mrlfeA0Policy));
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
request.controls = controls;
solverOptions.mrlfeParams.fluidDensity = controls.fluidDensity;
solverOptions.mrlfeParams.fluidSoundSpeed = controls.fluidSoundSpeed;
solverOptions.mrlfeUseAtlasFitRoute = logical(controls.mrlfeUseAtlasFitRoute);
solverOptions.mrlfeFitAtlasPreset = "fast_fit_atlas";

routePolicy = localRoutePolicy(branchName, request.freeParams, controls);
if routePolicy.requestDirectViscoAtlas
    solverOptions.mrlfeUseDirectViscoAtlas = true;
    solverOptions.mrlfeDisableForwardCache = true;
    solverOptions.mrlfeUseAtlasFitRoute = false;
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
profileMetadata.internalAtlasPreset = localFitAtlasPreset(fitResult);
profileMetadata.routePolicy = localActualEvaluationPath(fitResult);
normalized.executionProfile = profileMetadata;

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
fitOutput.executionProfile = profileMetadata;
end

function policy = localRoutePolicy(branchName, freeParams, controls)
freeParams = string(freeParams(:));
useAtlasFitRoute = isstruct(controls) && isfield(controls, 'mrlfeUseAtlasFitRoute') && ...
    ~isempty(controls.mrlfeUseAtlasFitRoute) && logical(controls.mrlfeUseAtlasFitRoute);
useUnifiedAtlas = isstruct(controls) && isfield(controls, 'mrlfeUseUnifiedAtlasRoute') && ...
    ~isempty(controls.mrlfeUseUnifiedAtlasRoute) && logical(controls.mrlfeUseUnifiedAtlasRoute);
policy = struct();
policy.branchName = string(branchName);
policy.freeParams = freeParams;
policy.routeFamily = "atlas";
policy.requestAtlasFitRoute = logical(useAtlasFitRoute);
policy.requestUnifiedAtlas = logical(useUnifiedAtlas);
policy.requestDirectViscoAtlas = ~useAtlasFitRoute && ~useUnifiedAtlas && ...
    branchName == "A0Like" && numel(freeParams) == 1 && freeParams(1) == "etaS";
if policy.requestAtlasFitRoute
    policy.expectedPath = "mrlfe_atlas";
    policy.description = "mRLFE fitting uses the official atlas output surface for A0Like and S0Like, analogous to AE atlasA0 fitting.";
elseif policy.requestDirectViscoAtlas
    policy.routeFamily = "legacy";
    policy.expectedPath = "direct_viscous_atlas";
    policy.description = "Legacy A0Like etaS fitting uses the direct viscous atlas route only when atlas-fit routing is explicitly disabled.";
else
    policy.routeFamily = "legacy";
    policy.expectedPath = "maintained_rl_mrlfe_workflow";
    policy.description = "Legacy mRLFE fitting uses the maintained reference-based workflow only when atlas-fit routing is explicitly disabled.";
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

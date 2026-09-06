function fitOutput = guiFitMRLFESolver(request)
%GUIFITMRLFESOLVER Run mRLFE fitting from an app-level request.

request = guiBuildFitRequest(request.modelFamily, ...
    'branchName', request.branchName, 'mode', request.mode, ...
    'experimental', request.experimental, 'fixedParams', request.fixedParams, ...
    'freeParams', request.freeParams, 'initialGuess', request.initialGuess, ...
    'bounds', request.bounds, 'controls', request.controls, ...
    'fitOptions', request.fitOptions, 'outputMode', request.outputMode);

branchName = string(request.branchName);
if strlength(branchName) == 0
    branchName = "A0Like";
end
if ~(branchName == "A0Like" || branchName == "S0Like")
    error('Unsupported mRLFE fitting branchName. Use A0Like or S0Like.');
end

controls = fitControls(request.controls);
[solverOptions, profileMetadata] = mrlfeResolveExecutionProfile(branchName, controls, ...
    'Surface', "fit", 'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default", 'EtaS', controls.etaS, ...
    'A0Policy', string(controls.mrlfeA0Policy));
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
request.controls = controls;
solverOptions.mrlfeParams.fluidDensity = controls.fluidDensity;
solverOptions.mrlfeParams.fluidSoundSpeed = controls.fluidSoundSpeed;
solverOptions.forwardModel = forwardModelPolicy(request.fitOptions);

fixedParams = request.fixedParams;
if ~any(string(request.freeParams) == "etaS") && ~isfield(fixedParams, 'etaS')
    fixedParams.etaS = controls.etaS;
end
fitConfig = struct('branchName', branchName, 'freeParams', request.freeParams, ...
    'fixedParams', fixedParams, 'initialGuess', request.initialGuess, ...
    'bounds', request.bounds, 'solverOptions', solverOptions, ...
    'fitOptions', request.fitOptions);

timerStart = tic;
fitResult = mrlfeFitDispersionData(request.experimental, fitConfig);
fitElapsedSeconds = toc(timerStart);
evaluation = fitResult.modelEvaluation.evaluationPath;
modelResult = fitResult.modelEvaluation.modelResult;

profileMetadata = mrlfeBuildSurfaceExecutionMetadata(profileMetadata, modelResult, ...
    'SurfaceDefault', "Fast", 'RoutePolicy', "lamb.models.mrlfe.mrlfeSolve", ...
    'OptimizerProfile', string(fitResult.optimizer.name), ...
    'GridPolicy', string(solverOptions.forwardModel.gridPolicy), ...
    'EtaS', fitResult.allParams.etaS, 'A0Policy', string(controls.mrlfeA0Policy));
profileMetadata.routePolicy = string(evaluation.path);
profileMetadata.forwardGridPolicy = string(evaluation.gridPolicy);

normalized = guiNormalizeFitResult(fitResult, request);
normalized.executionProfile = profileMetadata;
normalized.fullCurve.executionProfile = profileMetadata;
normalized.fitElapsedSeconds = fitElapsedSeconds;

routePolicy = buildRoutePolicy(branchName, request.freeParams, controls, evaluation, fitResult.allParams.etaS);
fitOutput = struct( ...
    'request', request, 'modelFamily', "mrlfe", 'modelName', "mRLFERealK", ...
    'branchName', branchName, 'fitResult', fitResult, 'normalized', normalized, ...
    'routePolicy', routePolicy, 'executionProfile', profileMetadata, ...
    'fitElapsedSeconds', fitElapsedSeconds);
end

function controls = fitControls(controls)
defaults = struct('etaS', 0.05, 'fluidDensity', 1000, ...
    'fluidSoundSpeed', 1500, 'mrlfeA0Policy', "physicalTail");
names = fieldnames(defaults);
for i = 1:numel(names)
    name = names{i};
    if ~isfield(controls, name) || isempty(controls.(name))
        controls.(name) = defaults.(name);
    end
end
end

function forwardModel = forwardModelPolicy(fitOptions)
forwardModel = struct('gridPolicy', "fitOptimized", 'minimumPointCount', 12, ...
    'maximumPointCount', 40, 'maximumStep_Hz', 250);
if isstruct(fitOptions) && isfield(fitOptions, 'forwardModel') && isstruct(fitOptions.forwardModel)
    names = fieldnames(fitOptions.forwardModel);
    for i = 1:numel(names)
        forwardModel.(names{i}) = fitOptions.forwardModel.(names{i});
    end
end
end

function policy = buildRoutePolicy(branchName, freeParams, controls, evaluation, etaS)
policy = struct( ...
    'branchName', string(branchName), 'freeParams', string(freeParams(:)), ...
    'routeFamily', "public_solver", 'expectedPath', "mrlfe_public_solver", ...
    'description', "mRLFE fitting uses the public lamb.models.mrlfe.mrlfeSolve production API.", ...
    'terminationPolicy', terminationPolicy(branchName), 'fallbackPolicy', "none", ...
    'actualPath', string(evaluation.path), ...
    'mrlfeA0Policy', string(controls.mrlfeA0Policy), 'etaS', etaS, ...
    'fitAtlasPreset', string(evaluation.fitAtlasPreset), ...
    'forwardGridPolicy', string(evaluation.gridPolicy));
end

function policy = terminationPolicy(branchName)
if branchName == "A0Like"
    policy = "physicalTail";
else
    policy = "none";
end
end

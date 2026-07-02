function fitOutput = guiFitRLSolver(request)
%GUIFITRLSOLVER Run Rayleigh-Lamb fitting from an app-level request.

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
    branchName = "A0";
end
if ~(branchName == "A0" || branchName == "S0")
    error('Unsupported Rayleigh-Lamb fitting branchName. Use A0 or S0.');
end

controls = request.controls;
[solverOptions, profileMetadata] = rlResolveExecutionProfile(controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default");
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
request.controls = controls;

fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = request.freeParams;
fitConfig.fixedParams = request.fixedParams;
fitConfig.initialGuess = request.initialGuess;
fitConfig.bounds = request.bounds;
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = request.fitOptions;

fitResult = rlFitDispersionData(request.experimental, fitConfig);
normalized = guiNormalizeFitResult(fitResult, request);
normalized.executionProfile = profileMetadata;

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "rayleigh_lamb";
fitOutput.modelName = "RayleighLamb";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
fitOutput.executionProfile = profileMetadata;
end

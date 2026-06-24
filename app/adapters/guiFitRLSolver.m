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
if ~isfield(controls, 'robustness') || strlength(string(controls.robustness)) == 0
    controls.robustness = "Fast";
end

fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = request.freeParams;
fitConfig.fixedParams = request.fixedParams;
fitConfig.initialGuess = request.initialGuess;
fitConfig.bounds = request.bounds;
fitConfig.solverOptions = rlDefaultOptions(string(controls.robustness));
fitConfig.fitOptions = request.fitOptions;

fitResult = rlFitDispersionData(request.experimental, fitConfig);
normalized = guiNormalizeFitResult(fitResult, request);

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "rayleigh_lamb";
fitOutput.modelName = "RayleighLamb";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
end

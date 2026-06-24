function fitOutput = guiFitAcoustoelasticIOPHGOSolver(request)
%GUIFITACOUSTOELASTICIOPHGOSOLVER Run AE IOP/HGO fitting from an app-level request.

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
    branchName = "atlasA0";
end
branchName = aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting supports only atlasA0.');
end

controls = request.controls;
if ~isfield(controls, 'robustness') || strlength(string(controls.robustness)) == 0
    controls.robustness = "Fast";
end

solverOptions = aeDefaultSweepOptions(string(controls.robustness));
solverOptions.atlasBranchPolicy = "atlasA0";
if isfield(controls, 'atlasNumYPoints') && ~isempty(controls.atlasNumYPoints)
    solverOptions.atlasNumYPoints = controls.atlasNumYPoints;
end
if isfield(controls, 'atlasTopNMinima') && ~isempty(controls.atlasTopNMinima)
    solverOptions.atlasTopNMinima = controls.atlasTopNMinima;
end
if isfield(controls, 'atlasInitializationNumFrequencyPoints') && ~isempty(controls.atlasInitializationNumFrequencyPoints)
    solverOptions.atlasInitializationNumFrequencyPoints = controls.atlasInitializationNumFrequencyPoints;
end

fitConfig = struct();
fitConfig.branchName = branchName;
fitConfig.freeParams = request.freeParams;
fitConfig.fixedParams = request.fixedParams;
fitConfig.initialGuess = request.initialGuess;
fitConfig.bounds = request.bounds;
fitConfig.solverOptions = solverOptions;
fitConfig.fitOptions = request.fitOptions;

fitResult = aeFitDispersionData(request.experimental, fitConfig);
normalized = guiNormalizeFitResult(fitResult, request);

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "acoustoelastic_iop_hgo";
fitOutput.modelName = "AcoustoelasticIOPHGO";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
end

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
[solverOptions, profileMetadata] = aeResolveExecutionProfile(controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default");
controls.executionProfile = profileMetadata.requestedExecutionProfile;
controls.robustness = profileMetadata.requestedExecutionProfile;
request.controls = controls;
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
profileMetadata = localApplyAEFitOverrideMetadata(profileMetadata, solverOptions);

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
normalized.executionProfile = profileMetadata;
normalized.fullCurve.executionProfile = profileMetadata;

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "acoustoelastic_iop_hgo";
fitOutput.modelName = "AcoustoelasticIOPHGO";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
fitOutput.executionProfile = profileMetadata;
end

function metadata = localApplyAEFitOverrideMetadata(metadata, solverOptions)
metadata.atlasNumYPoints = solverOptions.atlasNumYPoints;
metadata.atlasTopNMinima = solverOptions.atlasTopNMinima;
metadata.internalAtlasPreset = "ae_atlas_" + string(solverOptions.atlasNumYPoints) + "x" + string(solverOptions.atlasTopNMinima);
metadata.routePolicy = string(solverOptions.atlasBranchPolicy);
if isfield(solverOptions, 'atlasInitializationNumFrequencyPoints')
    metadata.atlasInitializationNumFrequencyPoints = solverOptions.atlasInitializationNumFrequencyPoints;
end
requestedOptions = aeDefaultSweepOptions(metadata.requestedExecutionProfile);
if solverOptions.atlasNumYPoints ~= requestedOptions.atlasNumYPoints || ...
        solverOptions.atlasTopNMinima ~= requestedOptions.atlasTopNMinima
    metadata.profileOverrideApplied = true;
    metadata.profileOverrideReason = "FitTool AE preserves the maintained fast atlas fitting controls.";
    if solverOptions.atlasNumYPoints == 300 && solverOptions.atlasTopNMinima == 12
        metadata.effectiveExecutionProfile = "Fast";
    elseif solverOptions.atlasNumYPoints == 600 && solverOptions.atlasTopNMinima == 16
        metadata.effectiveExecutionProfile = "Balanced";
    elseif solverOptions.atlasNumYPoints == 900 && solverOptions.atlasTopNMinima == 20
        metadata.effectiveExecutionProfile = "Robust";
    end
else
    metadata.profileOverrideApplied = false;
    metadata.profileOverrideReason = "";
end
end

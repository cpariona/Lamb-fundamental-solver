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
branchName = lamb.models.acoustoelastic_iop_hgo.configuration.aeNormalizeBranchPolicy(branchName);
if branchName ~= "atlasA0"
    error('AE IOP/HGO fitting supports only atlasA0.');
end

controls = request.controls;
overrides = copyControlOverrides(struct(), controls, ...
    {'atlasNumYPoints', 'atlasTopNMinima', 'atlasInitializationNumFrequencyPoints'});
[solverOptions, profileMetadata] = aeResolveExecutionProfile(controls, ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default", ...
    'Surface', "FitTool", ...
    'Overrides', overrides, ...
    'OverrideReason', "FitTool AE preserves the maintained fast atlas fitting controls.");
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

tFit = tic;
fitResult = aeFitDispersionData(request.experimental, fitConfig);
fitElapsedSeconds = toc(tFit);
normalized = guiNormalizeFitResult(fitResult, request);
normalized.executionProfile = profileMetadata;
normalized.fullCurve.executionProfile = profileMetadata;
normalized.fitElapsedSeconds = fitElapsedSeconds;

fitOutput = struct();
fitOutput.request = request;
fitOutput.modelFamily = "acoustoelastic_iop_hgo";
fitOutput.modelName = "AcoustoelasticIOPHGO";
fitOutput.branchName = branchName;
fitOutput.fitResult = fitResult;
fitOutput.normalized = normalized;
fitOutput.executionProfile = profileMetadata;
fitOutput.fitElapsedSeconds = fitElapsedSeconds;
end

function target = copyControlOverrides(target, controls, names)
for i = 1:numel(names)
    name = names{i};
    if isfield(controls, name) && ~isempty(controls.(name))
        target.(name) = controls.(name);
    end
end
end

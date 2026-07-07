function [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%MRLFEEVALUATEFITMODEL Evaluate mRLFE Cp on a fitting frequency grid.
%
% [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%
% The maintained fitting path builds a public mRLFE request and evaluates it
% through mrlfeSolve. Compatibility metadata is kept for FitTool diagnostics.
%
% The older reference/direct-viscous workflow is retained only for explicit
% diagnostic calls with solverOptions.mrlfeUseAtlasFitRoute = false.

if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 4 || isempty(solverOptions)
    solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0.05, ...
        'UseUnifiedAtlasRoute', true, 'A0Policy', "adaptivePhysicalTail");
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

if localShouldUsePublicFitRoute(solverOptions)
    request = mrlfeBuildFitSolveRequest(params, frequencyInput, branchName, solverOptions);
    modelResult = mrlfeSolve(request);
    Cp_mps = modelResult.phaseVelocity_mps(:);
    rawResult = localAdaptPublicResultForFitWorkflow(modelResult, params, solverOptions);
    return;
end

[params, frequencySolve_Hz] = localPrepareFrequencyParams(params, frequencyInput);
solverOptions = localPrepareOptions(solverOptions, branchName, params);
useDirectViscoAtlas = localShouldUseDirectViscoAtlas(solverOptions, branchName);

if useDirectViscoAtlas
    [rawFullResult, branchSolve] = localEvaluateDirectViscoAtlas(params, frequencySolve_Hz, branchName, solverOptions);
else
    rawFullResult = rlComputeFundamentalLambModes(params, solverOptions);
    branchSolve = localExtractBranch(rawFullResult, branchName);
end
[branch, Cp_mps] = localResampleBranchToRequestedGrid(branchSolve, frequencyInput);

rawResult = struct();
rawResult.modelFamily = "mrlfe";
rawResult.modelName = "mRLFERealK";
rawResult.branchName = branchName;
rawResult.frequency_Hz = frequencyInput;
rawResult.frequencySolve_Hz = frequencySolve_Hz;
rawResult.Cp_mps = Cp_mps;
rawResult.validMask = localBranchValidMask(branch);
rawResult.branch = branch;
rawResult.branchSolve = branchSolve;
rawResult.rawFullResult = rawFullResult;
rawResult.params = params;
rawResult.options = solverOptions;
rawResult.fitPerformanceDefaults = localBuildFitPerformanceSummary(solverOptions);
rawResult.evaluationPath = localEvaluationPathSummary(solverOptions, useDirectViscoAtlas);
end

function tf = localShouldUsePublicFitRoute(options)
tf = logical(getOption(options, 'mrlfeUseAtlasFitRoute', true));
if logical(getOption(options, 'mrlfeUseLegacyFitRoute', false))
    tf = false;
end
end

function rawResult = localAdaptPublicResultForFitWorkflow(modelResult, params, solverOptions)
internal = modelResult.diagnostics.rawInternalResult;
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
rawResult.rawFullResult = internal.rawFullResult;
rawResult.rawFullResult = localAddCompatibilityModelAliases(rawResult.rawFullResult, modelResult);
rawResult.params = params;
rawResult.options = localMergeReportedOptions(solverOptions, internal.options);
rawResult.modelResult = modelResult;
rawResult.fitPerformanceDefaults = localBuildPublicFitPerformanceSummary(modelResult);
rawResult.evaluationPath = localPublicEvaluationPathSummary(modelResult, internal);
end

function rawFullResult = localAddCompatibilityModelAliases(rawFullResult, modelResult)
if ~isstruct(rawFullResult) || ~isfield(rawFullResult, 'models') || ...
        ~isfield(rawFullResult.models, 'mRLFERealK')
    return;
end

switch string(modelResult.execution.internalEngine)
    case "elastic_adaptive"
        rawFullResult.models.mRLFEElasticRealK = rawFullResult.models.mRLFERealK;
    case "viscoelastic_adaptive"
        rawFullResult.models.mRLFEViscoRealK = rawFullResult.models.mRLFERealK;
end
end

function options = localMergeReportedOptions(inputOptions, internalOptions)
options = internalOptions;
if ~isstruct(inputOptions)
    return;
end
names = fieldnames(inputOptions);
for i = 1:numel(names)
    name = names{i};
    if startsWith(name, 'mrlfeElasticReferenceResult')
        options.(name) = inputOptions.(name);
    end
end
end

function summary = localBuildPublicFitPerformanceSummary(modelResult)
preset = modelResult.configuration.numericalPreset;
summary = struct();
summary.routeFamily = "public_solver";
summary.useFitAtlasPreset = logical(preset.useFitAtlasPreset);
summary.preset = string(modelResult.execution.effectivePreset);
summary.publicPreset = string(modelResult.execution.effectivePreset);
summary.internalFitAtlasPreset = string(preset.internalFitAtlasPreset);
summary.atlasCpScanPoints = preset.scanPoints;
summary.a0DpCandidates = preset.candidateCount;
summary.adaptiveWindows = preset.adaptiveWindows;
summary.requestedPreset = string(modelResult.execution.requestedPreset);
summary.effectivePreset = string(modelResult.execution.effectivePreset);
end

function summary = localPublicEvaluationPathSummary(modelResult, internal)
summary = struct();
summary.routeFamily = "atlas";
summary.path = string(internal.executionPath.referenceOracle);
summary.actualPath = summary.path;
summary.expectedPath = "mrlfe_public_solver";
summary.requestedAtlasFitRoute = true;
summary.usedAtlasFitRoute = false;
summary.usedPublicSolver = true;
summary.requestedUnifiedAtlas = modelResult.configuration.parameters.etaS_Pas > 0;
summary.usedUnifiedAtlas = modelResult.configuration.parameters.etaS_Pas > 0;
summary.requestedDirectViscoAtlas = false;
summary.usedDirectViscoAtlas = false;
summary.etaS = modelResult.configuration.parameters.etaS_Pas;
summary.mrlfeA0Policy = modelResult.termination.policy;
summary.fitAtlasPreset = string(modelResult.configuration.numericalPreset.internalFitAtlasPreset);
summary.internalFitAtlasPreset = string(modelResult.configuration.numericalPreset.internalFitAtlasPreset);
summary.requestedPreset = string(modelResult.execution.requestedPreset);
summary.effectivePreset = string(modelResult.execution.effectivePreset);
summary.internalEngine = string(modelResult.execution.internalEngine);
summary.terminationPolicy = string(modelResult.termination.policy);
summary.fallbackPolicy = string(modelResult.fallback.policy);
summary.fallbackApplied = logical(modelResult.fallback.applied);
summary.quality = modelResult.quality;
end

function [params, frequencySolve_Hz] = localPrepareFrequencyParams(params, frequency_Hz)
frequency_Hz = frequency_Hz(:);
[frequencySorted, ~] = sort(frequency_Hz);
if any(abs(frequencySorted - frequency_Hz) > 0)
    error('mRLFE fitting currently requires frequency_Hz to be sorted ascending.');
end

if numel(frequencySorted) == 1
    f0 = frequencySorted(1);
    halfWidth = max(0.05 * f0, 1.0);
    fmin = max(eps(f0), f0 - halfWidth);
    fmax = f0 + halfWidth;
else
    fmin = frequencySorted(1);
    fmax = frequencySorted(end);
end

numFrequencyPoints = max(10, numel(frequencySorted));
frequencySolve_Hz = linspace(fmin, fmax, numFrequencyPoints).';

params.fmin = fmin;
params.fmax = fmax;
params.numFrequencyPoints = numFrequencyPoints;
params.frequencySpacing = "linspace";
end

function options = localPrepareOptions(options, branchName, params)
branchName = string(branchName);
options.computeMRLFERealK = true;
options.computeMRLFEElasticRealK = true;
options.computeMRLFEViscoRealK = true;
options.computeMRLFEComplexK = false;
options.mrlfeA0Policy = string(getOption(options, 'mrlfeA0Policy', "delayedCut"));

if ~isfield(options, 'mrlfeParams') || isempty(options.mrlfeParams)
    options.mrlfeParams = defaultMRLFEParams();
end
options.mrlfeParams.solveComplexK = false;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
if isfield(params, 'etaS') && ~isempty(params.etaS)
    options.mrlfeParams.etaS = params.etaS;
end

switch branchName
    case "A0Like"
        options.computeA0 = true;
        options.computeS0 = false;
        options.mrlfeComputeA0Like = true;
        options.mrlfeComputeS0Like = false;
    case "S0Like"
        options.computeA0 = false;
        options.computeS0 = true;
        options.mrlfeComputeA0Like = false;
        options.mrlfeComputeS0Like = true;
    otherwise
        error('Unsupported mRLFE fitting branch: %s.', branchName);
end

options = localApplyFitPerformanceDefaults(options, branchName);
end

function tf = localShouldUseDirectViscoAtlas(options, branchName)
tf = false;
if getOption(options, 'mrlfeUseUnifiedAtlasRoute', false)
    return;
end
if ~(isstruct(options) && isfield(options, 'mrlfeUseDirectViscoAtlas') && options.mrlfeUseDirectViscoAtlas)
    return;
end
if branchName ~= "A0Like"
    return;
end
etaS = 0;
if isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS') && ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end
tf = isfinite(etaS) && etaS > 0;
end

function [rawFullResult, branchSolve] = localEvaluateDirectViscoAtlas(params, frequencySolve_Hz, branchName, solverOptions)
rlParams = params;
rlParams.fmin = min(frequencySolve_Hz);
rlParams.fmax = max(frequencySolve_Hz);
rlParams.numFrequencyPoints = numel(frequencySolve_Hz);
rlParams.frequencySpacing = "linspace";

rlOptions = rlDefaultOptions("Fast");
rlOptions.computeA0 = branchName == "A0Like";
rlOptions.computeS0 = branchName == "S0Like";
rlOptions.computeMRLFE = false;
rlOptions.computeMRLFERealK = false;
rlOptions.computeMRLFEElasticRealK = false;
rlOptions.computeMRLFEViscoRealK = false;
rlOptions.computeMRLFEComplexK = false;

rlStart = tic;
rawRL = rlComputeFundamentalLambModes(rlParams, rlOptions);
rlElapsed = toc(rlStart);

if branchName == "A0Like"
    if ~isfield(rawRL, 'modes') || ~isfield(rawRL.modes, 'A0')
        error('Direct mRLFE viscous atlas requires Rayleigh-Lamb A0 seed mode.');
    end
    seedMode = rawRL.modes.A0;
else
    if ~isfield(rawRL, 'modes') || ~isfield(rawRL.modes, 'S0')
        error('Direct mRLFE viscous atlas requires Rayleigh-Lamb S0 seed mode.');
    end
    seedMode = rawRL.modes.S0;
end

atlasStart = tic;
branchSolve = solveMRLFEViscoBranchAtlas(branchName, seedMode, rawRL.material, rawRL.geometry, solverOptions.mrlfeParams, solverOptions);
atlasElapsed = toc(atlasStart);

rawFullResult = rawRL;
rawFullResult.models = struct();
rawFullResult.models.mRLFERealK = struct();
rawFullResult.models.mRLFERealK.modelName = "mRLFE";
rawFullResult.models.mRLFERealK.variant = "direct-viscous-atlas-real-k";
rawFullResult.models.mRLFERealK.description = "Direct viscous mRLFE Cp atlas prototype without elastic mRLFE reference branch.";
rawFullResult.models.mRLFERealK.parameters = solverOptions.mrlfeParams;
rawFullResult.models.mRLFERealK.frequency = frequencySolve_Hz(:);
rawFullResult.models.mRLFERealK.branches = struct();
rawFullResult.models.mRLFERealK.branches.(char(branchName)) = branchSolve;
rawFullResult.models.mRLFERealK.diagnostics = struct();
rawFullResult.models.mRLFERealK.diagnostics.elapsedSeconds = atlasElapsed;
rawFullResult.models.mRLFERealK.diagnostics.rayleighLambSeedElapsedSeconds = rlElapsed;
rawFullResult.models.mRLFERealK.diagnostics.variant = "direct-viscous-atlas-real-k";
rawFullResult.models.mRLFERealK.diagnostics.branchNames = branchName;
rawFullResult.models.mRLFERealK.diagnostics.usedInternalTrackingGrid = false;
rawFullResult.models.mRLFERealK.diagnostics.requestedPointCount = numel(frequencySolve_Hz);
rawFullResult.models.mRLFERealK.diagnostics.trackingPointCount = numel(frequencySolve_Hz);
end

function options = localApplyFitPerformanceDefaults(options, branchName)
useDefaults = getOption(options, 'mrlfeUseFitPerformanceDefaults', true);
options.mrlfeUseFitPerformanceDefaults = logical(useDefaults);
if ~useDefaults
    options.mrlfeFitPerformancePreset = "off";
    return;
end

etaS = 0;
if isfield(options, 'mrlfeParams') && isfield(options.mrlfeParams, 'etaS') && ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end

if ~(branchName == "A0Like" && abs(etaS) <= eps(max(1, abs(etaS))))
    options.mrlfeFitPerformancePreset = "maintained_default";
    return;
end

options.mrlfeFitPerformancePreset = getOption(options, 'mrlfeFitPerformancePreset', "fast_elastic_A0Like");
options.mrlfeUseInternalTrackingGrid = getOption(options, 'mrlfeFitUseInternalTrackingGrid', true);
options.mrlfeInternalTrackingMinPoints = getOption(options, 'mrlfeFitInternalTrackingMinPoints', 10);
options.mrlfeInternalTrackingPointFactor = getOption(options, 'mrlfeFitInternalTrackingPointFactor', 1);
options.mrlfeInternalTrackingMaxPoints = getOption(options, 'mrlfeFitInternalTrackingMaxPoints', 80);
options.mrlfeA0DPCpScanPoints = getOption(options, 'mrlfeFitA0DPCpScanPoints', 500);
options.mrlfeA0DPCandidates = getOption(options, 'mrlfeFitA0DPCandidates', getOption(options, 'mrlfeA0DPCandidates', 8));
end

function summary = localBuildFitPerformanceSummary(options)
summary = struct();
summary.routeFamily = "legacy";
summary.useFitPerformanceDefaults = getOption(options, 'mrlfeUseFitPerformanceDefaults', false);
summary.preset = getOption(options, 'mrlfeFitPerformancePreset', "off");
summary.useInternalTrackingGrid = getOption(options, 'mrlfeUseInternalTrackingGrid', false);
summary.internalTrackingMinPoints = getOption(options, 'mrlfeInternalTrackingMinPoints', NaN);
summary.internalTrackingPointFactor = getOption(options, 'mrlfeInternalTrackingPointFactor', NaN);
summary.internalTrackingMaxPoints = getOption(options, 'mrlfeInternalTrackingMaxPoints', NaN);
summary.a0DpCpScanPoints = getOption(options, 'mrlfeA0DPCpScanPoints', NaN);
summary.a0DpCandidates = getOption(options, 'mrlfeA0DPCandidates', NaN);
end

function summary = localEvaluationPathSummary(options, usedDirectViscoAtlas)
requestedDirectViscoAtlas = getOption(options, 'mrlfeUseDirectViscoAtlas', false);
requestedUnifiedAtlas = getOption(options, 'mrlfeUseUnifiedAtlasRoute', false);
summary = struct();
summary.routeFamily = "legacy";
summary.requestedAtlasFitRoute = false;
summary.usedAtlasFitRoute = false;
summary.requestedDirectViscoAtlas = logical(requestedDirectViscoAtlas);
summary.requestedUnifiedAtlas = logical(requestedUnifiedAtlas);
summary.useDirectViscoAtlas = logical(usedDirectViscoAtlas);
summary.usedDirectViscoAtlas = logical(usedDirectViscoAtlas);
summary.usedUnifiedAtlas = logical(requestedUnifiedAtlas && ~usedDirectViscoAtlas);
summary.mrlfeA0Policy = string(getOption(options, 'mrlfeA0Policy', "delayedCut"));
if usedDirectViscoAtlas
    summary.path = "direct_viscous_atlas";
elseif requestedUnifiedAtlas
    summary.path = "unified_atlas";
else
    summary.path = "maintained_rl_mrlfe_workflow";
end
summary.actualPath = summary.path;
end

function branch = localExtractBranch(rawFullResult, branchName)
if ~isfield(rawFullResult, 'models') || ~isfield(rawFullResult.models, 'mRLFERealK') || ...
        ~isfield(rawFullResult.models.mRLFERealK, 'branches') || ...
        ~isfield(rawFullResult.models.mRLFERealK.branches, char(branchName))
    error('mRLFE result does not contain requested branch: %s.', branchName);
end
branch = rawFullResult.models.mRLFERealK.branches.(char(branchName));
end

function [branchOut, CpRequested_mps] = localResampleBranchToRequestedGrid(branchIn, frequencyRequested_Hz)
frequencyRequested_Hz = frequencyRequested_Hz(:);
frequencySolve_Hz = branchIn.frequency(:);
CpSolve_mps = branchIn.Cp(:);

branchOut = branchIn;
branchOut.frequency = frequencyRequested_Hz;
branchOut.omega = 2 * pi * frequencyRequested_Hz;
branchOut.Cp = interpolateNumeric(CpSolve_mps, frequencySolve_Hz, frequencyRequested_Hz);

numericFields = {'k', 'kReal', 'kImag', 'attenuation', 'kThickness', 'residual', 'score', 'seedK', 'seedCp'};
for i = 1:numel(numericFields)
    fieldName = numericFields{i};
    if isfield(branchIn, fieldName)
        branchOut.(fieldName) = interpolateNumeric(branchIn.(fieldName), frequencySolve_Hz, frequencyRequested_Hz);
    end
end

logicalFields = {'validResidual', 'validReference', 'validSmooth', 'validCp', 'validAttenuation', 'valid'};
for i = 1:numel(logicalFields)
    fieldName = logicalFields{i};
    if isfield(branchIn, fieldName)
        branchOut.(fieldName) = interpolateLogical(branchIn.(fieldName), frequencySolve_Hz, frequencyRequested_Hz);
    end
end

CpRequested_mps = branchOut.Cp(:);
end

function valuesOut = interpolateNumeric(valuesIn, frequencyIn, frequencyOut)
valuesIn = valuesIn(:);
if isempty(valuesIn) || numel(valuesIn) ~= numel(frequencyIn)
    valuesOut = nan(size(frequencyOut));
    return;
end
valid = isfinite(frequencyIn) & isfinite(real(valuesIn)) & isfinite(imag(valuesIn));
if nnz(valid) < 2
    valuesOut = nan(size(frequencyOut));
    return;
end
if ~isreal(valuesIn)
    realPart = interp1(frequencyIn(valid), real(valuesIn(valid)), frequencyOut, 'linear', nan);
    imagPart = interp1(frequencyIn(valid), imag(valuesIn(valid)), frequencyOut, 'linear', nan);
    valuesOut = realPart + 1i * imagPart;
else
    valuesOut = interp1(frequencyIn(valid), valuesIn(valid), frequencyOut, 'linear', nan);
end
end

function valuesOut = interpolateLogical(valuesIn, frequencyIn, frequencyOut)
valuesIn = logical(valuesIn(:));
if isempty(valuesIn) || numel(valuesIn) ~= numel(frequencyIn)
    valuesOut = false(size(frequencyOut));
    return;
end
nearest = interp1(frequencyIn, double(valuesIn), frequencyOut, 'nearest', 0);
valuesOut = logical(nearest(:));
end

function validMask = localBranchValidMask(branch)
if isfield(branch, 'validCp')
    validMask = logical(branch.validCp(:)) & isfinite(branch.Cp(:));
elseif isfield(branch, 'valid')
    validMask = logical(branch.valid(:)) & isfinite(branch.Cp(:));
else
    validMask = isfinite(branch.Cp(:));
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

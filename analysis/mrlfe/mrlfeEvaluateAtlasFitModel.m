function [Cp_mps, rawResult] = mrlfeEvaluateAtlasFitModel(params, frequency_Hz, branchName, solverOptions)
%MRLFEEVALUATEATLASFITMODEL Diagnostic/reference mRLFE atlas fitting oracle.
%
% [Cp_mps, rawResult] = mrlfeEvaluateAtlasFitModel(params, frequency_Hz,
% branchName, solverOptions) evaluates A0Like or S0Like through the atlas-style
% real-k mRLFE route and resamples the official atlas branch onto the requested
% fitting frequencies.
%
% This helper is not the maintained production evaluator. It is retained
% temporarily as a diagnostic/reference oracle for characterization and
% migration tests while FitTool fitting consumes the public mrlfeSolve API.

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

[params, frequencySolve_Hz] = localPrepareFrequencyParams(params, frequencyInput);
solverOptions = localPrepareOptions(solverOptions, branchName, params);

rawFullResult = localComputeRayleighLambSeed(params, branchName);
etaS = localGetEtaS(solverOptions);
[mrlfeResult, actualPath, routeQuality] = localSolveAtlas(rawFullResult, branchName, solverOptions, etaS);

rawFullResult.models.mRLFERealK = mrlfeResult;
rawFullResult.models.mRLFE = mrlfeResult;
branchSolve = localExtractBranch(rawFullResult, branchName);
[branch, Cp_mps] = localResampleBranchToRequestedGrid(branchSolve, frequencyInput);
validMask = localBranchValidMask(branch);

rawResult = struct();
rawResult.modelFamily = "mrlfe";
rawResult.modelName = "mRLFERealK";
rawResult.branchName = branchName;
rawResult.frequency_Hz = frequencyInput;
rawResult.frequencySolve_Hz = frequencySolve_Hz;
rawResult.Cp_mps = Cp_mps;
rawResult.validMask = validMask;
rawResult.branch = branch;
rawResult.branchSolve = branchSolve;
rawResult.rawFullResult = rawFullResult;
rawResult.params = params;
rawResult.options = solverOptions;
rawResult.fitPerformanceDefaults = localBuildFitPerformanceSummary(solverOptions);
rawResult.evaluationPath = localEvaluationPathSummary(solverOptions, actualPath, etaS, routeQuality);
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
options.computeMRLFEElasticRealK = false;
options.computeMRLFEViscoRealK = false;
options.computeMRLFEComplexK = false;
options.mrlfeUseAtlasFitRoute = true;
options.mrlfeA0Policy = string(localGetOption(options, 'mrlfeA0Policy', "adaptivePhysicalTail"));
options.mrlfeFitAtlasPreset = string(localGetOption(options, 'mrlfeFitAtlasPreset', "fast_fit_atlas"));

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
        error('Unsupported mRLFE atlas fitting branch: %s.', branchName);
end

options = localApplyFitAtlasPreset(options);
end

function rawRL = localComputeRayleighLambSeed(params, branchName)
rlOptions = rlDefaultOptions("Fast");
rlOptions.computeA0 = branchName == "A0Like";
rlOptions.computeS0 = branchName == "S0Like";
rlOptions.computeMRLFE = false;
rlOptions.computeMRLFERealK = false;
rlOptions.computeMRLFEElasticRealK = false;
rlOptions.computeMRLFEViscoRealK = false;
rlOptions.computeMRLFEComplexK = false;
rawRL = rlComputeFundamentalLambModes(params, rlOptions);
end

function [mrlfeResult, actualPath, routeQuality] = localSolveAtlas(rawRL, branchName, options, etaS)
if etaS > 0
    options.mrlfeUseUnifiedAtlasRoute = true;
    mrlfeResult = solveMRLFEAtlasUnified(rawRL.grid.frequency(:), rawRL.material, rawRL.geometry, ...
        rawRL.modes, options.mrlfeParams, options);
    actualPath = "viscous_unified_atlas";
else
    mrlfeResult = localSolveZeroViscosityAdaptive(rawRL, branchName, options);
    actualPath = "zero_viscosity_adaptive_atlas";
end
routeQuality = localSummarizeAtlasCpQuality(mrlfeResult, branchName);
end

function mrlfeResult = localSolveZeroViscosityAdaptive(rawRL, branchName, options)
frequency = rawRL.grid.frequency(:);
zeroParams = options.mrlfeParams;
zeroParams.etaS = 0;
zeroParams.solveComplexK = false;
zeroParams.etaL = 0;
zeroParams.useComplexLambda = false;

mrlfeResult = struct();
mrlfeResult.modelName = "mRLFE";
mrlfeResult.variant = "zero-viscosity-adaptive-real-k-fit";
mrlfeResult.description = "Zero-viscosity adaptive mRLFE real-k fitting atlas route.";
mrlfeResult.parameters = zeroParams;
mrlfeResult.frequency = frequency;
mrlfeResult.branches = struct();
mrlfeResult.atlasUnified = struct('isViscous', false, ...
    'useZeroViscosityAdaptiveAtlas', true, ...
    'fitRoute', true, ...
    'seedStrategy', "RayleighLambOrPhysicalSynthetic");

seedMode = mrlfeMakePhysicalSeedMode(branchName, frequency, rawRL.material, rawRL.geometry, rawRL.modes);
branch = solveMRLFEBranchAdaptiveAtlas(branchName, seedMode, rawRL.material, rawRL.geometry, zeroParams, options);
branch.solverRoute = "zeroViscosityAdaptiveAtlasFit";
branch.seedMode = seedMode;
if branchName == "A0Like"
    branch.atlasUnifiedPolicy = "zeroViscosityA0AdaptivePhysicalTailCut";
    if localGetOption(options, 'mrlfeUseA0PhysicalTailCut', true)
        branch = mrlfeApplyPhysicalCorridorCut(branch, seedMode.Cp, seedMode.frequency, localMakeA0PhysicalTailCutOptions(options));
    end
else
    branch.atlasUnifiedPolicy = "zeroViscosityS0AdaptiveContinuation";
end
mrlfeResult.branches.(char(branchName)) = branch;
mrlfeResult.diagnostics = struct('variant', mrlfeResult.variant, 'branchNames', branchName);
end

function options = localApplyFitAtlasPreset(options)
if ~logical(localGetOption(options, 'mrlfeUseFitAtlasPreset', true))
    options.mrlfeFitAtlasPreset = "off";
    return;
end

options.mrlfeFitAtlasPreset = string(localGetOption(options, 'mrlfeFitAtlasPreset', "fast_fit_atlas"));
options.mrlfeUseA0PhysicalTailCut = localGetOption(options, 'mrlfeUseA0PhysicalTailCut', true);
options.mrlfeA0DPCpScanPoints = localGetOption(options, 'mrlfeFitAtlasCpScanPoints', localGetOption(options, 'mrlfeA0DPCpScanPoints', 260));
options.mrlfeViscoAtlasCpScanPoints = localGetOption(options, 'mrlfeFitAtlasCpScanPoints', localGetOption(options, 'mrlfeViscoAtlasCpScanPoints', 260));
options.mrlfeAdaptiveCpScanPoints = localGetOption(options, 'mrlfeFitAtlasCpScanPoints', localGetOption(options, 'mrlfeAdaptiveCpScanPoints', 260));
options.mrlfeA0DPCandidates = localGetOption(options, 'mrlfeFitAtlasCandidates', localGetOption(options, 'mrlfeA0DPCandidates', 5));
options.mrlfeA0DPRefineCandidates = localGetOption(options, 'mrlfeFitAtlasRefineCandidates', localGetOption(options, 'mrlfeA0DPRefineCandidates', false));
options.mrlfeAdaptiveRefineCandidates = localGetOption(options, 'mrlfeFitAtlasRefineCandidates', localGetOption(options, 'mrlfeAdaptiveRefineCandidates', false));
options.mrlfeAdaptiveWindows = localGetOption(options, 'mrlfeAdaptiveWindows', [0.20 0.40 0.80]);
options.mrlfeAdaptiveValleyFallbackRelativeWindow = localGetOption(options, 'mrlfeAdaptiveValleyFallbackRelativeWindow', 0.12);
options.mrlfeAdaptiveResidualWeight = localGetOption(options, 'mrlfeAdaptiveResidualWeight', 0.45);
options.mrlfeAdaptivePredictionWeight = localGetOption(options, 'mrlfeAdaptivePredictionWeight', 45.0);
options.mrlfeAdaptiveValleyFallbackResidualWeight = localGetOption(options, 'mrlfeAdaptiveValleyFallbackResidualWeight', 0.30);
options.mrlfeAdaptiveValleyFallbackPredictionWeight = localGetOption(options, 'mrlfeAdaptiveValleyFallbackPredictionWeight', 65.0);
end

function corridorOptions = localMakeA0PhysicalTailCutOptions(options)
corridorOptions = struct();
corridorOptions.minRatioToGuide = localGetOption(options, 'mrlfeA0PhysicalMinRatioToGuide', 0.70);
corridorOptions.maxRatioToGuide = localGetOption(options, 'mrlfeA0PhysicalMaxRatioToGuide', inf);
corridorOptions.minFrequencyHz = localGetOption(options, 'mrlfeA0PhysicalMinFrequencyHz', 1000);
corridorOptions.minValidRunBeforeCut = localGetOption(options, 'mrlfeA0PhysicalMinValidRunBeforeCut', 8);
corridorOptions.maxLocalDropRelative = localGetOption(options, 'mrlfeA0PhysicalMaxLocalDropRelative', 0.05);
corridorOptions.maxTwoStepDropRelative = localGetOption(options, 'mrlfeA0PhysicalMaxTwoStepDropRelative', 0.10);
end

function summary = localBuildFitPerformanceSummary(options)
summary = struct();
summary.routeFamily = "atlas";
summary.useFitAtlasPreset = localGetOption(options, 'mrlfeUseFitAtlasPreset', true);
summary.preset = string(localGetOption(options, 'mrlfeFitAtlasPreset', "fast_fit_atlas"));
summary.atlasCpScanPoints = localGetOption(options, 'mrlfeAdaptiveCpScanPoints', localGetOption(options, 'mrlfeA0DPCpScanPoints', NaN));
summary.a0DpCandidates = localGetOption(options, 'mrlfeA0DPCandidates', NaN);
summary.adaptiveWindows = localGetOption(options, 'mrlfeAdaptiveWindows', []);
end

function summary = localEvaluationPathSummary(options, actualPath, etaS, routeQuality)
summary = struct();
summary.routeFamily = "atlas";
summary.path = string(actualPath);
summary.actualPath = string(actualPath);
summary.expectedPath = "mrlfe_atlas";
summary.requestedAtlasFitRoute = true;
summary.usedAtlasFitRoute = true;
summary.requestedUnifiedAtlas = etaS > 0;
summary.usedUnifiedAtlas = etaS > 0;
summary.requestedDirectViscoAtlas = false;
summary.usedDirectViscoAtlas = false;
summary.etaS = etaS;
summary.mrlfeA0Policy = string(localGetOption(options, 'mrlfeA0Policy', "adaptivePhysicalTail"));
summary.fitAtlasPreset = string(localGetOption(options, 'mrlfeFitAtlasPreset', "fast_fit_atlas"));
summary.quality = routeQuality;
end

function branch = localExtractBranch(rawFullResult, branchName)
if ~isfield(rawFullResult, 'models') || ~isfield(rawFullResult.models, 'mRLFERealK') || ...
        ~isfield(rawFullResult.models.mRLFERealK, 'branches') || ...
        ~isfield(rawFullResult.models.mRLFERealK.branches, char(branchName))
    error('mRLFE atlas result does not contain requested branch: %s.', branchName);
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
branchOut.Cp = localInterpolateNumeric(CpSolve_mps, frequencySolve_Hz, frequencyRequested_Hz);

numericFields = {'k', 'kReal', 'kImag', 'attenuation', 'kThickness', 'residual', 'score', 'seedK', 'seedCp'};
for i = 1:numel(numericFields)
    fieldName = numericFields{i};
    if isfield(branchIn, fieldName)
        branchOut.(fieldName) = localInterpolateNumeric(branchIn.(fieldName), frequencySolve_Hz, frequencyRequested_Hz);
    end
end

logicalFields = {'validResidual', 'validReference', 'validSmooth', 'validCp', 'validAttenuation', 'valid'};
for i = 1:numel(logicalFields)
    fieldName = logicalFields{i};
    if isfield(branchIn, fieldName)
        branchOut.(fieldName) = localInterpolateLogical(branchIn.(fieldName), frequencySolve_Hz, frequencyRequested_Hz);
    end
end

CpRequested_mps = branchOut.Cp(:);
end

function valuesOut = localInterpolateNumeric(valuesIn, frequencyIn, frequencyOut)
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

function valuesOut = localInterpolateLogical(valuesIn, frequencyIn, frequencyOut)
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

function quality = localSummarizeAtlasCpQuality(mrlfeResult, branchName)
quality = struct('validFraction', NaN, 'validCount', 0, 'totalCount', 0, 'maxJumpRelative', NaN);
if ~isstruct(mrlfeResult) || ~isfield(mrlfeResult, 'branches') || ...
        ~isfield(mrlfeResult.branches, char(branchName))
    return;
end
branch = mrlfeResult.branches.(char(branchName));
if isfield(branch, 'Cp')
    cp = branch.Cp(:);
elseif isfield(branch, 'phaseVelocity')
    cp = branch.phaseVelocity(:);
else
    return;
end
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp') && numel(branch.validCp) == numel(cp)
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid') && numel(branch.valid) == numel(cp)
    valid = valid & logical(branch.valid(:));
end
quality.totalCount = numel(cp);
quality.validCount = nnz(valid);
if quality.totalCount > 0
    quality.validFraction = quality.validCount / quality.totalCount;
end
quality.maxJumpRelative = localMaxRelativeJump(cp(valid));
end

function y = localMaxRelativeJump(x)
x = x(:);
x = x(isfinite(x) & x > 0);
if numel(x) < 2
    y = 0;
else
    y = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

function etaS = localGetEtaS(options)
etaS = 0;
if isstruct(options) && isfield(options, 'mrlfeParams') && ...
        isfield(options.mrlfeParams, 'etaS') && ~isempty(options.mrlfeParams.etaS)
    etaS = options.mrlfeParams.etaS;
end
end

function value = localGetOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

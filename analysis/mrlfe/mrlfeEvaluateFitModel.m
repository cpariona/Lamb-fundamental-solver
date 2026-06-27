function [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%MRLFEEVALUATEFITMODEL Evaluate mRLFE Cp on a fitting frequency grid.
%
% [Cp_mps, rawResult] = mrlfeEvaluateFitModel(params, frequency_Hz, branchName, solverOptions)
%
% The helper evaluates the maintained mRLFE real-k workflow through
% rlComputeFundamentalLambModes. The internal forward solve uses at least 10
% frequency points to satisfy the Rayleigh-Lamb base solver validation, then
% interpolates the branch back to the experimental fitting frequencies.
%
% The elastic/geometric parameters remain in params. The mRLFE viscosity
% parameter etaS may also be passed in params for fitting; when present it is
% propagated to solverOptions.mrlfeParams.etaS before the forward solve.

if nargin < 3 || isempty(branchName)
    branchName = "A0Like";
end
if nargin < 4 || isempty(solverOptions)
    solverOptions = mrlfeDefaultSweepOptions(branchName, 'EtaS', 0.05);
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
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

% The fast fitting preset has been validated only for the elastic A0Like real-k
% baseline. Viscous real-k branches use a different tracker/reference path and
% can lose all valid Cp points if the elastic A0 DP scan is reduced too much.
% Keep viscous and S0Like fitting on the maintained solver defaults until a
% separate option-sensitivity diagnostic validates faster settings for them.
if ~(branchName == "A0Like" && abs(etaS) <= eps(max(1, abs(etaS))))
    options.mrlfeFitPerformancePreset = "maintained_default";
    return;
end

% Fitting calls the forward mRLFE evaluator repeatedly. The maintained sweep
% defaults are intentionally conservative, but they are too expensive for
% iterative fitting. Diagnostics on the A0Like elastic real-k baseline showed
% that 500 Cp scan points and a 10-point internal tracking grid preserve the
% branch within a few millimetres per second while reducing forward time by
% nearly one order of magnitude for the standard fitting data window.
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
summary = struct();
summary.requestedDirectViscoAtlas = logical(requestedDirectViscoAtlas);
summary.useDirectViscoAtlas = logical(usedDirectViscoAtlas);
summary.usedDirectViscoAtlas = logical(usedDirectViscoAtlas);
if usedDirectViscoAtlas
    summary.path = "direct_viscous_atlas";
else
    summary.path = "maintained_rl_mrlfe_workflow";
end
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

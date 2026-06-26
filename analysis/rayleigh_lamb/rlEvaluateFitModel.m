function [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%RLEVALUATEFITMODEL Evaluate Rayleigh-Lamb Cp on a fitting frequency grid.
%
% [Cp_mps, rawResult] = rlEvaluateFitModel(params, frequency_Hz, branchName, options)
%
% This helper is intended for fitting. It builds an internal tracking grid,
% explicitly includes the requested experimental frequencies, and evaluates the
% requested Rayleigh-Lamb branch by continuation with prediction fallback
% disabled. The returned Cp values are therefore sampled from one coherent modal
% branch rather than from independent per-frequency residual minima.

if nargin < 3 || isempty(branchName)
    branchName = "A0";
end
if nargin < 4 || isempty(options)
    options = rlDefaultOptions("Fast");
end

branchName = string(branchName);
frequencyInput = frequency_Hz(:);
if isempty(frequencyInput) || any(~isfinite(frequencyInput)) || any(frequencyInput <= 0)
    error('frequency_Hz must contain positive finite values.');
end

rlValidateParams(params);
rlValidateOptions(options);

material = rlComputeMaterial(params);
geometry = rlComputeGeometry(params);

[frequencyTrack, requestIndexInTrack] = localBuildTrackingFrequencyGrid(frequencyInput, options);
solverOptions = localBuildSolverOptions(options, material);
solverOptions.disallowPredictionFallback = true;

geometryForSpec = geometry;
geometryForSpec.frequency0 = frequencyTrack(1);
branchSpec = rlMakeBranchSpec(branchName, material, geometryForSpec);
solverOptions = localApplyBranchSpec(solverOptions, branchSpec);

switch branchName
    case "A0"
        residualFcn = @(Cp, f) rlAResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    case "S0"
        residualFcn = @(Cp, f) rlSResidual(Cp, f, material.CL, material.CT, geometry.halfThickness);
    otherwise
        error('Unsupported Rayleigh-Lamb fitting branch: %s.', branchName);
end

[CpTrack, residualTrack] = rlSolveFundamentalBranch(frequencyTrack, residualFcn, solverOptions);

Cp_mps = CpTrack(requestIndexInTrack);
residual = residualTrack(requestIndexInTrack);
omega = 2 * pi * frequencyInput;
k = omega ./ Cp_mps;
validMask = isfinite(Cp_mps) & isfinite(residual) & isfinite(k) & Cp_mps > 0;
Cp_mps(~validMask) = NaN;
k(~validMask) = NaN;

rawResult = struct();
rawResult.modelFamily = "rayleigh_lamb";
rawResult.branchName = branchName;
rawResult.frequency_Hz = frequencyInput;
rawResult.Cp_mps = Cp_mps;
rawResult.omega = omega;
rawResult.k = k;
rawResult.kThickness = k * geometry.thickness;
rawResult.residual = residual;
rawResult.validMask = validMask;
rawResult.material = material;
rawResult.geometry = rmfield(geometry, 'halfThickness');
rawResult.options = options;
rawResult.trackingMode = "branch_coherent_internal_grid";
rawResult.internalFrequency_Hz = frequencyTrack;
rawResult.internalCp_mps = CpTrack;
rawResult.internalResidual = residualTrack;
rawResult.internalValidMask = isfinite(CpTrack) & isfinite(residualTrack) & CpTrack > 0;
rawResult.selectedBranch = branchName;
rawResult.minimaTable = struct([]);
rawResult.branchTable = localBuildBranchTable(branchName, frequencyTrack, CpTrack, residualTrack);
rawResult.reliability = localBuildReliability(branchName, frequencyInput, validMask, frequencyTrack, CpTrack, residualTrack);
rawResult.diagnostics = localBuildDiagnostics(frequencyInput, frequencyTrack, requestIndexInTrack, solverOptions);
end

function [frequencyTrack, requestIndexInTrack] = localBuildTrackingFrequencyGrid(frequencyInput, options)
frequencySorted = sort(frequencyInput(:));
fminRequest = min(frequencySorted);
fmaxRequest = max(frequencySorted);

initMinDefault = min(300, fminRequest);
initMin = getOption(options, 'rlFitInitializationMinFrequency_Hz', initMinDefault);
if ~isfinite(initMin) || initMin <= 0
    initMin = initMinDefault;
end
initMin = min(initMin, fminRequest);

if fmaxRequest <= initMin
    fmaxTrack = fmaxRequest * 1.05;
else
    fmaxTrack = fmaxRequest;
end

numRequest = numel(unique(frequencySorted));
numInit = getOption(options, 'rlFitInitializationNumFrequencyPoints', max(16, 2 * numRequest));
numInit = max(10, round(numInit));

if fmaxTrack > initMin
    initGrid = linspace(initMin, fmaxTrack, numInit).';
else
    halfWidth = max(0.05 * fminRequest, 1.0);
    initGrid = linspace(max(fminRequest - halfWidth, eps), fminRequest + halfWidth, numInit).';
end

frequencyTrack = unique([initGrid; frequencySorted], 'sorted');
[~, requestIndexInTrack] = ismember(frequencyInput, frequencyTrack);

if any(requestIndexInTrack == 0)
    requestIndexInTrack = zeros(size(frequencyInput));
    for i = 1:numel(frequencyInput)
        [delta, idx] = min(abs(frequencyTrack - frequencyInput(i)));
        tol = 10 * eps(max(1, abs(frequencyInput(i))));
        if delta > tol
            error('Internal Rayleigh-Lamb fitting grid did not retain requested frequency %.15g Hz.', frequencyInput(i));
        end
        requestIndexInTrack(i) = idx;
    end
end
end

function solverOptions = localBuildSolverOptions(options, material)
solverOptions = struct();
solverOptions.CT = material.CT;
solverOptions.gridPointsInitial = options.gridPointsInitial;
solverOptions.gridPointsTracking = options.gridPointsTracking;
solverOptions.jumpTol = options.jumpTol;
solverOptions.residualTolerance = options.residualTolerance;

optionalFields = {'searchFactors', 'minCpAbsolute', 'minCpRelativeToCT', ...
    'maxCpFactorCT', 'minCpGlobalMax', 'initialGuessWeight', 'predictionWeight', ...
    'maxPredictionRelativeError', 'maxSinglePointSpikeRelative', 'preferPreviousRootWeight'};
for i = 1:numel(optionalFields)
    fieldName = optionalFields{i};
    if isfield(options, fieldName)
        solverOptions.(fieldName) = options.(fieldName);
    end
end
end

function solverOptions = localApplyBranchSpec(solverOptions, branchSpec)
solverOptions.branchName = branchSpec.name;
solverOptions.initialCpGuess = branchSpec.initialCpGuess;
solverOptions.initialSearchRange = branchSpec.initialSearchRange;
solverOptions.preferLowestCp = branchSpec.preferLowestCp;
end

function branchTable = localBuildBranchTable(branchName, frequencyTrack, CpTrack, residualTrack)
valid = isfinite(CpTrack) & isfinite(residualTrack) & CpTrack > 0;
branchTable = struct();
branchTable.name = branchName;
branchTable.validPoints = nnz(valid);
branchTable.totalPoints = numel(frequencyTrack);
branchTable.validFraction = nnz(valid) / max(1, numel(frequencyTrack));
branchTable.firstValidFrequency_Hz = localFirstValue(frequencyTrack(valid));
branchTable.lastValidFrequency_Hz = localLastValue(frequencyTrack(valid));
branchTable.maxRelativeCpJump = localMaxRelativeJump(CpTrack(valid));
branchTable.meanResidual = mean(residualTrack(valid), 'omitnan');
end

function reliability = localBuildReliability(branchName, frequencyInput, validMask, frequencyTrack, CpTrack, residualTrack)
internalValid = isfinite(CpTrack) & isfinite(residualTrack) & CpTrack > 0;
reliability = struct();
reliability.PolicyName = "rlBranchCoherentInternalGrid";
reliability.BranchName = branchName;
reliability.ValidFraction = nnz(validMask) / max(1, numel(validMask));
reliability.ValidPoints = nnz(validMask);
reliability.MissingPoints = numel(validMask) - nnz(validMask);
reliability.FirstValidFrequency_kHz = localFirstValue(frequencyInput(validMask)) / 1e3;
reliability.LastValidFrequency_kHz = localLastValue(frequencyInput(validMask)) / 1e3;
reliability.InternalValidFraction = nnz(internalValid) / max(1, numel(internalValid));
reliability.InternalFirstValidFrequency_kHz = localFirstValue(frequencyTrack(internalValid)) / 1e3;
reliability.InternalLastValidFrequency_kHz = localLastValue(frequencyTrack(internalValid)) / 1e3;
reliability.MaxBranchRelativeCpJump = localMaxRelativeJump(CpTrack(internalValid));
reliability.SelectionFallbackUsed = false;
if all(validMask)
    reliability.ValidityNote = "allRequestedPointsReported";
else
    reliability.ValidityNote = "someRequestedPointsMissingFromCoherentBranch";
end
end

function diagnostics = localBuildDiagnostics(frequencyInput, frequencyTrack, requestIndexInTrack, solverOptions)
diagnostics = struct();
diagnostics.requestedFrequency_Hz = frequencyInput;
diagnostics.internalFrequency_Hz = frequencyTrack;
diagnostics.requestIndexInTrack = requestIndexInTrack;
diagnostics.disallowPredictionFallback = true;
diagnostics.gridPointsInitial = solverOptions.gridPointsInitial;
diagnostics.gridPointsTracking = solverOptions.gridPointsTracking;
diagnostics.jumpTol = solverOptions.jumpTol;
diagnostics.residualTolerance = solverOptions.residualTolerance;
end

function value = localFirstValue(x)
x = x(:);
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = x(1);
end
end

function value = localLastValue(x)
x = x(:);
x = x(isfinite(x));
if isempty(x)
    value = NaN;
else
    value = x(end);
end
end

function maxJump = localMaxRelativeJump(Cp)
Cp = Cp(:);
Cp = Cp(isfinite(Cp) & Cp > 0);
if numel(Cp) < 2
    maxJump = NaN;
    return;
end
maxJump = max(abs(diff(Cp)) ./ max(Cp(1:end-1), eps));
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end

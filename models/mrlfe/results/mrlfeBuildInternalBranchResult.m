function rawResult = mrlfeBuildInternalBranchResult(problem, configuration, mrlfeResult, branchSolve, engineName, referenceOracle)
%MRLFEBUILDINTERNALBRANCHRESULT Build normalized internal solver output.

[branch, Cp_mps] = resampleBranch(branchSolve, problem.frequencyRequested_Hz);
validMask = branchValidMask(branch);

rawFullResult = branchSolve.seedResult;
rawFullResult.models.mRLFERealK = mrlfeResult;
rawFullResult.models.mRLFE = mrlfeResult;

rawResult = struct();
rawResult.modelFamily = "mrlfe";
rawResult.modelName = "mRLFERealK";
rawResult.branchName = configuration.branch;
rawResult.frequency_Hz = problem.frequencyRequested_Hz(:);
rawResult.frequencySolve_Hz = problem.frequencySolve_Hz(:);
rawResult.Cp_mps = Cp_mps(:);
rawResult.validMask = validMask(:);
rawResult.branch = branch;
rawResult.branchSolve = branchSolve;
rawResult.rawFullResult = rawFullResult;
rawResult.params = problem.params;
rawResult.options = configuration.internalOptions;
rawResult.executionPath = struct( ...
    'engine', string(engineName), ...
    'referenceOracle', string(referenceOracle), ...
    'requestedPreset', configuration.requestedPreset, ...
    'effectivePreset', configuration.effectivePreset);
rawResult.routeQuality = summarizeBranchQuality(branchSolve);
end

function [branchOut, CpRequested_mps] = resampleBranch(branchIn, frequencyRequested_Hz)
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

function validMask = branchValidMask(branch)
if isfield(branch, 'validCp')
    validMask = logical(branch.validCp(:)) & isfinite(branch.Cp(:));
elseif isfield(branch, 'valid')
    validMask = logical(branch.valid(:)) & isfinite(branch.Cp(:));
else
    validMask = isfinite(branch.Cp(:));
end
end

function quality = summarizeBranchQuality(branch)
cp = branch.Cp(:);
valid = isfinite(cp) & cp > 0;
if isfield(branch, 'validCp')
    valid = valid & logical(branch.validCp(:));
elseif isfield(branch, 'valid')
    valid = valid & logical(branch.valid(:));
end
quality = struct();
quality.totalCount = numel(cp);
quality.validCount = nnz(valid);
quality.validFraction = quality.validCount / max(quality.totalCount, 1);
quality.maxJumpRelative = maxRelativeJump(cp(valid));
end

function value = maxRelativeJump(x)
x = x(:);
x = x(isfinite(x) & x > 0);
if numel(x) < 2
    value = 0;
else
    value = max(abs(diff(x)) ./ max(abs(x(1:end-1)), eps));
end
end

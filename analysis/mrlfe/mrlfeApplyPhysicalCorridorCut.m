function branchOut = mrlfeApplyPhysicalCorridorCut(branchIn, guideCp, frequency, options)
%MRLFEAPPLYPHYSICALCORRIDORCUT Cut a branch when it leaves a physical Cp corridor.
%
% The corridor is defined relative to a guide branch, usually dry RL-A0. This
% does not assume that mRLFE must match RL. It only prevents continuation into
% very low-Cp mathematical/leaky roots that are incompatible with the tracked
% physical A0-like branch.

if nargin < 4
    options = struct();
end

branchOut = branchIn;
cp = branchIn.Cp(:);
guideCp = guideCp(:);
frequency = frequency(:);

minRatio = getOption(options, 'minRatioToGuide', 0.70);
maxRatio = getOption(options, 'maxRatioToGuide', inf);
minFrequencyHz = getOption(options, 'minFrequencyHz', -inf);
minValidRunBeforeCut = getOption(options, 'minValidRunBeforeCut', 8);

valid = isfinite(cp) & cp > 0 & isfinite(guideCp) & guideCp > 0;
if isfield(branchIn, 'validCp')
    valid = valid & logical(branchIn.validCp(:));
elseif isfield(branchIn, 'valid')
    valid = valid & logical(branchIn.valid(:));
end

ratio = nan(size(cp));
ratio(valid) = cp(valid) ./ guideCp(valid);
inside = valid & ratio >= minRatio & ratio <= maxRatio;

cutIndex = nan;
cutReason = "none";
validRun = 0;
for j = 1:numel(cp)
    if frequency(j) < minFrequencyHz
        continue;
    end
    if inside(j)
        validRun = validRun + 1;
    elseif valid(j) && validRun >= minValidRunBeforeCut
        cutIndex = j;
        if ratio(j) < minRatio
            cutReason = "below_min_ratio_to_guide";
        elseif ratio(j) > maxRatio
            cutReason = "above_max_ratio_to_guide";
        else
            cutReason = "outside_physical_corridor";
        end
        break;
    elseif valid(j)
        validRun = 0;
    end
end

corridorValid = valid;
if isfinite(cutIndex)
    corridorValid(cutIndex:end) = false;
end
corridorValid = corridorValid & inside;

branchOut.Cp(~corridorValid) = nan;
if isfield(branchOut, 'kReal')
    branchOut.kReal(~corridorValid) = nan;
end
if isfield(branchOut, 'k')
    branchOut.k(~corridorValid) = nan;
end
if isfield(branchOut, 'residual')
    branchOut.residual(~corridorValid) = nan;
end
if isfield(branchOut, 'validCp')
    branchOut.validCp = corridorValid;
end
if isfield(branchOut, 'valid')
    branchOut.valid = corridorValid;
end

branchOut.physicalCorridor = struct( ...
    'PolicyName', "guideRatioCorridorCut", ...
    'MinRatioToGuide', minRatio, ...
    'MaxRatioToGuide', maxRatio, ...
    'MinFrequencyHz', minFrequencyHz, ...
    'MinValidRunBeforeCut', minValidRunBeforeCut, ...
    'FirstCutIndex', cutIndex, ...
    'FirstCutFrequency', getCutFrequency(frequency, cutIndex), ...
    'CutReason', cutReason, ...
    'GuideName', "guideCp", ...
    'ValidPointsAfterCut', nnz(corridorValid));
branchOut.guideCp = guideCp;
branchOut.guideRatio = ratio;
end

function f = getCutFrequency(frequency, cutIndex)
if isfinite(cutIndex) && cutIndex >= 1 && cutIndex <= numel(frequency)
    f = frequency(cutIndex);
else
    f = nan;
end
end

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

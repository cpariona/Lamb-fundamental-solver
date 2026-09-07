function branchOut = mrlfeEvaluatePhysicalTail(branchIn, guideCp, frequency, options)
%MRLFEEVALUATEPHYSICALTAIL Apply the maintained A0 physical-tail cut.

if nargin < 4
    options = struct();
end

branchOut = branchIn;
cp = branchIn.Cp(:);
guideCp = guideCp(:);
frequency = frequency(:);

minRatio = getOption(options, 'minRatioToGuide', 0.70);
maxRatio = getOption(options, 'maxRatioToGuide', inf);
minFrequencyHz = getOption(options, 'minFrequencyHz', 1000);
minValidRunBeforeCut = getOption(options, 'minValidRunBeforeCut', 8);
maxLocalDropRelative = getOption(options, 'maxLocalDropRelative', 0.05);
maxTwoStepDropRelative = getOption(options, 'maxTwoStepDropRelative', 0.10);

valid = isfinite(cp) & cp > 0 & isfinite(guideCp) & guideCp > 0;
if isfield(branchIn, 'validCp')
    valid = valid & logical(branchIn.validCp(:));
elseif isfield(branchIn, 'valid')
    valid = valid & logical(branchIn.valid(:));
end

ratio = nan(size(cp));
ratio(valid) = cp(valid) ./ guideCp(valid);
inside = valid & ratio >= minRatio & ratio <= maxRatio;

localDrop = nan(size(cp));
twoStepDrop = nan(size(cp));
for j = 2:numel(cp)
    if valid(j) && valid(j-1)
        localDrop(j) = (cp(j-1) - cp(j)) / max(abs(cp(j-1)), eps);
    end
end
for j = 3:numel(cp)
    if valid(j) && valid(j-2)
        twoStepDrop(j) = (cp(j-2) - cp(j)) / max(abs(cp(j-2)), eps);
    end
end

cutIndex = nan;
cutReason = "none";
validRun = 0;
for j = 1:numel(cp)
    if frequency(j) < minFrequencyHz || ~valid(j)
        continue;
    end
    if inside(j)
        validRun = validRun + 1;
        continue;
    end
    outsideLow = ratio(j) < minRatio;
    outsideHigh = ratio(j) > maxRatio;
    strongDrop = localDrop(j) > maxLocalDropRelative || twoStepDrop(j) > maxTwoStepDropRelative;
    if validRun >= minValidRunBeforeCut && (outsideLow || outsideHigh) && strongDrop
        cutIndex = j;
        if outsideLow
            cutReason = "low_ratio_with_downward_collapse";
        elseif outsideHigh
            cutReason = "high_ratio_with_fast_departure";
        else
            cutReason = "outside_corridor_with_trend";
        end
        break;
    end
end

corridorValid = valid;
if isfinite(cutIndex)
    corridorValid(cutIndex:end) = false;
end

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
    'PolicyName', "guideRatioConditionalTailCut", ...
    'MinRatioToGuide', minRatio, ...
    'MaxRatioToGuide', maxRatio, ...
    'MinFrequencyHz', minFrequencyHz, ...
    'MinValidRunBeforeCut', minValidRunBeforeCut, ...
    'MaxLocalDropRelative', maxLocalDropRelative, ...
    'MaxTwoStepDropRelative', maxTwoStepDropRelative, ...
    'FirstCutIndex', cutIndex, ...
    'FirstCutFrequency', getCutFrequency(frequency, cutIndex), ...
    'CutReason', cutReason, ...
    'GuideName', "guideCp", ...
    'ValidPointsAfterCut', nnz(corridorValid));
branchOut.guideCp = guideCp;
branchOut.guideRatio = ratio;
branchOut.localDropRelative = localDrop;
branchOut.twoStepDropRelative = twoStepDrop;
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

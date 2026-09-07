function quality = mrlfeEvaluateBranchQuality(frequency_Hz, phaseVelocity_mps, validMask, options)
%MRLFEEVALUATEBRANCHQUALITY Compute public mRLFE branch quality metadata.

if nargin < 4 || isempty(options)
    options = struct();
end
frequency_Hz = frequency_Hz(:);
phaseVelocity_mps = phaseVelocity_mps(:);
validMask = logical(validMask(:)) & isfinite(phaseVelocity_mps) & phaseVelocity_mps > 0;

quality = struct();
quality.validCount = nnz(validMask);
quality.pointCount = numel(frequency_Hz);
if quality.pointCount > 0
    quality.validFraction = quality.validCount / quality.pointCount;
else
    quality.validFraction = NaN;
end
if any(validMask)
    quality.lastValidFrequency_Hz = frequency_Hz(find(validMask, 1, 'last'));
else
    quality.lastValidFrequency_Hz = NaN;
end
quality.maxRelativeJump = maxRelativeJump(phaseVelocity_mps(validMask));

minValidFraction = getOption(options, 'minValidFraction', 0.50);
maxJump = getOption(options, 'maxRelativeJump', 0.25);
quality.accepted = quality.validCount > 0 && ...
    quality.validFraction >= minValidFraction && ...
    quality.maxRelativeJump <= maxJump;
if quality.accepted
    quality.reason = "accepted";
elseif quality.validCount == 0
    quality.reason = "no_valid_points";
elseif quality.validFraction < minValidFraction
    quality.reason = "low_valid_fraction";
else
    quality.reason = "large_relative_jump";
end
quality.thresholds = struct('minValidFraction', minValidFraction, 'maxRelativeJump', maxJump);
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

function value = getOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

function [frequencySolve_Hz, metadata] = mrlfeResolveSolveFrequencyGrid(frequencyRequested_Hz, numerics)
%MRLFERESOLVESOLVEFREQUENCYGRID Resolve the internal mRLFE tracking grid.
%
% The maintained default preserves the current production behavior: a
% linearly spaced internal grid with at least ten points. Validation scripts
% may provide numerics.frequencySolveOverride_Hz to test an exact internal
% grid without changing the public requested-frequency result contract.

frequencyRequested_Hz = validateFrequencyVector( ...
    frequencyRequested_Hz, 'frequencyRequested_Hz');

if nargin < 2 || isempty(numerics)
    numerics = struct();
end
if ~isstruct(numerics)
    error('mrlfe:InvalidNumerics', 'numerics must be a struct.');
end

if isfield(numerics, 'frequencySolveOverride_Hz') && ...
        ~isempty(numerics.frequencySolveOverride_Hz)
    frequencySolve_Hz = validateFrequencyVector( ...
        numerics.frequencySolveOverride_Hz, ...
        'numerics.frequencySolveOverride_Hz');
    validateCoverage(frequencySolve_Hz, frequencyRequested_Hz);
    source = "diagnosticOverride";
else
    [fmin, fmax] = requestedBounds(frequencyRequested_Hz);
    numFrequencyPoints = max(10, numel(frequencyRequested_Hz));
    frequencySolve_Hz = linspace(fmin, fmax, numFrequencyPoints).';
    source = "defaultLinspace";
end

metadata = struct();
metadata.source = source;
metadata.pointCount = numel(frequencySolve_Hz);
metadata.fmin_Hz = frequencySolve_Hz(1);
metadata.fmax_Hz = frequencySolve_Hz(end);
metadata.minStep_Hz = minimumStep(frequencySolve_Hz);
metadata.medianStep_Hz = medianStep(frequencySolve_Hz);
metadata.maxStep_Hz = maximumStep(frequencySolve_Hz);
end

function frequency_Hz = validateFrequencyVector(frequency_Hz, fieldName)
frequency_Hz = frequency_Hz(:);
if isempty(frequency_Hz) || ~isnumeric(frequency_Hz) || ...
        any(~isfinite(frequency_Hz)) || any(frequency_Hz <= 0)
    error('mrlfe:InvalidFrequencyGrid', ...
        '%s must contain finite positive numeric values.', fieldName);
end
if numel(frequency_Hz) > 1 && any(diff(frequency_Hz) <= 0)
    error('mrlfe:InvalidFrequencyOrder', ...
        '%s must be strictly ascending.', fieldName);
end
end

function validateCoverage(frequencySolve_Hz, frequencyRequested_Hz)
tolerance = 32 * eps(max(frequencyRequested_Hz(end), 1));
if frequencySolve_Hz(1) > frequencyRequested_Hz(1) + tolerance || ...
        frequencySolve_Hz(end) < frequencyRequested_Hz(end) - tolerance
    error('mrlfe:InvalidSolveFrequencyCoverage', ...
        ['frequencySolveOverride_Hz must cover the complete requested ' ...
         'frequency interval.']);
end
end

function [fmin, fmax] = requestedBounds(frequency_Hz)
if numel(frequency_Hz) == 1
    f0 = frequency_Hz(1);
    halfWidth = max(0.05 * f0, 1.0);
    fmin = max(eps(f0), f0 - halfWidth);
    fmax = f0 + halfWidth;
else
    fmin = frequency_Hz(1);
    fmax = frequency_Hz(end);
end
end

function value = minimumStep(frequency_Hz)
if numel(frequency_Hz) < 2
    value = NaN;
else
    value = min(diff(frequency_Hz));
end
end

function value = medianStep(frequency_Hz)
if numel(frequency_Hz) < 2
    value = NaN;
else
    value = median(diff(frequency_Hz));
end
end

function value = maximumStep(frequency_Hz)
if numel(frequency_Hz) < 2
    value = NaN;
else
    value = max(diff(frequency_Hz));
end
end

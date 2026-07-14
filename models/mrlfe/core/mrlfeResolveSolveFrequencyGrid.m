function [frequencySolve_Hz, metadata] = mrlfeResolveSolveFrequencyGrid( ...
    frequencyRequested_Hz, numerics, numericalPreset)
%MRLFERESOLVESOLVEFREQUENCYGRID Resolve the internal mRLFE tracking grid.
%
% Production requests use the frequency-grid policy carried by the resolved
% numerical preset. Diagnostics may provide numerics.frequencySolveOverride_Hz;
% that exact override has precedence and preserves the public requested-grid
% result contract.

frequencyRequested_Hz = validateFrequencyVector( ...
    frequencyRequested_Hz, 'frequencyRequested_Hz');

if nargin < 2 || isempty(numerics)
    numerics = struct();
end
if ~isstruct(numerics)
    error('mrlfe:InvalidNumerics', 'numerics must be a struct.');
end
if nargin < 3 || isempty(numericalPreset) || ~isstruct(numericalPreset)
    error('mrlfe:InvalidNumericalPreset', ...
        'A resolved numerical preset is required to build the production solve grid.');
end

if isfield(numerics, 'frequencySolveOverride_Hz') && ...
        ~isempty(numerics.frequencySolveOverride_Hz)
    frequencySolve_Hz = validateFrequencyVector( ...
        numerics.frequencySolveOverride_Hz, ...
        'numerics.frequencySolveOverride_Hz');
    validateCoverage(frequencySolve_Hz, frequencyRequested_Hz);
    metadata = makeMetadata(frequencySolve_Hz, "diagnosticOverride", ...
        numericalPreset, NaN, "explicitOverride", NaN);
    return;
end

validatePresetGridPolicy(numericalPreset);
[fmin_Hz, fmax_Hz] = requestedBounds(frequencyRequested_Hz);
frequencySolve_Hz = makePresetGrid(fmin_Hz, fmax_Hz, numericalPreset);
metadata = makeMetadata(frequencySolve_Hz, "numericalPreset", ...
    numericalPreset, numericalPreset.frequencyStep_Hz, ...
    numericalPreset.frequencyGridPolicy, ...
    numericalPreset.transitionFrequency_Hz);
end

function validatePresetGridPolicy(preset)
requiredFields = {'name','frequencyStep_Hz','frequencyGridPolicy', ...
    'transitionFrequency_Hz','lowFrequencyAnchors_Hz'};
for i = 1:numel(requiredFields)
    if ~isfield(preset, requiredFields{i}) || isempty(preset.(requiredFields{i}))
        error('mrlfe:InvalidNumericalPreset', ...
            'Resolved numerical preset is missing field "%s".', requiredFields{i});
    end
end
if ~isscalar(preset.frequencyStep_Hz) || ...
        ~isfinite(preset.frequencyStep_Hz) || preset.frequencyStep_Hz <= 0
    error('mrlfe:InvalidNumericalPreset', ...
        'Numerical preset frequencyStep_Hz must be a finite positive scalar.');
end
if string(preset.frequencyGridPolicy) ~= "fixedLowAnchorsConstantHighStep"
    error('mrlfe:InvalidNumericalPreset', ...
        'Unsupported numerical preset frequency-grid policy "%s".', ...
        string(preset.frequencyGridPolicy));
end
validateFrequencyVector(preset.lowFrequencyAnchors_Hz, ...
    'numericalPreset.lowFrequencyAnchors_Hz');
end

function frequency_Hz = makePresetGrid(fmin_Hz, fmax_Hz, preset)
transition_Hz = double(preset.transitionFrequency_Hz);
step_Hz = double(preset.frequencyStep_Hz);
anchors_Hz = double(preset.lowFrequencyAnchors_Hz(:));

low = anchors_Hz(anchors_Hz >= fmin_Hz & ...
    anchors_Hz <= min(transition_Hz, fmax_Hz));

if fmax_Hz > transition_Hz
    highStart_Hz = max(transition_Hz, fmin_Hz);
    high = (highStart_Hz:step_Hz:fmax_Hz).';
else
    high = zeros(0,1);
end

frequency_Hz = unique([fmin_Hz; low; high; fmax_Hz], 'sorted');
frequency_Hz = validateFrequencyVector(frequency_Hz, 'frequencySolve_Hz');
end

function metadata = makeMetadata(frequency_Hz, source, preset, ...
    configuredStep_Hz, lowFrequencyPolicy, transitionFrequency_Hz)
metadata = struct();
metadata.source = string(source);
metadata.pointCount = numel(frequency_Hz);
metadata.fmin_Hz = frequency_Hz(1);
metadata.fmax_Hz = frequency_Hz(end);
metadata.minStep_Hz = minimumStep(frequency_Hz);
metadata.medianStep_Hz = medianStep(frequency_Hz);
metadata.maxStep_Hz = maximumStep(frequency_Hz);
metadata.presetName = string(preset.name);
metadata.configuredStep_Hz = configuredStep_Hz;
metadata.lowFrequencyPolicy = string(lowFrequencyPolicy);
metadata.transitionFrequency_Hz = transitionFrequency_Hz;
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

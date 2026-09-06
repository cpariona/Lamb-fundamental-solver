function [frequencySolve_Hz, metadata] = mrlfeBuildFitFrequencyGrid(frequencyRequested_Hz, forwardModel)
%MRLFEBUILDFITFREQUENCYGRID Build the internal grid used by fit evaluations.
%
% The grid always preserves requested experimental frequencies and adds only
% the continuation points needed for stable tracking. It is intended for the
% repeated forward evaluations performed by the optimizer.

frequencyRequested_Hz = unique(frequencyRequested_Hz(:), 'sorted');
if isempty(frequencyRequested_Hz) || any(~isfinite(frequencyRequested_Hz)) || ...
        any(frequencyRequested_Hz <= 0)
    error('mrlfe:InvalidFitFrequency', ...
        'Fit frequencies must contain positive finite values.');
end

if nargin < 2 || isempty(forwardModel)
    forwardModel = struct();
end
minimumPointCount = localPositiveInteger(forwardModel, 'minimumPointCount', 12);
maximumPointCount = localPositiveInteger(forwardModel, 'maximumPointCount', 40);
maximumStep_Hz = localPositiveScalar(forwardModel, 'maximumStep_Hz', 250);
if maximumPointCount < minimumPointCount
    error('mrlfe:InvalidFitGridPolicy', ...
        'forwardModel.maximumPointCount must be at least minimumPointCount.');
end

if numel(frequencyRequested_Hz) == 1
    f0 = frequencyRequested_Hz(1);
    halfWidth = max(0.05 * f0, 1);
    fmin = max(eps(f0), f0 - halfWidth);
    fmax = f0 + halfWidth;
else
    fmin = frequencyRequested_Hz(1);
    fmax = frequencyRequested_Hz(end);
end

% First enforce the maximum continuation step.
continuation = fmin;
for i = 1:max(1, numel(frequencyRequested_Hz) - 1)
    if numel(frequencyRequested_Hz) == 1
        left = fmin;
        right = fmax;
    else
        left = frequencyRequested_Hz(i);
        right = frequencyRequested_Hz(i + 1);
    end
    segmentCount = max(1, ceil((right - left) / maximumStep_Hz));
    segment = linspace(left, right, segmentCount + 1).';
    continuation = [continuation; segment]; %#ok<AGROW>
end

frequencySolve_Hz = unique([frequencyRequested_Hz; continuation; fmin; fmax], 'sorted');

% Enforce the minimum count with uniformly distributed continuation points.
if numel(frequencySolve_Hz) < minimumPointCount
    fillGrid = linspace(fmin, fmax, minimumPointCount).';
    frequencySolve_Hz = unique([frequencySolve_Hz; fillGrid], 'sorted');
end

% Preserve every requested frequency. Only auxiliary points may be reduced.
if numel(frequencySolve_Hz) > maximumPointCount && ...
        numel(frequencyRequested_Hz) < maximumPointCount
    auxiliary = setdiff(frequencySolve_Hz, frequencyRequested_Hz, 'stable');
    keepAuxiliary = maximumPointCount - numel(frequencyRequested_Hz);
    if keepAuxiliary > 0 && ~isempty(auxiliary)
        idx = unique(round(linspace(1, numel(auxiliary), keepAuxiliary)));
        auxiliary = auxiliary(idx);
    else
        auxiliary = zeros(0, 1);
    end
    frequencySolve_Hz = unique([frequencyRequested_Hz; auxiliary; fmin; fmax], 'sorted');
end

metadata = struct();
metadata.gridPolicy = "fitOptimized";
metadata.requestedPointCount = numel(frequencyRequested_Hz);
metadata.solvePointCount = numel(frequencySolve_Hz);
metadata.minimumPointCount = minimumPointCount;
metadata.maximumPointCount = maximumPointCount;
metadata.maximumStep_Hz = maximumStep_Hz;
metadata.fmin_Hz = fmin;
metadata.fmax_Hz = fmax;
metadata.preservedRequestedFrequencies = all(ismember(frequencyRequested_Hz, frequencySolve_Hz));
end

function value = localPositiveInteger(s, name, defaultValue)
value = localPositiveScalar(s, name, defaultValue);
value = round(value);
if value < 2
    error('mrlfe:InvalidFitGridPolicy', '%s must be an integer of at least 2.', name);
end
end

function value = localPositiveScalar(s, name, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
end
if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
    error('mrlfe:InvalidFitGridPolicy', '%s must be a positive finite scalar.', name);
end
end

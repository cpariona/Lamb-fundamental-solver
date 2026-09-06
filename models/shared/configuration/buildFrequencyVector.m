function frequency = buildFrequencyVector(params)
%BUILDFREQUENCYVECTOR Build a canonical frequency vector from grid parameters.
%
% Supported spacing modes: hybrid, logspace, linspace, explicit.

if isfield(params, 'frequencySpacing')
    spacing = lower(string(params.frequencySpacing));
else
    spacing = "hybrid";
end

if spacing == "explicit"
    frequency = resolveExplicitFrequencyVector(params);
    return;
end

nPoints = resolveFrequencyPointCount(params);

switch spacing
    case "logspace"
        frequency = logspace(log10(params.fmin), log10(params.fmax), nPoints);

    case "linspace"
        frequency = linspace(params.fmin, params.fmax, nPoints);

    case "hybrid"
        frequency = buildHybridFrequencyVector(params.fmin, params.fmax, nPoints);

    otherwise
        error('Unknown frequency spacing. Use hybrid, logspace, linspace, or explicit.');
end
end

function frequency = resolveExplicitFrequencyVector(params)
if ~isfield(params, 'frequencyVector_Hz') || isempty(params.frequencyVector_Hz)
    error('frequencyVector_Hz is required when frequencySpacing is explicit.');
end
frequency = params.frequencyVector_Hz(:).';
if ~isnumeric(frequency) || any(~isfinite(frequency)) || any(frequency <= 0)
    error('frequencyVector_Hz must contain finite positive numeric values.');
end
if numel(frequency) < 2 || any(diff(frequency) <= 0)
    error('frequencyVector_Hz must contain at least two strictly ascending values.');
end
end

function nPoints = resolveFrequencyPointCount(params)
if ~isfield(params, 'numFrequencyPoints')
    nPoints = estimateAutomaticPointCount(params.fmin, params.fmax);
    return;
end

if ischar(params.numFrequencyPoints) || isstring(params.numFrequencyPoints)
    value = lower(string(params.numFrequencyPoints));
    if value == "auto"
        nPoints = estimateAutomaticPointCount(params.fmin, params.fmax);
    else
        nPoints = str2double(value);
    end
else
    nPoints = params.numFrequencyPoints;
end

if ~isfinite(nPoints) || nPoints < 10
    error('numFrequencyPoints must be numeric >= 10 or "auto".');
end

nPoints = round(nPoints);
end

function nPoints = estimateAutomaticPointCount(fmin, fmax)
rangeRatio = fmax / fmin;
decades = log10(rangeRatio);
spanKHz = (fmax - fmin) / 1000;

nByDecades = 180 * max(decades, 1);
nByLinearSpan = 2.0 * spanKHz;

nPoints = ceil(max([250, nByDecades, nByLinearSpan]));
nPoints = min(max(nPoints, 250), 2500);
end

function frequency = buildHybridFrequencyVector(fmin, fmax, nPoints)
if nPoints < 3 || fmax <= fmin
    frequency = linspace(fmin, fmax, nPoints);
    return;
end

fTransition = sqrt(fmin * fmax);
lowFraction = 0.40;
nLow = max(3, round(lowFraction * nPoints));
nHigh = max(3, nPoints - nLow + 1);

fLow = logspace(log10(fmin), log10(fTransition), nLow);
fHigh = linspace(fTransition, fmax, nHigh);

frequency = unique([fLow, fHigh(2:end)], 'stable');

if numel(frequency) < nPoints
    extra = linspace(frequency(end), fmax, nPoints - numel(frequency) + 1);
    frequency = unique([frequency, extra(2:end)], 'stable');
elseif numel(frequency) > nPoints
    frequency = frequency(1:nPoints);
    frequency(end) = fmax;
end
end

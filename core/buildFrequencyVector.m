function frequency = buildFrequencyVector(params)
% Build frequency vector according to selected spacing.
%
% The GUI uses the hybrid spacing internally. linspace and logspace remain
% available for scripts and development comparisons.

if isfield(params, 'frequencySpacing')
    spacing = lower(string(params.frequencySpacing));
else
    spacing = "hybrid";
end

switch spacing
    case "logspace"
        frequency = logspace(log10(params.fmin), log10(params.fmax), params.numFrequencyPoints);

    case "linspace"
        frequency = linspace(params.fmin, params.fmax, params.numFrequencyPoints);

    case "hybrid"
        frequency = buildHybridFrequencyVector(params.fmin, params.fmax, params.numFrequencyPoints);

    otherwise
        error('Unknown frequency spacing. Use hybrid, logspace, or linspace.');
end
end

function frequency = buildHybridFrequencyVector(fmin, fmax, nPoints)
% Use logarithmic sampling at low frequencies and linear sampling afterward.

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

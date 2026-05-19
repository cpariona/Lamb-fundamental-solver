function frequency = buildFrequencyVector(params)
% Build frequency vector according to selected spacing.

switch lower(string(params.frequencySpacing))
    case "logspace"
        frequency = logspace(log10(params.fmin), log10(params.fmax), params.numFrequencyPoints);
    case "linspace"
        frequency = linspace(params.fmin, params.fmax, params.numFrequencyPoints);
    otherwise
        error('Unknown frequency spacing.');
end
end

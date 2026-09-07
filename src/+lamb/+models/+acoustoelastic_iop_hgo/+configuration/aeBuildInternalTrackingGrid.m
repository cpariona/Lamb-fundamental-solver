function trackingFrequency = aeBuildInternalTrackingGrid(requestedFrequency, options)
%AEBUILDINTERNALTRACKINGGRID Build the maintained hidden atlas frequency grid.

if nargin < 2
    options = [];
end
options = lamb.models.acoustoelastic_iop_hgo.configuration.aeResolveConfiguration(options);

requestedFrequency = unique(requestedFrequency(isfinite(requestedFrequency) & requestedFrequency > 0), 'stable');
requestedFrequency = sort(requestedFrequency(:).');
if isempty(requestedFrequency)
    trackingFrequency = requestedFrequency;
    return;
end

fMax = max(requestedFrequency);
initMin = options.atlasInitializationMinFrequency_Hz;
initMin = max(initMin, eps);
initMin = min(initMin, fMax);

nInit = round(options.atlasInitializationNumFrequencyPoints);
nInit = max(nInit, 2);
initFrequency = logspace(log10(initMin), log10(fMax), nInit);
trackingFrequency = unique([initFrequency(:); requestedFrequency(:)], 'sorted').';
end

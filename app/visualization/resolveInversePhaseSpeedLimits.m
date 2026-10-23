function [limits, evidence] = resolveInversePhaseSpeedLimits(values, varargin)
%RESOLVEINVERSEPHASESPEEDLIMITS Display-only complete, robust or shared Cp scale.
%   VALUES are original speeds in m/s from an explicitly reviewed population.
%   Mode="complete" (default) includes all finite values. Mode="robust" uses
%   an upper median/MAD screen (modified Z <= 3.5) only to choose the scale.
%   Limits=[low high] uses an explicit shared scale, without rescreening it.
%   Never returns a fitting mask. EVIDENCE counts nonfinite and clipped values.
p = inputParser;
addParameter(p, 'Mode', "complete", @(x) any(string(x)==["complete","robust"]));
addParameter(p, 'Limits', [], @(x) isempty(x) || ...
    (isnumeric(x) && isreal(x) && numel(x)==2 && all(isfinite(x)) && x(2)>x(1)));
parse(p, varargin{:});
validateattributes(values, {'double'}, {'real'});
if ~isempty(values), validateattributes(values,{'double'},{'vector'}); end
values = values(:);
finite = values(isfinite(values));
if ~isempty(p.Results.Limits)
    limits = reshape(double(p.Results.Limits),1,2);
    source = "explicit_shared";
else
    source = string(p.Results.Mode);
    scaleValues = finite;
    if source=="robust"
        positive = finite(finite>0);
        if ~isempty(positive)
            center = median(positive);
            spread = median(abs(positive-center));
            if spread>0
                positive = positive(0.674489750196082*(positive-center)/spread<=3.5);
            end
            scaleValues = [min([0;finite]);positive];
        end
    end
    if isempty(scaleValues)
        limits = [0 1];
    else
        lower = min([0;scaleValues]); upper = max(scaleValues);
        padding = max(0.1*(upper-lower),0.1*max(abs([lower,upper])));
        if padding==0, padding=1; end
        limits = [lower-padding*(lower<0),upper+padding];
        if any(~isfinite(limits))
            limits = [min(finite),max(finite)];
        end
    end
end
outside = isfinite(values) & (values<limits(1) | values>limits(2));
evidence = struct('source',source,'limits_mps',limits,'populationCount',numel(values), ...
    'nonfiniteCount',nnz(~isfinite(values)),'outsideCount',nnz(outside), ...
    'maximumOutside_mps',NaN,'minimumOutside_mps',NaN);
if any(outside)
    evidence.maximumOutside_mps = max(values(outside));
    evidence.minimumOutside_mps = min(values(outside));
end
end

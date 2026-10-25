function [limits, evidence] = resolveInversePhaseSpeedLimits(values, varargin)
%RESOLVEINVERSEPHASESPEEDLIMITS Display-only complete, robust or shared Cp scale.
%   VALUES are original values in the units declared by Quantity.
%   Mode="complete" (default) includes all finite values. Mode="robust" uses
%   an upper median/MAD screen (modified Z <= 3.5) only to choose the scale.
%   Limits=[low high] uses an explicit shared scale, without rescreening it.
%   A cell vector holds comparable cases: resolve each case, then take their
%   envelope. Dense acquisitions cannot outweigh sparse cases in this scale.
%   Quantity="regression" or "residual" resolves Pa-valued panel limits.
%   Quantity="speed_residual" reuses the residual policy for native m/s values.
%   Residuals use a two-sided median/MAD display screen, retaining zero.
%   Never returns a fitting mask. EVIDENCE counts nonfinite and clipped values.
p = inputParser;
addParameter(p, 'Mode', "complete", @(x) any(string(x)==["complete","robust"]));
addParameter(p, 'Quantity', "phase_speed", @(x) any(string(x)==["phase_speed","regression","residual","speed_residual"]));
addParameter(p, 'Limits', [], @(x) isempty(x) || ...
    (isnumeric(x) && isreal(x) && numel(x)==2 && all(isfinite(x)) && x(2)>x(1)));
parse(p, varargin{:});
isResidual = any(p.Results.Quantity==["residual","speed_residual"]);
if iscell(values)
    validateattributes(values,{'cell'},{'vector','nonempty'});
    caseLimits=zeros(numel(values),2);
    for k=1:numel(values)
        caseLimits(k,:)=resolveInversePhaseSpeedLimits(values{k},varargin{:});
    end
    limits=[min(caseLimits(:,1)),max(caseLimits(:,2))];
    population=cellfun(@(x)x(:),values,'UniformOutput',false);
    [~,evidence]=resolveInversePhaseSpeedLimits(vertcat(population{:}),'Limits',limits, ...
        'Quantity',p.Results.Quantity);
    evidence.source="case_envelope_"+string(p.Results.Mode);
    if ~isempty(p.Results.Limits),evidence.source="explicit_shared";end
    evidence.caseLimits=caseLimits;
    if p.Results.Quantity=="phase_speed",evidence.caseLimits_mps=caseLimits;end
    return
end
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
        if isResidual
            center=median(finite);spread=median(abs(finite-center));
            if spread>0
                scaleValues=finite(0.674489750196082*abs(finite-center)/spread<=3.5);
            end
        else
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
    end
    if isempty(scaleValues)
        limits = [0 1];
    else
        lower = min([0;scaleValues]); upper = max(scaleValues);
        if isResidual,upper=max([0;scaleValues]);end
        padding = max(0.1*(upper-lower),0.1*max(abs([lower,upper])));
        if padding==0, padding=1; end
        limits = [lower-padding*(lower<0),upper+padding];
        if any(~isfinite(limits))
            limits = [min(finite),max(finite)];
        end
        if source=="robust"
            step=10^floor(log10(diff(limits)/5));
            if isfinite(step) && step>0
                limits=[floor(limits(1)/step),ceil(limits(2)/step)]*step;
            end
        end
    end
end
outside = isfinite(values) & (values<limits(1) | values>limits(2));
evidence = struct('source',source,'limits_mps',limits,'populationCount',numel(values), ...
    'nonfiniteCount',nnz(~isfinite(values)),'outsideCount',nnz(outside), ...
    'maximumOutside_mps',NaN,'minimumOutside_mps',NaN);
evidence.limits=limits;evidence.quantity=string(p.Results.Quantity);evidence.unit="m/s";
if p.Results.Quantity~="phase_speed"
    evidence=rmfield(evidence,{'limits_mps','maximumOutside_mps','minimumOutside_mps'});
    if p.Results.Quantity~="speed_residual",evidence.unit="Pa";end
end
evidence.maximumOutside=NaN;evidence.minimumOutside=NaN;
if any(outside)
    evidence.maximumOutside=max(values(outside));evidence.minimumOutside=min(values(outside));
    if p.Results.Quantity=="phase_speed"
        evidence.maximumOutside_mps=evidence.maximumOutside;
        evidence.minimumOutside_mps=evidence.minimumOutside;
    end
end
end

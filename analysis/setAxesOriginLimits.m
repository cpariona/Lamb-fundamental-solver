function setAxesOriginLimits(ax, varargin)
%SETAXESORIGINLIMITS Force plotted axes to start at the origin.
%
% The upper limits are taken from the current axes limits, so this helper can
% be called after plotting without needing access to the original data.

p = inputParser();
addParameter(p, 'IncludeZ', false, @(x)islogical(x) || isnumeric(x));
parse(p, varargin{:});

setAxisLimitFromOrigin(ax, 'x');
setAxisLimitFromOrigin(ax, 'y');

if p.Results.IncludeZ
    setAxisLimitFromOrigin(ax, 'z');
end
end

function setAxisLimitFromOrigin(ax, axisName)
switch lower(axisName)
    case 'x'
        lim = xlim(ax);
        upper = lim(2);
        if ~isfinite(upper) || upper <= 0
            upper = 1;
        end
        xlim(ax, [0 upper]);
    case 'y'
        lim = ylim(ax);
        upper = lim(2);
        if ~isfinite(upper) || upper <= 0
            upper = 1;
        end
        ylim(ax, [0 upper]);
    case 'z'
        lim = zlim(ax);
        upper = lim(2);
        if ~isfinite(upper) || upper <= 0
            upper = 1;
        end
        zlim(ax, [0 upper]);
end
end

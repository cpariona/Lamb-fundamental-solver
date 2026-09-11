function lineHandle = guiPlotSolverCurve(ax, x, Cp, validMask, varargin)
%GUIPLOTSOLVERCURVE Render a Main GUI curve without joining invalid samples.
x = x(:);
Cp = Cp(:);
valid = logical(validMask(:)) & isfinite(x) & isfinite(Cp);
Cp(~valid) = nan;
lineHandle = plot(ax, x, Cp, varargin{:});
end

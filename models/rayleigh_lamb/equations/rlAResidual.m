function varargout = rlAResidual(varargin)
%RLARESIDUAL Author-neutral wrapper for rayleighLambAResidual.
[varargout{1:nargout}] = rayleighLambAResidual(varargin{:});
end

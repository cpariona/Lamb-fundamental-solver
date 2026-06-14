function varargout = rlSResidual(varargin)
%RLSRESIDUAL Author-neutral wrapper for rayleighLambSResidual.
[varargout{1:nargout}] = rayleighLambSResidual(varargin{:});
end

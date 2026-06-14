function varargout = rayleighLambAResidual(varargin)
%RAYLEIGHLAMBARESIDUAL Compatibility wrapper for rlAResidual.
[varargout{1:nargout}] = rlAResidual(varargin{:});
end

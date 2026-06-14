function varargout = rayleighLambSResidual(varargin)
%RAYLEIGHLAMBSRESIDUAL Compatibility wrapper for rlSResidual.
[varargout{1:nargout}] = rlSResidual(varargin{:});
end

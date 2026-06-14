function varargout = rayleighLambSResidual(varargin)
%RAYLEIGHLAMBSRESIDUAL Compatibility wrapper for rlSResidual.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlSResidual under models/rayleigh_lamb/. New maintained
%   code should call rlSResidual directly. This wrapper is retained to preserve
%   old scripts and notebooks that call rayleighLambSResidual.
[varargout{1:nargout}] = rlSResidual(varargin{:});
end

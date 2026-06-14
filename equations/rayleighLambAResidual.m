function varargout = rayleighLambAResidual(varargin)
%RAYLEIGHLAMBARESIDUAL Compatibility wrapper for rlAResidual.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlAResidual under models/rayleigh_lamb/. New maintained
%   code should call rlAResidual directly. This wrapper is retained to preserve
%   old scripts and notebooks that call rayleighLambAResidual.
[varargout{1:nargout}] = rlAResidual(varargin{:});
end

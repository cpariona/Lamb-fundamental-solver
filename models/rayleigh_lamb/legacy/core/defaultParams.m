function varargout = defaultParams(varargin)
%DEFAULTPARAMS Compatibility wrapper for rlDefaultParams.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlDefaultParams under models/rayleigh_lamb/. New maintained
%   code should call rlDefaultParams directly. This wrapper is retained to preserve
%   old scripts and notebooks that call defaultParams.
[varargout{1:nargout}] = rlDefaultParams(varargin{:});
end

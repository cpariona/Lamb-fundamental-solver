function varargout = defaultOptions(varargin)
%DEFAULTOPTIONS Compatibility wrapper for rlDefaultOptions.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlDefaultOptions under models/rayleigh_lamb/. New maintained
%   code should call rlDefaultOptions directly. This wrapper is retained to preserve
%   old scripts and notebooks that call defaultOptions.
[varargout{1:nargout}] = rlDefaultOptions(varargin{:});
end

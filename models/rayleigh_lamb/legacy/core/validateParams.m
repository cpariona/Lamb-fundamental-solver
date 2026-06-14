function varargout = validateParams(varargin)
%VALIDATEPARAMS Compatibility wrapper for rlValidateParams.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlValidateParams under models/rayleigh_lamb/. New maintained
%   code should call rlValidateParams directly. This wrapper is retained to preserve
%   old scripts and notebooks that call validateParams.
[varargout{1:nargout}] = rlValidateParams(varargin{:});
end

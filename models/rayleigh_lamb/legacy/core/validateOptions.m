function varargout = validateOptions(varargin)
%VALIDATEOPTIONS Compatibility wrapper for rlValidateOptions.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlValidateOptions under models/rayleigh_lamb/. New maintained
%   code should call rlValidateOptions directly. This wrapper is retained to preserve
%   old scripts and notebooks that call validateOptions.
[varargout{1:nargout}] = rlValidateOptions(varargin{:});
end

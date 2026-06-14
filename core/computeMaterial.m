function varargout = computeMaterial(varargin)
%COMPUTEMATERIAL Compatibility wrapper for rlComputeMaterial.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlComputeMaterial under models/rayleigh_lamb/. New maintained
%   code should call rlComputeMaterial directly. This wrapper is retained to preserve
%   old scripts and notebooks that call computeMaterial.
[varargout{1:nargout}] = rlComputeMaterial(varargin{:});
end

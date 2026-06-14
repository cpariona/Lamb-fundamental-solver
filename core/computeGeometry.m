function varargout = computeGeometry(varargin)
%COMPUTEGEOMETRY Compatibility wrapper for rlComputeGeometry.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlComputeGeometry under models/rayleigh_lamb/. New maintained
%   code should call rlComputeGeometry directly. This wrapper is retained to preserve
%   old scripts and notebooks that call computeGeometry.
[varargout{1:nargout}] = rlComputeGeometry(varargin{:});
end

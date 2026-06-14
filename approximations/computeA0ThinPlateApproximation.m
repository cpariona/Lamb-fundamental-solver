function varargout = computeA0ThinPlateApproximation(varargin)
%COMPUTEA0THINPLATEAPPROXIMATION Compatibility wrapper for rlComputeA0ThinPlateApproximation.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlComputeA0ThinPlateApproximation under models/rayleigh_lamb/. New maintained
%   code should call rlComputeA0ThinPlateApproximation directly. This wrapper is retained to preserve
%   old scripts and notebooks that call computeA0ThinPlateApproximation.
[varargout{1:nargout}] = rlComputeA0ThinPlateApproximation(varargin{:});
end

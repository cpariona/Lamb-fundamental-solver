function varargout = computeAnalyticalApproximations(varargin)
%COMPUTEANALYTICALAPPROXIMATIONS Compatibility wrapper for rlComputeAnalyticalApproximations.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlComputeAnalyticalApproximations under models/rayleigh_lamb/. New maintained
%   code should call rlComputeAnalyticalApproximations directly. This wrapper is retained to preserve
%   old scripts and notebooks that call computeAnalyticalApproximations.
[varargout{1:nargout}] = rlComputeAnalyticalApproximations(varargin{:});
end

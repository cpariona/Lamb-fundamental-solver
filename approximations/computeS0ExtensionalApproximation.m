function varargout = computeS0ExtensionalApproximation(varargin)
%COMPUTES0EXTENSIONALAPPROXIMATION Compatibility wrapper for rlComputeS0ExtensionalApproximation.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlComputeS0ExtensionalApproximation under models/rayleigh_lamb/. New maintained
%   code should call rlComputeS0ExtensionalApproximation directly. This wrapper is retained to preserve
%   old scripts and notebooks that call computeS0ExtensionalApproximation.
[varargout{1:nargout}] = rlComputeS0ExtensionalApproximation(varargin{:});
end

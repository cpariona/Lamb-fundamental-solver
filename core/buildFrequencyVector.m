function varargout = buildFrequencyVector(varargin)
%BUILDFREQUENCYVECTOR Compatibility wrapper for rlBuildFrequencyVector.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlBuildFrequencyVector under models/rayleigh_lamb/. New maintained
%   code should call rlBuildFrequencyVector directly. This wrapper is retained to preserve
%   old scripts and notebooks that call buildFrequencyVector.
[varargout{1:nargout}] = rlBuildFrequencyVector(varargin{:});
end

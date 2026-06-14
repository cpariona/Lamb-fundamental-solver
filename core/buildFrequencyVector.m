function varargout = buildFrequencyVector(varargin)
%BUILDFREQUENCYVECTOR Compatibility wrapper for rlBuildFrequencyVector.
[varargout{1:nargout}] = rlBuildFrequencyVector(varargin{:});
end

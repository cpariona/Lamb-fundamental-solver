function varargout = computeGeometry(varargin)
%COMPUTEGEOMETRY Compatibility wrapper for rlComputeGeometry.
[varargout{1:nargout}] = rlComputeGeometry(varargin{:});
end

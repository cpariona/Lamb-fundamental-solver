function varargout = computeMaterial(varargin)
%COMPUTEMATERIAL Compatibility wrapper for rlComputeMaterial.
[varargout{1:nargout}] = rlComputeMaterial(varargin{:});
end

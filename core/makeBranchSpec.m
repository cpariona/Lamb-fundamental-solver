function varargout = makeBranchSpec(varargin)
%MAKEBRANCHSPEC Compatibility wrapper for rlMakeBranchSpec.
[varargout{1:nargout}] = rlMakeBranchSpec(varargin{:});
end

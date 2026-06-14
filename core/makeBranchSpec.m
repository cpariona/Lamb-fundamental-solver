function varargout = makeBranchSpec(varargin)
%MAKEBRANCHSPEC Compatibility wrapper for rlMakeBranchSpec.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlMakeBranchSpec under models/rayleigh_lamb/. New maintained
%   code should call rlMakeBranchSpec directly. This wrapper is retained to preserve
%   old scripts and notebooks that call makeBranchSpec.
[varargout{1:nargout}] = rlMakeBranchSpec(varargin{:});
end

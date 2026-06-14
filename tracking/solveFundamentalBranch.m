function varargout = solveFundamentalBranch(varargin)
%SOLVEFUNDAMENTALBRANCH Compatibility wrapper for rlSolveFundamentalBranch.
[varargout{1:nargout}] = rlSolveFundamentalBranch(varargin{:});
end

function varargout = solveFundamentalBranch(varargin)
%SOLVEFUNDAMENTALBRANCH Compatibility wrapper for rlSolveFundamentalBranch.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlSolveFundamentalBranch under models/rayleigh_lamb/. New maintained
%   code should call rlSolveFundamentalBranch directly. This wrapper is retained to preserve
%   old scripts and notebooks that call solveFundamentalBranch.
[varargout{1:nargout}] = rlSolveFundamentalBranch(varargin{:});
end

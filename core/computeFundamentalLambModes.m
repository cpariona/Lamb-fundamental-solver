function varargout = computeFundamentalLambModes(varargin)
%COMPUTEFUNDAMENTALLAMBMODES Compatibility wrapper for rlComputeFundamentalLambModes.
%   This file is a legacy compatibility wrapper. The primary
%   implementation is rlComputeFundamentalLambModes under models/rayleigh_lamb/. New maintained
%   code should call rlComputeFundamentalLambModes directly. This wrapper is retained to preserve
%   old scripts and notebooks that call computeFundamentalLambModes.
[varargout{1:nargout}] = rlComputeFundamentalLambModes(varargin{:});
end

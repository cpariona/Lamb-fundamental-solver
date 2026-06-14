function varargout = defaultParams(varargin)
%DEFAULTPARAMS Compatibility wrapper for rlDefaultParams.
[varargout{1:nargout}] = rlDefaultParams(varargin{:});
end

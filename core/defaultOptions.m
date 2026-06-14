function varargout = defaultOptions(varargin)
%DEFAULTOPTIONS Compatibility wrapper for rlDefaultOptions.
[varargout{1:nargout}] = rlDefaultOptions(varargin{:});
end

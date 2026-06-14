function varargout = validateOptions(varargin)
%VALIDATEOPTIONS Compatibility wrapper for rlValidateOptions.
[varargout{1:nargout}] = rlValidateOptions(varargin{:});
end

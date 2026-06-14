function varargout = rlValidateOptions(varargin)
%RLVALIDATEOPTIONS Author-neutral wrapper for validateOptions.
[varargout{1:nargout}] = validateOptions(varargin{:});
end

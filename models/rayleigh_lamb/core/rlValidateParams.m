function varargout = rlValidateParams(varargin)
%RLVALIDATEPARAMS Author-neutral wrapper for validateParams.
[varargout{1:nargout}] = validateParams(varargin{:});
end

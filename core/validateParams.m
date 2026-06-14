function varargout = validateParams(varargin)
%VALIDATEPARAMS Compatibility wrapper for rlValidateParams.
[varargout{1:nargout}] = rlValidateParams(varargin{:});
end

function varargout = buildMatrix_Li2024_Acoustoelastic(varargin)
%BUILDMATRIX_LI2024_ACOUSTOELASTIC Compatibility wrapper for buildAcoustoelasticMatrix.
%
% Use buildAcoustoelasticMatrix for new author-neutral acoustoelastic code.

[varargout{1:nargout}] = buildAcoustoelasticMatrix(varargin{:});
end

function result = solveDispersionAtlasBranch_Li2024_Acoustoelastic(params, options)
%SOLVEDISPERSIONATLASBRANCH_LI2024_ACOUSTOELASTIC Compatibility wrapper.
%
% Forward legacy Li2024 atlas-branch calls to the author-neutral generic
% Acoustoelastic atlas-branch solver.

if nargin < 2
    result = solveAcoustoelasticAtlasBranch(params);
else
    result = solveAcoustoelasticAtlasBranch(params, options);
end
end

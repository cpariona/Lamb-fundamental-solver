function result = solveAcoustoelasticIOPHGOBranch(params, options)
%SOLVEACOUSTOELASTICIOPHGOBRANCH Solve the acoustoelastic IOP/HGO atlas branch.
%
% This is the maintained author-neutral wrapper for the IOP/HGO
% acoustoelastic branch solver. It preserves compatibility by delegating to
% the original Li2024 implementation function.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2, rho, rhoF, fluidBulkModulus, frequency

if nargin < 2
    options = [];
end

result = solveDispersionIOPHGOAtlasBranch_Li2024(params, options);
end

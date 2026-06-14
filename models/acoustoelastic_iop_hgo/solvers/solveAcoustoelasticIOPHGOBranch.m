function result = solveAcoustoelasticIOPHGOBranch(params, options)
%SOLVEACOUSTOELASTICIOPHGOBRANCH Solve the acoustoelastic IOP/HGO atlas branch.
%
% This is the recommended public convenience entrypoint for the IOP/HGO
% acoustoelastic branch solver. It delegates to the author-neutral atlas
% branch implementation.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2, rho, rhoF, fluidBulkModulus, frequency

if nargin < 2
    options = [];
end

result = solveAcoustoelasticIOPHGOAtlasBranch(params, options);
end

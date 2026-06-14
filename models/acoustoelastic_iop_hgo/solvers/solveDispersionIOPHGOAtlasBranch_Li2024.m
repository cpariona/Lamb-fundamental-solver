function result = solveDispersionIOPHGOAtlasBranch_Li2024(params, options)
%SOLVEDISPERSIONIOPHGOATLASBRANCH_LI2024 Compatibility wrapper for acoustoelastic IOP/HGO atlas branch solver.
%
% Prefer solveAcoustoelasticIOPHGOAtlasBranch for new code.

if nargin < 2
    options = [];
end

result = solveAcoustoelasticIOPHGOAtlasBranch(params, options);
end

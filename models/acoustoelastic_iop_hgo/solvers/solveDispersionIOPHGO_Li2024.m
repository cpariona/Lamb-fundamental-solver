function result = solveDispersionIOPHGO_Li2024(params, options)
%SOLVEDISPERSIONIOPHGO_LI2024 Compatibility wrapper for direct IOP/HGO dispersion.
%
% Prefer solveAcoustoelasticIOPHGODispersion for new code.

if nargin < 2
    result = solveAcoustoelasticIOPHGODispersion(params);
else
    result = solveAcoustoelasticIOPHGODispersion(params, options);
end
end

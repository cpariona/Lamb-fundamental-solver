function result = solveAcoustoelasticIOPHGOAtlasBranch(params, options)
%SOLVEACOUSTOELASTICIOPHGOATLASBRANCH Solve atlas branch from acoustoelastic IOP/HGO parameters.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2, rho, rhoF, fluidBulkModulus, frequency
%
% This wrapper computes alpha, beta, gamma from the IOP/HGO constitutive block
% and then calls solveAcoustoelasticAtlasBranch.

if nargin < 2 || isempty(options)
    options = defaultAcoustoelasticIOPHGOOptions();
end

requiredFields = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', 'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required acoustoelastic IOP/HGO atlas parameter: %s', requiredFields{i});
    end
end

[alpha, beta, gamma, state] = computeABGFromIOPHGO_Li2024( ...
    params.IOP, params.R, params.thickness, params.mu, params.k1, params.k2);

directParams = struct();
directParams.alpha = alpha;
directParams.beta = beta;
directParams.gamma = gamma;
directParams.thickness = params.thickness;
directParams.rho = params.rho;
directParams.rhoF = params.rhoF;
directParams.fluidBulkModulus = params.fluidBulkModulus;
directParams.frequency = params.frequency;

result = solveAcoustoelasticAtlasBranch(directParams, options);
result.constitutiveState = state;
result.directParams = directParams;
end

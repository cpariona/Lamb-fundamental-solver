function result = solveDispersionIOPHGO_Li2024(params, options)
%SOLVEDISPERSIONIOPHGO_LI2024 Solve Li 2024 dispersion from IOP/HGO parameters.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2
%   rho, rhoF, fluidBulkModulus, frequency
%
% This wrapper computes alpha, beta, gamma from the constitutive block and
% then calls solveDispersion_Li2024_Acoustoelastic. By default, it is intended
% for the A0 corrected/backward workflow while the direct solver is being
% validated.

if nargin < 2 || isempty(options)
    options = defaultLi2024AcoustoelasticOptions();
end

requiredFields = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', 'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required Li2024 IOP/HGO parameter: %s', requiredFields{i});
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

if isfield(params, 'cGrid')
    directParams.cGrid = params.cGrid;
end

result = solveDispersion_Li2024_Acoustoelastic(directParams, options);
result.constitutiveState = state;
result.directParams = directParams;
end

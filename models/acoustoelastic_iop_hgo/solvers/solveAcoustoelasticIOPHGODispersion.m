function result = solveAcoustoelasticIOPHGODispersion(params, options)
%SOLVEACOUSTOELASTICIOPHGODISPERSION Solve direct dispersion from IOP/HGO parameters.
%
% Required params fields, SI units:
%   IOP, R, thickness, mu, k1, k2
%   rho, rhoF, fluidBulkModulus, frequency
%
% This wrapper computes alpha, beta, gamma from the constitutive block and
% then calls solveAcoustoelasticDispersion. By default, it is intended
% for the A0 corrected/backward workflow while the direct solver is being
% validated.

if nargin < 2
    options = [];
end
options = aeDefaultDiagnosticOptions(options);

requiredFields = {'IOP', 'R', 'thickness', 'mu', 'k1', 'k2', 'rho', 'rhoF', 'fluidBulkModulus', 'frequency'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required Acoustoelastic IOP/HGO parameter: %s', requiredFields{i});
    end
end

[alpha, beta, gamma, state] = computeAcoustoelasticABGFromIOPHGO( ...
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

result = solveAcoustoelasticDispersion(directParams, options);
result.constitutiveState = state;
result.directParams = directParams;
end

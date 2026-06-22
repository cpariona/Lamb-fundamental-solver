function material = rlComputeMaterial(params)
% Compute isotropic elastic material quantities based on selected material model.
%
% Maintained user-facing soft-material workflows should use ShearPoisson:
%   params.mu, params.nu, params.rho
%
% LameParameters is retained as an explicit internal/diagnostic alternative.

rho = params.rho;
modelType = string(params.modelType);

switch modelType
    case "ShearPoisson"
        material = elasticFromMuNu(params.mu, params.nu, rho);

    case "LameParameters"
        material = elasticFromLame(params.lambda, params.mu, rho);

    otherwise
        error('Unknown material model type: %s.', modelType);
end

material.modelType = modelType;
end

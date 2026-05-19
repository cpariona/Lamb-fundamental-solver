function material = computeMaterial(params)
% Compute E, nu, lambda, mu, CL and CT based on selected material model.

rho = params.rho;
modelType = string(params.modelType);

switch modelType
    case "YoungPoissonFixedCL"
        E = params.E;
        nu = params.nu;
        CL = params.CL;

        mu = E / (2 * (1 + nu));
        lambda = E * nu / ((1 + nu) * (1 - 2 * nu));
        CT = sqrt(mu / rho);

    case "LameParameters"
        lambda = params.lambda;
        mu = params.mu;

        E = mu * (3 * lambda + 2 * mu) / (lambda + mu);
        nu = lambda / (2 * (lambda + mu));

        CL = sqrt((lambda + 2 * mu) / rho);
        CT = sqrt(mu / rho);

    otherwise
        error('Unknown material model type.');
end

material = struct();
material.modelType = modelType;
material.rho = rho;
material.E = E;
material.nu = nu;
material.lambda = lambda;
material.mu = mu;
material.CL = CL;
material.CT = CT;
end

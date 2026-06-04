function validateParams(params)
% Validate physical and frequency parameters before running the solver.

requiredFields = {'modelType', 'rho', 'thickness', 'fmin', 'fmax', ...
    'numFrequencyPoints'};
for i = 1:numel(requiredFields)
    if ~isfield(params, requiredFields{i})
        error('Missing required parameter field: %s.', requiredFields{i});
    end
end

if params.rho <= 0
    error('rho must be positive.');
end

if params.thickness <= 0
    error('thickness must be positive.');
end

if params.fmin <= 0 || params.fmax <= 0
    error('fmin and fmax must be positive.');
end

if params.fmax <= params.fmin
    error('fmax must be larger than fmin.');
end

if params.numFrequencyPoints < 10
    error('numFrequencyPoints must be at least 10.');
end

if isfield(params, 'frequencySpacing')
    spacing = lower(string(params.frequencySpacing));
else
    spacing = "hybrid";
end

if spacing ~= "hybrid" && spacing ~= "logspace" && spacing ~= "linspace"
    error('frequencySpacing must be hybrid, logspace, or linspace.');
end

modelType = string(params.modelType);
switch modelType
    case "YoungPoissonFixedCL"
        requiredMaterialFields = {'E', 'nu', 'CL'};
        for i = 1:numel(requiredMaterialFields)
            if ~isfield(params, requiredMaterialFields{i})
                error('Missing required material field for YoungPoissonFixedCL: %s.', requiredMaterialFields{i});
            end
        end

        if params.E <= 0
            error('E must be positive.');
        end
        if params.nu < 0 || params.nu >= 0.5
            error('nu must be in the range [0, 0.5).');
        end
        if params.CL <= 0
            error('CL must be positive.');
        end

    case "LameParameters"
        requiredMaterialFields = {'lambda', 'mu'};
        for i = 1:numel(requiredMaterialFields)
            if ~isfield(params, requiredMaterialFields{i})
                error('Missing required material field for LameParameters: %s.', requiredMaterialFields{i});
            end
        end

        if params.lambda < 0
            error('lambda must be non-negative.');
        end
        if params.mu <= 0
            error('mu must be positive.');
        end

    otherwise
        error('Unknown material model type: %s.', modelType);
end
end

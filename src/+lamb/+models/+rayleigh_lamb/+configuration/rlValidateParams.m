function rlValidateParams(params)
% Validate physical and frequency parameters before running the solver.

requiredFields = {'modelType', 'rho', 'thickness', 'fmin', 'fmax'};
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

if isfield(params, 'frequencySpacing')
    spacing = lower(string(params.frequencySpacing));
else
    spacing = "hybrid";
end

validSpacings = ["hybrid", "logspace", "linspace", "explicit"];
if ~any(spacing == validSpacings)
    error('frequencySpacing must be hybrid, logspace, linspace, or explicit.');
end

if spacing == "explicit"
    validateExplicitFrequencyVector(params);
else
    validateFrequencyPointCount(params);
end

modelType = string(params.modelType);
switch modelType
    case "ShearPoisson"
        requiredMaterialFields = {'mu', 'nu'};
        for i = 1:numel(requiredMaterialFields)
            if ~isfield(params, requiredMaterialFields{i})
                error('Missing required material field for ShearPoisson: %s.', requiredMaterialFields{i});
            end
        end

        if params.mu <= 0
            error('mu must be positive.');
        end
        if params.nu <= -1 || params.nu >= 0.5
            error('nu must be in the range (-1, 0.5).');
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

function validateFrequencyPointCount(params)
if ~isfield(params, 'numFrequencyPoints')
    return;
end

if ischar(params.numFrequencyPoints) || isstring(params.numFrequencyPoints)
    value = lower(string(params.numFrequencyPoints));
    if value ~= "auto"
        numericValue = str2double(value);
        if ~isfinite(numericValue) || numericValue < 10
            error('numFrequencyPoints must be numeric >= 10 or "auto".');
        end
    end
elseif ~isnumeric(params.numFrequencyPoints) || ~isscalar(params.numFrequencyPoints) || ...
        ~isfinite(params.numFrequencyPoints) || params.numFrequencyPoints < 10
    error('numFrequencyPoints must be at least 10.');
end
end

function validateExplicitFrequencyVector(params)
if ~isfield(params, 'frequencyVector_Hz') || isempty(params.frequencyVector_Hz)
    error('frequencyVector_Hz is required when frequencySpacing is explicit.');
end

frequency = params.frequencyVector_Hz(:);
if ~isnumeric(frequency) || any(~isfinite(frequency)) || any(frequency <= 0)
    error('frequencyVector_Hz must contain finite positive numeric values.');
end
if numel(frequency) < 2 || any(diff(frequency) <= 0)
    error('frequencyVector_Hz must contain at least two strictly ascending values.');
end

endpointTolerance = max(1e-9, 1e-10 * max(abs([params.fmin, params.fmax])));
if abs(frequency(1) - params.fmin) > endpointTolerance || ...
        abs(frequency(end) - params.fmax) > endpointTolerance
    error('frequencyVector_Hz endpoints must match fmin and fmax.');
end
end

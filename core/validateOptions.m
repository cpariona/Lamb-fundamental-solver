function validateOptions(options)
% Validate numerical and mode-selection options before running the solver.

requiredFields = {'computeA0', 'computeS0', 'gridPointsInitial', ...
    'gridPointsTracking', 'jumpTol', 'residualTolerance'};
for i = 1:numel(requiredFields)
    if ~isfield(options, requiredFields{i})
        error('Missing required option field: %s.', requiredFields{i});
    end
end

if ~logical(options.computeA0) && ~logical(options.computeS0)
    error('At least one mode must be selected: computeA0 or computeS0.');
end

if options.gridPointsInitial < 100
    error('gridPointsInitial must be at least 100.');
end

if options.gridPointsTracking < 100
    error('gridPointsTracking must be at least 100.');
end

if options.jumpTol <= 0
    error('jumpTol must be positive.');
end

if options.residualTolerance <= 0
    error('residualTolerance must be positive.');
end

if isfield(options, 'searchFactors')
    if size(options.searchFactors, 2) ~= 2 || any(options.searchFactors(:) <= 0)
        error('searchFactors must be an n-by-2 matrix with positive values.');
    end
    if any(options.searchFactors(:, 2) <= options.searchFactors(:, 1))
        error('Each searchFactors upper bound must be larger than the lower bound.');
    end
end

if isfield(options, 'minCpAbsolute') && options.minCpAbsolute <= 0
    error('minCpAbsolute must be positive.');
end

if isfield(options, 'minCpRelativeToCT') && options.minCpRelativeToCT <= 0
    error('minCpRelativeToCT must be positive.');
end

if isfield(options, 'maxCpFactorCT') && options.maxCpFactorCT <= 0
    error('maxCpFactorCT must be positive.');
end

if isfield(options, 'minCpGlobalMax') && options.minCpGlobalMax <= 0
    error('minCpGlobalMax must be positive.');
end
end

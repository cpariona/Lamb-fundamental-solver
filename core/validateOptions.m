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
end

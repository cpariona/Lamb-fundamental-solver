function branchPoints = aeRefineSelectedAtlasBranch(branchPoints, params, cGrid, options)
%AEREFINESELECTEDATLASBRANCH Refine the selected atlas branch on the true SVD objective.
%
% The atlas grid is used only for discrete candidate discovery, branch linking,
% and A0 policy selection. Once the branch is selected, each explicit branch
% point is refined by bounded minimization in log(Cp) between neighboring atlas
% velocity samples.

if isempty(branchPoints) || ~getLocalOption(options, 'refineLocalMinima', true)
    return;
end

cGrid = cGrid(:);
cShear = sqrt(params.alpha / params.rho);
tolX = getLocalOption(options, 'selectedBranchRefinementTolLogCp', 1e-6);
maxFunEvals = getLocalOption(options, 'selectedBranchRefinementMaxFunEvals', 24);
maxIter = getLocalOption(options, 'selectedBranchRefinementMaxIter', 24);
optimOptions = optimset('Display', 'off', 'TolX', tolX, ...
    'MaxFunEvals', maxFunEvals, 'MaxIter', maxIter);

for n = 1:height(branchPoints)
    frequency = branchPoints.Frequency_Hz(n);
    cpSeed = branchPoints.Cp_mps(n);
    if ~isfinite(frequency) || ~isfinite(cpSeed)
        continue;
    end

    [~, centerIdx] = min(abs(cGrid - cpSeed));
    if centerIdx <= 1 || centerIdx >= numel(cGrid)
        continue;
    end

    lowerLogCp = log(cGrid(centerIdx - 1));
    upperLogCp = log(cGrid(centerIdx + 1));
    objectiveFunction = @(logCp) evaluateObjective(exp(logCp), frequency, params, options);

    try
        [refinedLogCp, refinedObjective, exitFlag] = fminbnd( ...
            objectiveFunction, lowerLogCp, upperLogCp, optimOptions);
    catch
        continue;
    end

    refinedCp = exp(refinedLogCp);
    if exitFlag <= 0 || ~isfinite(refinedCp) || ~isfinite(refinedObjective) || ...
            refinedCp <= cGrid(centerIdx - 1) || refinedCp >= cGrid(centerIdx + 1)
        continue;
    end

    branchPoints.Cp_mps(n) = refinedCp;
    branchPoints.y(n) = refinedCp / cShear;
    branchPoints.log10y(n) = log10(branchPoints.y(n));
    branchPoints.Objective(n) = refinedObjective;
end
end

function objective = evaluateObjective(cp, frequency, params, options)
objective = objectiveAcoustoelasticResidual( ...
    params.alpha, params.beta, params.gamma, params.thickness, ...
    params.rho, params.rhoF, params.fluidBulkModulus, frequency, cp, options);
end

function value = getLocalOption(options, fieldName, defaultValue)
if isstruct(options) && isfield(options, fieldName) && ~isempty(options.(fieldName))
    value = options.(fieldName);
else
    value = defaultValue;
end
end

% TEMPORARY_DIAGNOSTIC
%DIAGNOSE_AE_LOCAL_RESIDUAL_VALLEYS Inspect true residual valleys after the
% high-frequency waviness diagnostic has populated the base workspace.

assert(exist('results', 'var') == 1, ...
    ['Variable ''results'' was not found. Run diagnose_ae_high_frequency_waviness ', ...
     'first and, after the structure-assignment error, run this script without clearing the workspace.']);
assert(isfield(results, 'baseline'), 'Baseline diagnostic result is unavailable.');

launchFolder = pwd;
outputFolder = aeOutputFolder(launchFolder, 'high_frequency_waviness');
plotFolder = fullfile(outputFolder, 'plots', 'local_valleys');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

options = defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.useInternalAtlasTrackingGrid = true;
options.atlasInitializationMinFrequency_Hz = 200;
options.atlasInitializationNumFrequencyPoints = 30;
options.invalidateAtlasFallbackOutput = false;

result = results.baseline.result;
diagnostic = results.baseline.diagnostic;
highMask = diagnostic.ValidCp & diagnostic.Frequency_Hz >= 8e3 & ...
    isfinite(diagnostic.RelativeDelta2Cp);
candidateIdx = find(highMask);
[~, order] = sort(abs(diagnostic.RelativeDelta2Cp(candidateIdx)), 'descend');
candidateIdx = candidateIdx(order(1:min(6, numel(order))));

direct = result.directParams;
cGrid = result.cGrid(:);
numCases = numel(candidateIdx);

Frequency_Hz = nan(numCases, 1);
Frequency_kHz = nan(numCases, 1);
RelativeDelta2Cp = nan(numCases, 1);
SolverCp_mps = nan(numCases, 1);
NearestDiscreteCp_mps = nan(numCases, 1);
ParabolicCp_mps = nan(numCases, 1);
DenseTrueMinimumCp_mps = nan(numCases, 1);
SolverMinusDense_mps = nan(numCases, 1);
ParabolicMinusDense_mps = nan(numCases, 1);
SolverTrueObjective = nan(numCases, 1);
ParabolicPredictedObjective = nan(numCases, 1);
ParabolicTrueObjective = nan(numCases, 1);
DenseTrueMinimumObjective = nan(numCases, 1);
ParabolicFitAccepted = false(numCases, 1);
valleySamples = repmat(struct('frequency_Hz', NaN, 'table', table()), numCases, 1);

for n = 1:numCases
    rowIdx = candidateIdx(n);
    f = diagnostic.Frequency_Hz(rowIdx);
    cpSolver = diagnostic.Cp_mps(rowIdx);

    [~, centerIdx] = min(abs(cGrid - cpSolver));
    centerIdx = min(max(centerIdx, 2), numel(cGrid)-1);
    localC = cGrid(centerIdx-1:centerIdx+1);
    localObj = evaluateObjectiveLocal(direct, f, localC, options);

    [cpParabolic, objParabolic, fitAccepted, coefficients] = ...
        fitThreePointParabolaLocal(localC, localObj);

    denseC = exp(linspace(log(localC(1)), log(localC(end)), 121)).';
    denseObj = evaluateObjectiveLocal(direct, f, denseC, options);
    [objDenseMin, denseMinIdx] = min(denseObj);
    cpDenseMin = denseC(denseMinIdx);

    if fitAccepted
        objParabolicTrue = evaluateObjectiveLocal(direct, f, cpParabolic, options);
        parabolaDense = polyval(coefficients, log(denseC));
    else
        objParabolicTrue = NaN;
        parabolaDense = nan(size(denseC));
    end
    objSolverTrue = evaluateObjectiveLocal(direct, f, cpSolver, options);

    valleySamples(n).frequency_Hz = f;
    valleySamples(n).table = table(denseC, denseObj, parabolaDense, ...
        'VariableNames', {'Cp_mps', 'TrueObjective', 'ParabolicApproximation'});

    Frequency_Hz(n) = f;
    Frequency_kHz(n) = f / 1e3;
    RelativeDelta2Cp(n) = diagnostic.RelativeDelta2Cp(rowIdx);
    SolverCp_mps(n) = cpSolver;
    NearestDiscreteCp_mps(n) = cGrid(centerIdx);
    ParabolicCp_mps(n) = cpParabolic;
    DenseTrueMinimumCp_mps(n) = cpDenseMin;
    SolverMinusDense_mps(n) = cpSolver - cpDenseMin;
    ParabolicMinusDense_mps(n) = cpParabolic - cpDenseMin;
    SolverTrueObjective(n) = objSolverTrue;
    ParabolicPredictedObjective(n) = objParabolic;
    ParabolicTrueObjective(n) = objParabolicTrue;
    DenseTrueMinimumObjective(n) = objDenseMin;
    ParabolicFitAccepted(n) = fitAccepted;

    fig = figure('Visible', 'off');
    plot(denseC, denseObj, '-', 'DisplayName', 'true objective'); hold on;
    plot(denseC, parabolaDense, '--', 'DisplayName', 'three-point parabola');
    plot(localC, localObj, 'o', 'DisplayName', 'atlas samples');
    xline(cpSolver, ':', 'solver Cp', 'DisplayName', 'solver Cp');
    xline(cpDenseMin, '-.', 'dense true min', 'DisplayName', 'dense true min');
    grid on;
    xlabel('Cp [m/s]');
    ylabel('log_{10}(\sigma_{min})');
    title(sprintf('Local residual valley at %.1f kHz', f / 1e3));
    legend('Location', 'best');
    saveas(fig, fullfile(plotFolder, sprintf('local_valley_%05dHz.png', round(f))));
    close(fig);
end

valleySummaryTable = table(Frequency_Hz, Frequency_kHz, RelativeDelta2Cp, ...
    SolverCp_mps, NearestDiscreteCp_mps, ParabolicCp_mps, ...
    DenseTrueMinimumCp_mps, SolverMinusDense_mps, ParabolicMinusDense_mps, ...
    SolverTrueObjective, ParabolicPredictedObjective, ParabolicTrueObjective, ...
    DenseTrueMinimumObjective, ParabolicFitAccepted);

writetable(valleySummaryTable, fullfile(outputFolder, 'local_valley_summary.csv'));
for n = 1:numCases
    writetable(valleySamples(n).table, fullfile(outputFolder, ...
        sprintf('local_valley_%05dHz.csv', round(valleySamples(n).frequency_Hz))));
end
save(fullfile(outputFolder, 'local_valley_workspace.mat'), ...
    'valleySummaryTable', 'valleySamples', '-v7.3');

disp(valleySummaryTable);
assignin('base', 'AELocalValleySummary', valleySummaryTable);
assignin('base', 'AELocalValleySamples', valleySamples);
fprintf('\nLocal residual valley files written to:\n%s\n', outputFolder);

function objective = evaluateObjectiveLocal(params, frequency, cp, options)
objective = nan(size(cp));
for i = 1:numel(cp)
    objective(i) = objectiveAcoustoelasticResidual( ...
        params.alpha, params.beta, params.gamma, params.thickness, ...
        params.rho, params.rhoF, params.fluidBulkModulus, ...
        frequency, cp(i), options);
end
end

function [cpRefined, objRefined, accepted, coefficients] = fitThreePointParabolaLocal(cp, objective)
cpRefined = cp(2);
objRefined = objective(2);
accepted = false;
coefficients = [NaN NaN NaN];
x = log(cp(:));
y = objective(:);
if any(~isfinite(x)) || any(~isfinite(y))
    return;
end
coefficients = polyfit(x, y, 2);
if ~isfinite(coefficients(1)) || coefficients(1) <= 0
    return;
end
x0 = -coefficients(2) / (2 * coefficients(1));
if x0 <= x(1) || x0 >= x(3)
    return;
end
cpRefined = exp(x0);
objRefined = polyval(coefficients, x0);
accepted = true;
end

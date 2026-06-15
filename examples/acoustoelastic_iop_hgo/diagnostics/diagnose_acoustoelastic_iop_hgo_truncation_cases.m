clear; clc; close all;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_TRUNCATION_CASES Inspect atlasA0 truncation cases.
%
% This diagnostic focuses on conditions where the maintained atlasA0 branch
% becomes untraceable at high frequency in the current sweeps.

outputFolder = fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_truncation_cases');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

cases = makeCaseSpecs();
allSummaryRows = [];
caseAnalysisByName = struct();

fprintf('\nAcoustoelastic IOP/HGO truncation-case diagnostic\n');
fprintf('Output folder:\n%s\n\n', outputFolder);

for i = 1:numel(cases)
    spec = cases(i);
    fprintf('Processing %s\n', spec.caseName);

    if ~exist(spec.workspacePath, 'file')
        warning('Workspace not found: %s. Run the corresponding sweep first.', spec.workspacePath);
        continue;
    end

    data = load(spec.workspacePath, 'sweepResult');
    idx = findConditionIndex(data.sweepResult, spec.sweepField, spec.targetValue, spec.valueTolerance);
    if isempty(idx)
        warning('Target condition not found for %s.', spec.caseName);
        continue;
    end

    result = data.sweepResult.conditions(idx).result;
    caseAnalysis = aeAnalyzeTruncationCase(result, 'Label', spec.caseName, 'WindowPoints', 6);
    key = matlab.lang.makeValidName(spec.caseName);
    caseAnalysisByName.(key) = caseAnalysis;

    row = caseAnalysis.summary;
    row.CaseName = spec.caseName;
    row.SweepField = spec.sweepField;
    row.TargetValue = spec.targetValue;
    row.TargetDisplayValue = spec.targetDisplayValue;
    allSummaryRows = [allSummaryRows; row]; %#ok<AGROW>

    writetable(struct2table(row), fullfile(outputFolder, spec.filePrefix + "_summary.csv"));
    writetable(caseAnalysis.neighborhoodTable, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.csv"));
    if ~isempty(caseAnalysis.firstMissingMinimaTable)
        writetable(caseAnalysis.firstMissingMinimaTable, fullfile(outputFolder, spec.filePrefix + "_first_missing_minima.csv"));
    end
    if ~isempty(caseAnalysis.branchCandidateTable)
        writetable(caseAnalysis.branchCandidateTable, fullfile(outputFolder, spec.filePrefix + "_branch_candidates.csv"));
    end

    plotCaseNeighborhood(caseAnalysis, spec, outputFolder);
end

if isempty(allSummaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(allSummaryRows);
end

writetable(summaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_cases_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_cases_workspace.mat'), ...
    'caseAnalysisByName', 'summaryTable', 'cases', '-v7.3');

disp(summaryTable);
fprintf('\nTruncation-case diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOTruncationCaseAnalysis', caseAnalysisByName);
assignin('base', 'AcoustoelasticIOPHGOTruncationCaseSummary', summaryTable);

function cases = makeCaseSpecs()
baseResults = fullfile(pwd, 'Results');
cases = struct([]);

cases(1).caseName = "iop_20mmHg";
cases(1).filePrefix = "acoustoelastic_iop_hgo_iop_20mmHg";
cases(1).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
cases(1).sweepField = "IOP";
cases(1).targetValue = 20 * 133.322;
cases(1).targetDisplayValue = 20;
cases(1).valueTolerance = 1e-6;
cases(1).xUnit = "mmHg";

cases(2).caseName = "iop_25mmHg";
cases(2).filePrefix = "acoustoelastic_iop_hgo_iop_25mmHg";
cases(2).workspacePath = cases(1).workspacePath;
cases(2).sweepField = "IOP";
cases(2).targetValue = 25 * 133.322;
cases(2).targetDisplayValue = 25;
cases(2).valueTolerance = 1e-6;
cases(2).xUnit = "mmHg";

cases(3).caseName = "mu_25kPa";
cases(3).filePrefix = "acoustoelastic_iop_hgo_mu_25kPa";
cases(3).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
cases(3).sweepField = "mu";
cases(3).targetValue = 25e3;
cases(3).targetDisplayValue = 25;
cases(3).valueTolerance = 1e-6;
cases(3).xUnit = "kPa";
end

function idx = findConditionIndex(sweepResult, sweepField, targetValue, tol)
idx = [];
for i = 1:numel(sweepResult.conditions)
    params = sweepResult.conditions(i).params;
    if isfield(params, char(sweepField))
        value = params.(char(sweepField));
        if abs(value - targetValue) <= tol * max(abs(targetValue), 1)
            idx = i;
            return;
        end
    end
end
end

function plotCaseNeighborhood(caseAnalysis, spec, outputFolder)
T = caseAnalysis.neighborhoodTable;
if isempty(T)
    return;
end
figure('Color', 'w', 'Name', spec.caseName + " truncation neighborhood");
plot(T.Frequency_kHz, T.Cp_mps, 'o-', 'LineWidth', 1.5);
hold on;
if ismember('BestMinimaCp_mps', T.Properties.VariableNames)
    plot(T.Frequency_kHz, T.BestMinimaCp_mps, 'x--', 'LineWidth', 1.2);
end
if ismember('ClosestMinimaCpToPreviousCp_mps', T.Properties.VariableNames)
    plot(T.Frequency_kHz, T.ClosestMinimaCpToPreviousCp_mps, 's:', 'LineWidth', 1.2);
end
grid on;
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(strrep(spec.caseName, '_', ' ') + " truncation neighborhood");
legend({'reported Cp', 'best atlas minimum', 'closest minimum to previous Cp'}, 'Location', 'best');
hold off;
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.fig"));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.png"));
end

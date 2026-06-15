clear; clc; close all;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_TRUNCATION_CASES Inspect atlasA0 truncation cases.
%
% This diagnostic focuses on conditions where the maintained atlasA0 branch
% becomes untraceable. It reports the conservative atlasA0 truncation and an
% optional diagnostic recovery assessment based on local minima and short-gap
% continuity. Recovery outputs are diagnostic only; they do not replace atlasA0.

outputFolder = fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_truncation_cases');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

cases = makeCaseSpecs();
allSummaryRows = [];
classificationRows = [];
breakRows = [];
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
    recovery = aeAnalyzeTruncationRecovery(result, ...
        'MaxRelativeCpDistance', spec.maxRelativeCpDistance, ...
        'MaxRelativeBridgeMismatch', spec.maxRelativeBridgeMismatch, ...
        'MaxGapPoints', spec.maxGapPoints, ...
        'MaxGapFrequencyRatio', spec.maxGapFrequencyRatio);
    classification = aeClassifyTruncationRecovery(caseAnalysis.summary, recovery.summary);
    firstBreak = aeAnalyzeFirstUnrecoveredBreak(result, recovery, ...
        'MaxRelativeCpDistance', spec.maxRelativeCpDistance, ...
        'WindowPoints', 6);

    key = matlab.lang.makeValidName(spec.caseName);
    caseAnalysisByName.(key).truncation = caseAnalysis;
    caseAnalysisByName.(key).recovery = recovery;
    caseAnalysisByName.(key).classification = classification;
    caseAnalysisByName.(key).firstUnrecoveredBreak = firstBreak;

    row = caseAnalysis.summary;
    row.CaseName = spec.caseName;
    row.SweepField = spec.sweepField;
    row.TargetValue = spec.targetValue;
    row.TargetDisplayValue = spec.targetDisplayValue;
    row.RecoveredValidFraction = recovery.summary.RecoveredValidFraction;
    row.NumRecoveredPoints = recovery.summary.NumRecoveredPoints;
    row.NumLocalMinimumRecoveries = recovery.summary.NumLocalMinimumRecoveries;
    row.NumSmallGapBridgeRecoveries = recovery.summary.NumSmallGapBridgeRecoveries;
    row.FirstMissingAfterRecovery_kHz = recovery.summary.FirstMissingAfterRecovery_kHz;
    row.LastRecoveredValidFrequency_kHz = recovery.summary.LastRecoveredValidFrequency_kHz;
    row.ContiguousRecoveredValidFraction = recovery.summary.ContiguousRecoveredValidFraction;
    row.NumContiguousRecoveredPoints = recovery.summary.NumContiguousRecoveredPoints;
    row.NumContiguousLocalMinimumRecoveries = recovery.summary.NumContiguousLocalMinimumRecoveries;
    row.NumContiguousSmallGapBridgeRecoveries = recovery.summary.NumContiguousSmallGapBridgeRecoveries;
    row.FirstMissingAfterContiguousRecovery_kHz = recovery.summary.FirstMissingAfterContiguousRecovery_kHz;
    row.LastContiguousRecoveredFrequency_kHz = recovery.summary.LastContiguousRecoveredFrequency_kHz;
    row.NumPointwiseRecoveriesAfterContiguousBreak = recovery.summary.NumPointwiseRecoveriesAfterContiguousBreak;
    row.RecoveryClass = classification.RecoveryClass;
    row.InitialBreakRecovered = classification.InitialBreakRecovered;
    row.ContiguousExtension_kHz = classification.ContiguousExtension_kHz;
    row.PointwiseOnly = classification.PointwiseOnly;
    row.FirstUnrecoveredBreakClass = firstBreak.summary.BreakClass;
    row.FirstUnrecoveredBreakFrequency_kHz = firstBreak.summary.BreakFrequency_kHz;
    row.FirstUnrecoveredBreakNearestRelativeDistance = firstBreak.summary.NearestRelativeDistanceToPreviousCp;
    row.FirstUnrecoveredBreakRelativeDistanceMargin = firstBreak.summary.RelativeDistanceMargin;
    allSummaryRows = [allSummaryRows; row]; %#ok<AGROW>

    classRow = classification;
    classRow.CaseName = spec.caseName;
    classRow.SweepField = spec.sweepField;
    classRow.TargetDisplayValue = spec.targetDisplayValue;
    classificationRows = [classificationRows; classRow]; %#ok<AGROW>

    breakRow = firstBreak.summary;
    breakRow.CaseName = spec.caseName;
    breakRow.SweepField = spec.sweepField;
    breakRow.TargetDisplayValue = spec.targetDisplayValue;
    breakRows = [breakRows; breakRow]; %#ok<AGROW>

    writetable(struct2table(row), fullfile(outputFolder, spec.filePrefix + "_summary.csv"));
    writetable(struct2table(classification), fullfile(outputFolder, spec.filePrefix + "_recovery_classification.csv"));
    writetable(struct2table(firstBreak.summary), fullfile(outputFolder, spec.filePrefix + "_first_unrecovered_break_summary.csv"));
    writetable(caseAnalysis.neighborhoodTable, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.csv"));
    writetable(recovery.recoveryTable, fullfile(outputFolder, spec.filePrefix + "_recovery_table.csv"));
    writetable(firstBreak.localWindowTable, fullfile(outputFolder, spec.filePrefix + "_first_unrecovered_break_window.csv"));
    if ~isempty(firstBreak.breakMinimaTable)
        writetable(firstBreak.breakMinimaTable, fullfile(outputFolder, spec.filePrefix + "_first_unrecovered_break_minima.csv"));
    end
    if ~isempty(caseAnalysis.firstMissingMinimaTable)
        writetable(caseAnalysis.firstMissingMinimaTable, fullfile(outputFolder, spec.filePrefix + "_first_missing_minima.csv"));
    end
    if ~isempty(caseAnalysis.branchCandidateTable)
        writetable(caseAnalysis.branchCandidateTable, fullfile(outputFolder, spec.filePrefix + "_branch_candidates.csv"));
    end

    plotCaseNeighborhood(caseAnalysis, recovery, result, spec, outputFolder);
end

if isempty(allSummaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(allSummaryRows);
end
if isempty(classificationRows)
    classificationTable = table();
else
    classificationTable = struct2table(classificationRows);
end
if isempty(breakRows)
    firstUnrecoveredBreakTable = table();
else
    firstUnrecoveredBreakTable = struct2table(breakRows);
end
interpretationTable = aeSummarizeTruncationRecoveryClassification(classificationTable);

writetable(summaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_cases_summary.csv'));
writetable(classificationTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_recovery_classification.csv'));
writetable(interpretationTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_recovery_interpretation.csv'));
writetable(firstUnrecoveredBreakTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_first_unrecovered_break_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_cases_workspace.mat'), ...
    'caseAnalysisByName', 'summaryTable', 'classificationTable', 'interpretationTable', 'firstUnrecoveredBreakTable', 'cases', '-v7.3');

disp(summaryTable);
if ~isempty(classificationTable)
    disp(classificationTable(:, {'CaseName','RecoveryClass','InitialBreakRecovered','ContiguousExtension_kHz','NumPointwiseRecoveriesAfterContiguousBreak'}));
end
if ~isempty(firstUnrecoveredBreakTable)
    disp(firstUnrecoveredBreakTable(:, {'CaseName','BreakClass','BreakFrequency_kHz','NearestRelativeDistanceToPreviousCp','RelativeDistanceMargin'}));
end
if ~isempty(interpretationTable)
    disp(interpretationTable(:, {'CaseName','RecoveryClass','ReportingInterpretation','RecommendedNextStep'}));
end
fprintf('\nTruncation-case diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOTruncationCaseAnalysis', caseAnalysisByName);
assignin('base', 'AcoustoelasticIOPHGOTruncationCaseSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOTruncationRecoveryClassification', classificationTable);
assignin('base', 'AcoustoelasticIOPHGOTruncationRecoveryInterpretation', interpretationTable);
assignin('base', 'AcoustoelasticIOPHGOFirstUnrecoveredBreakSummary', firstUnrecoveredBreakTable);

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
cases(1).maxRelativeCpDistance = 0.08;
cases(1).maxRelativeBridgeMismatch = 0.03;
cases(1).maxGapPoints = 2;
cases(1).maxGapFrequencyRatio = 1.12;

cases(2).caseName = "iop_25mmHg";
cases(2).filePrefix = "acoustoelastic_iop_hgo_iop_25mmHg";
cases(2).workspacePath = cases(1).workspacePath;
cases(2).sweepField = "IOP";
cases(2).targetValue = 25 * 133.322;
cases(2).targetDisplayValue = 25;
cases(2).valueTolerance = 1e-6;
cases(2).xUnit = "mmHg";
cases(2).maxRelativeCpDistance = 0.08;
cases(2).maxRelativeBridgeMismatch = 0.03;
cases(2).maxGapPoints = 2;
cases(2).maxGapFrequencyRatio = 1.12;

cases(3).caseName = "mu_25kPa";
cases(3).filePrefix = "acoustoelastic_iop_hgo_mu_25kPa";
cases(3).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
cases(3).sweepField = "mu";
cases(3).targetValue = 25e3;
cases(3).targetDisplayValue = 25;
cases(3).valueTolerance = 1e-6;
cases(3).xUnit = "kPa";
cases(3).maxRelativeCpDistance = 0.08;
cases(3).maxRelativeBridgeMismatch = 0.03;
cases(3).maxGapPoints = 2;
cases(3).maxGapFrequencyRatio = 1.12;
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

function plotCaseNeighborhood(caseAnalysis, recovery, result, spec, outputFolder)
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
idx = ismember(result.frequency(:)/1e3, T.Frequency_kHz);
plot(result.frequency(idx)/1e3, recovery.recoveredCp(idx), 'd-.', 'LineWidth', 1.2);
plot(result.frequency(idx)/1e3, recovery.contiguousRecoveredCp(idx), '^-', 'LineWidth', 1.2);
grid on;
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(strrep(spec.caseName, '_', ' ') + " truncation neighborhood");
legend({'reported Cp', 'best atlas minimum', 'closest minimum to previous Cp', 'pointwise recovered Cp', 'contiguous recovered Cp'}, 'Location', 'best');
hold off;
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.fig"));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.png"));
end

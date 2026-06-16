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
sensitivitySummaryRows = [];
relaxedComparisonRows = [];
relaxedQualityRows = [];
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
    thresholdSensitivity = aeAnalyzeBreakThresholdSensitivity(result, ...
        'RelativeCpDistanceValues', spec.relativeCpDistanceSensitivityValues, ...
        'MaxRelativeBridgeMismatch', spec.maxRelativeBridgeMismatch, ...
        'MaxGapPoints', spec.maxGapPoints, ...
        'MaxGapFrequencyRatio', spec.maxGapFrequencyRatio, ...
        'WindowPoints', 6);

    relaxedThreshold = thresholdSensitivity.summary.BestThresholdByContiguousExtension;
    if ~isfinite(relaxedThreshold)
        relaxedThreshold = spec.maxRelativeCpDistance;
    end
    thresholdRelaxedComparison = aeCompareThresholdRelaxedBranch(result, ...
        'MaxRelativeCpDistance', relaxedThreshold, ...
        'MaxRelativeBridgeMismatch', spec.maxRelativeBridgeMismatch, ...
        'MaxGapPoints', spec.maxGapPoints, ...
        'MaxGapFrequencyRatio', spec.maxGapFrequencyRatio);
    thresholdRelaxedQuality = aeAssessThresholdRelaxedBranchQuality(result, thresholdRelaxedComparison);

    key = matlab.lang.makeValidName(spec.caseName);
    caseAnalysisByName.(key).truncation = caseAnalysis;
    caseAnalysisByName.(key).recovery = recovery;
    caseAnalysisByName.(key).classification = classification;
    caseAnalysisByName.(key).firstUnrecoveredBreak = firstBreak;
    caseAnalysisByName.(key).thresholdSensitivity = thresholdSensitivity;
    caseAnalysisByName.(key).thresholdRelaxedComparison = thresholdRelaxedComparison;
    caseAnalysisByName.(key).thresholdRelaxedQuality = thresholdRelaxedQuality;

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
    row.ThresholdForInitialBreakRecovery = thresholdSensitivity.summary.ThresholdForInitialBreakRecovery;
    row.BestThresholdByContiguousExtension = thresholdSensitivity.summary.BestThresholdByContiguousExtension;
    row.MaxContiguousExtensionByThreshold_kHz = thresholdSensitivity.summary.MaxContiguousExtension_kHz;
    row.RelaxedComparisonThreshold = thresholdRelaxedComparison.summary.RelaxedThreshold;
    row.RelaxedComparisonClass = thresholdRelaxedComparison.summary.RelaxedBranchClass;
    row.RelaxedAddedPoints = thresholdRelaxedComparison.summary.AddedByRelaxedPoints;
    row.RelaxedLastValidFrequency_kHz = thresholdRelaxedComparison.summary.LastRelaxedValidFrequency_kHz;
    row.RelaxedQualityClass = thresholdRelaxedQuality.summary.RelaxedQualityClass;
    row.RelaxedStrongMinimumPoints = thresholdRelaxedQuality.summary.StrongMinimumPoints;
    row.RelaxedAcceptableMinimumPoints = thresholdRelaxedQuality.summary.AcceptableMinimumPoints;
    row.RelaxedWeakOrCrowdedMinimumPoints = thresholdRelaxedQuality.summary.WeakOrCrowdedMinimumPoints;
    row.RelaxedLowRankMinimumPoints = thresholdRelaxedQuality.summary.LowRankMinimumPoints;
    row.RelaxedMedianAddedMinRank = thresholdRelaxedQuality.summary.MedianAddedMinRank;
    row.RelaxedMedianAddedDepthRelativeToMedian = thresholdRelaxedQuality.summary.MedianAddedDepthRelativeToMedian;
    row.RelaxedMedianAddedSpacingToNearestLogY = thresholdRelaxedQuality.summary.MedianAddedSpacingToNearestLogY;
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

    sensitivityRow = thresholdSensitivity.summary;
    sensitivityRow.CaseName = spec.caseName;
    sensitivityRow.SweepField = spec.sweepField;
    sensitivityRow.TargetDisplayValue = spec.targetDisplayValue;
    sensitivitySummaryRows = [sensitivitySummaryRows; sensitivityRow]; %#ok<AGROW>

    relaxedRow = thresholdRelaxedComparison.summary;
    relaxedRow.CaseName = spec.caseName;
    relaxedRow.SweepField = spec.sweepField;
    relaxedRow.TargetDisplayValue = spec.targetDisplayValue;
    relaxedComparisonRows = [relaxedComparisonRows; relaxedRow]; %#ok<AGROW>

    qualityRow = thresholdRelaxedQuality.summary;
    qualityRow.CaseName = spec.caseName;
    qualityRow.SweepField = spec.sweepField;
    qualityRow.TargetDisplayValue = spec.targetDisplayValue;
    relaxedQualityRows = [relaxedQualityRows; qualityRow]; %#ok<AGROW>

    sensitivityTable = thresholdSensitivity.sensitivityTable;
    if ~isempty(sensitivityTable)
        sensitivityTable.CaseName = repmat(spec.caseName, height(sensitivityTable), 1);
        sensitivityTable.SweepField = repmat(spec.sweepField, height(sensitivityTable), 1);
        sensitivityTable.TargetDisplayValue = repmat(spec.targetDisplayValue, height(sensitivityTable), 1);
    end

    relaxedComparisonTable = thresholdRelaxedComparison.comparisonTable;
    if ~isempty(relaxedComparisonTable)
        relaxedComparisonTable.CaseName = repmat(spec.caseName, height(relaxedComparisonTable), 1);
        relaxedComparisonTable.SweepField = repmat(spec.sweepField, height(relaxedComparisonTable), 1);
        relaxedComparisonTable.TargetDisplayValue = repmat(spec.targetDisplayValue, height(relaxedComparisonTable), 1);
    end

    relaxedQualityTable = thresholdRelaxedQuality.addedQualityTable;
    if ~isempty(relaxedQualityTable)
        relaxedQualityTable.CaseName = repmat(spec.caseName, height(relaxedQualityTable), 1);
        relaxedQualityTable.SweepField = repmat(spec.sweepField, height(relaxedQualityTable), 1);
        relaxedQualityTable.TargetDisplayValue = repmat(spec.targetDisplayValue, height(relaxedQualityTable), 1);
    end

    writetable(struct2table(row), fullfile(outputFolder, spec.filePrefix + "_summary.csv"));
    writetable(struct2table(classification), fullfile(outputFolder, spec.filePrefix + "_recovery_classification.csv"));
    writetable(struct2table(firstBreak.summary), fullfile(outputFolder, spec.filePrefix + "_first_unrecovered_break_summary.csv"));
    writetable(struct2table(thresholdSensitivity.summary), fullfile(outputFolder, spec.filePrefix + "_threshold_sensitivity_summary.csv"));
    writetable(sensitivityTable, fullfile(outputFolder, spec.filePrefix + "_threshold_sensitivity.csv"));
    writetable(struct2table(thresholdRelaxedComparison.summary), fullfile(outputFolder, spec.filePrefix + "_threshold_relaxed_comparison_summary.csv"));
    writetable(relaxedComparisonTable, fullfile(outputFolder, spec.filePrefix + "_threshold_relaxed_comparison.csv"));
    writetable(struct2table(thresholdRelaxedQuality.summary), fullfile(outputFolder, spec.filePrefix + "_threshold_relaxed_quality_summary.csv"));
    writetable(relaxedQualityTable, fullfile(outputFolder, spec.filePrefix + "_threshold_relaxed_quality.csv"));
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

    plotCaseNeighborhood(caseAnalysis, recovery, thresholdRelaxedComparison, result, spec, outputFolder);
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
if isempty(sensitivitySummaryRows)
    thresholdSensitivitySummaryTable = table();
else
    thresholdSensitivitySummaryTable = struct2table(sensitivitySummaryRows);
end
if isempty(relaxedComparisonRows)
    thresholdRelaxedComparisonSummaryTable = table();
else
    thresholdRelaxedComparisonSummaryTable = struct2table(relaxedComparisonRows);
end
if isempty(relaxedQualityRows)
    thresholdRelaxedQualitySummaryTable = table();
else
    thresholdRelaxedQualitySummaryTable = struct2table(relaxedQualityRows);
end
interpretationTable = aeSummarizeTruncationRecoveryClassification(classificationTable);

writetable(summaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_cases_summary.csv'));
writetable(classificationTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_recovery_classification.csv'));
writetable(interpretationTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_recovery_interpretation.csv'));
writetable(firstUnrecoveredBreakTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_first_unrecovered_break_summary.csv'));
writetable(thresholdSensitivitySummaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_threshold_sensitivity_summary.csv'));
writetable(thresholdRelaxedComparisonSummaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_threshold_relaxed_comparison_summary.csv'));
writetable(thresholdRelaxedQualitySummaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_threshold_relaxed_quality_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_truncation_cases_workspace.mat'), ...
    'caseAnalysisByName', 'summaryTable', 'classificationTable', 'interpretationTable', ...
    'firstUnrecoveredBreakTable', 'thresholdSensitivitySummaryTable', ...
    'thresholdRelaxedComparisonSummaryTable', 'thresholdRelaxedQualitySummaryTable', 'cases', '-v7.3');

disp(summaryTable);
if ~isempty(classificationTable)
    disp(classificationTable(:, {'CaseName','RecoveryClass','InitialBreakRecovered','ContiguousExtension_kHz','NumPointwiseRecoveriesAfterContiguousBreak'}));
end
if ~isempty(firstUnrecoveredBreakTable)
    disp(firstUnrecoveredBreakTable(:, {'CaseName','BreakClass','BreakFrequency_kHz','NearestRelativeDistanceToPreviousCp','RelativeDistanceMargin'}));
end
if ~isempty(thresholdSensitivitySummaryTable)
    disp(thresholdSensitivitySummaryTable(:, {'CaseName','ThresholdForInitialBreakRecovery','BestThresholdByContiguousExtension','MaxContiguousExtension_kHz'}));
end
if ~isempty(thresholdRelaxedComparisonSummaryTable)
    disp(thresholdRelaxedComparisonSummaryTable(:, {'CaseName','RelaxedThreshold','RelaxedBranchClass','AddedByRelaxedPoints','LastRelaxedValidFrequency_kHz'}));
end
if ~isempty(thresholdRelaxedQualitySummaryTable)
    disp(thresholdRelaxedQualitySummaryTable(:, {'CaseName','RelaxedQualityClass','StrongMinimumPoints','AcceptableMinimumPoints','WeakOrCrowdedMinimumPoints','LowRankMinimumPoints'}));
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
assignin('base', 'AcoustoelasticIOPHGOThresholdSensitivitySummary', thresholdSensitivitySummaryTable);
assignin('base', 'AcoustoelasticIOPHGOThresholdRelaxedComparisonSummary', thresholdRelaxedComparisonSummaryTable);
assignin('base', 'AcoustoelasticIOPHGOThresholdRelaxedQualitySummary', thresholdRelaxedQualitySummaryTable);

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
cases(1).relativeCpDistanceSensitivityValues = [0.08 0.10 0.12 0.15];

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
cases(2).relativeCpDistanceSensitivityValues = [0.08 0.10 0.12 0.15];

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
cases(3).relativeCpDistanceSensitivityValues = [0.08 0.10 0.12 0.15];
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

function plotCaseNeighborhood(caseAnalysis, recovery, thresholdRelaxedComparison, result, spec, outputFolder)
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
plot(result.frequency(idx)/1e3, thresholdRelaxedComparison.recovery.contiguousRecoveredCp(idx), 'v-', 'LineWidth', 1.2);
grid on;
xlabel('frequency [kHz]');
ylabel('Cp [m/s]');
title(strrep(spec.caseName, '_', ' ') + " truncation neighborhood");
legend({'reported Cp', 'best atlas minimum', 'closest minimum to previous Cp', 'pointwise recovered Cp', 'contiguous recovered Cp', 'threshold-relaxed contiguous Cp'}, 'Location', 'best');
hold off;
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.fig"));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_truncation_neighborhood.png"));
end

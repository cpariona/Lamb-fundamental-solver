function interpretationTable = aeSummarizeTruncationRecoveryClassification(classificationTable)
%AESUMMARIZETRUNCATIONRECOVERYCLASSIFICATION Build an interpretation table for truncation recovery classes.
%
%   interpretationTable = aeSummarizeTruncationRecoveryClassification(classificationTable)
%
%   Converts the detailed recovery-classification table into a compact table
%   intended for reporting and debugging. It does not modify solver results.

if nargin < 1 || isempty(classificationTable)
    interpretationTable = table();
    return;
end

rows = [];
for i = 1:height(classificationTable)
    row = struct();
    row.CaseName = getTableValue(classificationTable, i, 'CaseName', "case_" + i);
    row.SweepField = getTableValue(classificationTable, i, 'SweepField', "");
    row.TargetDisplayValue = getTableValue(classificationTable, i, 'TargetDisplayValue', nan);
    row.RecoveryClass = getTableValue(classificationTable, i, 'RecoveryClass', "unknown");
    row.InitialBreakRecovered = logical(getTableValue(classificationTable, i, 'InitialBreakRecovered', false));
    row.ContiguousExtension_kHz = getTableValue(classificationTable, i, 'ContiguousExtension_kHz', nan);
    row.LastContiguousRecoveredFrequency_kHz = getTableValue(classificationTable, i, 'LastContiguousRecoveredFrequency_kHz', nan);
    row.FirstMissingAfterContiguousRecovery_kHz = getTableValue(classificationTable, i, 'FirstMissingAfterContiguousRecovery_kHz', nan);
    row.NumPointwiseRecoveriesAfterContiguousBreak = getTableValue(classificationTable, i, 'NumPointwiseRecoveriesAfterContiguousBreak', nan);
    row.ReportingInterpretation = buildInterpretation(row);
    row.RecommendedNextStep = buildRecommendation(row);
    rows = [rows; row]; %#ok<AGROW>
end

interpretationTable = struct2table(rows);
end

function value = getTableValue(T, rowIndex, name, defaultValue)
if ismember(name, T.Properties.VariableNames)
    value = T.(name)(rowIndex);
else
    value = defaultValue;
end
if iscell(value) && numel(value) == 1
    value = value{1};
end
if isstring(defaultValue)
    value = string(value);
end
end

function text = buildInterpretation(row)
switch string(row.RecoveryClass)
    case "no_truncation"
        text = "The maintained atlasA0 branch has no truncation in this case.";
    case "fully_contiguous_recovered"
        text = "The diagnostic recovery propagates continuously through all missing points; this is compatible with a traceability limitation rather than a resolved physical disappearance.";
    case "partially_contiguous_recovered"
        text = sprintf("The first atlasA0 break is recovered and the branch is extended continuously by %.3g kHz, but a later contiguous break remains.", row.ContiguousExtension_kHz);
    case "pointwise_only_after_break"
        text = "Only pointwise candidates are found after an unresolved break; these candidates should not be interpreted as a continuous recovered branch.";
    case "not_recovered"
        text = "The first atlasA0 break is not recovered under the current conservative continuity criteria.";
    otherwise
        text = "Recovery class is unknown; inspect recoveryTable and classificationTable directly.";
end
text = string(text);
end

function text = buildRecommendation(row)
switch string(row.RecoveryClass)
    case "no_truncation"
        text = "No recovery action is needed for this case.";
    case "fully_contiguous_recovered"
        text = "Keep atlasA0 conservative; use the recovered curve only as diagnostic evidence and consider a narrow local-refinement check before changing maintained outputs.";
    case "partially_contiguous_recovered"
        text = "Use contiguous recovery to identify the recoverable band, then inspect the remaining break before considering local atlas refinement or gap-bridging rules.";
    case "pointwise_only_after_break"
        text = "Do not bridge the branch automatically; inspect residual landscape or run a focused local-refinement/complex-Cp diagnostic around the first break.";
    case "not_recovered"
        text = "Do not alter the maintained branch; investigate whether the missing segment is due to weak real-valued minima, modal mixing, or complex/leaky behavior.";
    otherwise
        text = "Inspect diagnostic tables manually before drawing conclusions.";
end
text = string(text);
end

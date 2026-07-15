clear; clc; close all;
launchFolder = pwd;
startup

%VALIDATE_ACOUSTOELASTIC_IOP_HGO_BRANCH_IDENTITY_SCORE_GRID
% Legacy descriptive implementation for branch-identity score grid validation.
% Prefer the short entrypoint:
%   validate_acoustoelastic_iop_hgo_branch_identity_score_grid
%
% New outputs are written to:
%   Results/ae_iop_hgo/idA0_score_grid

outputFolder = aeOutputFolder(launchFolder, 'idA0_score_grid');

baseParams = aeDefaultIdentityA0ValidationParams();
baseOptions = aeDefaultIdentityA0ValidationOptions('AtlasBranchPolicy', "atlasA0");
grid = aeDefaultIdentityA0ValidationGrid();

fprintf('\nAcoustoelastic IOP/HGO branch-identity score grid validation\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n', outputFolder);
fprintf('Number of grid cases: %d\n\n', height(grid));

summaryRows = [];
caseRows = [];
scoreByCase = struct();

for i = 1:height(grid)
    params = baseParams;
    params.IOP = grid.IOP_mmHg(i) * 133.322;
    params.mu = grid.mu_kPa(i) * 1e3;
    params.k1 = grid.k1_kPa(i) * 1e3;
    params.k2 = grid.k2(i);
    params.thickness = grid.thickness_um(i) * 1e-6;

    caseName = sprintf('iop_%gmmHg_mu_%gkPa_k1_%gkPa_k2_%g_h_%gum', ...
        grid.IOP_mmHg(i), grid.mu_kPa(i), grid.k1_kPa(i), grid.k2(i), grid.thickness_um(i));
    safeName = matlab.lang.makeValidName(caseName);

    fprintf('[%03d/%03d] %s\n', i, height(grid), caseName);

    result = solveAcoustoelasticIOPHGOBranch(params, baseOptions);
    score = aeScoreBranchIdentityCandidates(result, 'Label', string(caseName));
    scoreByCase.(safeName) = compactScore(score);

    row = buildSummaryRow(i, grid(i,:), result, score);
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    bestRows = bestCandidateRows(score.candidateTable, i, grid(i,:), caseName);
    caseRows = [caseRows; bestRows]; %#ok<AGROW>
end

summaryTable = struct2table(summaryRows);
if isempty(caseRows)
    bestCandidateTable = table();
else
    bestCandidateTable = struct2table(caseRows);
end
aggregateTable = buildAggregateTable(summaryTable);

writetable(summaryTable, fullfile(outputFolder, 'idA0_score_grid_summary.csv'));
writetable(bestCandidateTable, fullfile(outputFolder, 'idA0_score_grid_best_candidates.csv'));
writetable(aggregateTable, fullfile(outputFolder, 'idA0_score_grid_aggregate.csv'));
save(fullfile(outputFolder, 'idA0_score_grid_workspace.mat'), ...
    'summaryTable', 'bestCandidateTable', 'aggregateTable', 'scoreByCase', 'grid', 'baseParams', 'baseOptions', 'launchFolder', '-v7.3');

fprintf('\nAggregate summary\n');
disp(aggregateTable);
fprintf('\nGrid summary\n');
disp(summaryTable);
fprintf('\nBranch-identity score grid files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreGridSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreGridBestCandidates', bestCandidateTable);
assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreGridAggregate', aggregateTable);
assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreGridOutputFolder', outputFolder);

function row = buildSummaryRow(caseIndex, gridRow, result, score)
valid = logical(result.validCp(:)) & isfinite(result.Cp(:));
s = score.summary;
row = struct();
row.CaseIndex = caseIndex;
row.IOP_mmHg = gridRow.IOP_mmHg;
row.mu_kPa = gridRow.mu_kPa;
row.k1_kPa = gridRow.k1_kPa;
row.k2 = gridRow.k2;
row.thickness_um = gridRow.thickness_um;
row.GridFamily = string(gridRow.GridFamily);
row.ValidPoints = nnz(valid);
row.TotalPoints = numel(valid);
row.ValidFraction = nnz(valid) / max(numel(valid), 1);
row.LastOfficialValidFrequency_kHz = s.LastOfficialValidFrequency_kHz;
row.FirstTerminalMissingFrequency_kHz = s.FirstTerminalMissingFrequency_kHz;
row.HasInternalGap = s.HasInternalGap;
row.FirstInternalGapFrequency_kHz = s.FirstInternalGapFrequency_kHz;
row.NumCandidates = s.NumCandidates;
row.NumBestFrequencyCandidates = s.NumBestFrequencyCandidates;
row.NumStrongDiagnosticCandidates = s.NumStrongDiagnosticCandidates;
row.NumCautionDiagnosticCandidates = s.NumCautionDiagnosticCandidates;
row.MedianBestScore = s.MedianBestScore;
row.MedianBestRank = s.MedianBestRank;
row.MedianBestRelativeDistance = s.MedianBestRelativeDistance;
row.MedianBestCrowding = s.MedianBestCrowding;
row.DominantBestScoreClass = s.DominantBestScoreClass;
row.ScoreFindsCandidate = s.NumStrongDiagnosticCandidates + s.NumCautionDiagnosticCandidates > 0;
row.OfficialTruncated = isfinite(s.FirstTerminalMissingFrequency_kHz);
row.Note = "Diagnostic grid only; atlasA0 unchanged.";
end

function compact = compactScore(score)
compact = struct();
compact.summary = score.summary;
T = score.candidateTable;
if isempty(T)
    compact.bestCandidates = table();
else
    compact.bestCandidates = T(logical(T.IsBestAtFrequency), :);
end
end

function rows = bestCandidateRows(T, caseIndex, gridRow, caseName)
rows = [];
if isempty(T)
    return;
end
B = T(logical(T.IsBestAtFrequency), :);
for i = 1:height(B)
    row = struct();
    row.CaseIndex = caseIndex;
    row.CaseName = string(caseName);
    row.IOP_mmHg = gridRow.IOP_mmHg;
    row.mu_kPa = gridRow.mu_kPa;
    row.k1_kPa = gridRow.k1_kPa;
    row.k2 = gridRow.k2;
    row.thickness_um = gridRow.thickness_um;
    row.Frequency_kHz = B.Frequency_kHz(i);
    row.OfficialValid = B.OfficialValid(i);
    row.CandidateCp_mps = B.CandidateCp_mps(i);
    row.CandidateRank = B.CandidateRank(i);
    row.RelativeDistanceToPreviousCp = B.RelativeDistanceToPreviousCp(i);
    row.BranchIdentityScore = B.BranchIdentityScore(i);
    row.ScoreClass = B.ScoreClass(i);
    row.CrowdingWithin5pct = B.CrowdingWithin5pct(i);
    rows = [rows; row]; %#ok<AGROW>
end
end

function aggregate = buildAggregateTable(summaryTable)
rows = [];
families = unique(summaryTable.GridFamily, 'stable');
for i = 1:numel(families)
    mask = summaryTable.GridFamily == families(i);
    rows = [rows; aggregateRows(summaryTable(mask,:), families(i))]; %#ok<AGROW>
end
rows = [rows; aggregateRows(summaryTable, "all")];
aggregate = struct2table(rows);
end

function row = aggregateRows(T, label)
row = struct();
row.Group = string(label);
row.NumCases = height(T);
row.NumOfficialTruncated = nnz(T.OfficialTruncated);
row.NumScoreFindsCandidate = nnz(T.ScoreFindsCandidate);
row.TruncatedWithCandidate = nnz(T.OfficialTruncated & T.ScoreFindsCandidate);
row.TruncatedWithoutCandidate = nnz(T.OfficialTruncated & ~T.ScoreFindsCandidate);
row.MedianValidFraction = median(T.ValidFraction, 'omitnan');
row.MedianBestScore = median(T.MedianBestScore, 'omitnan');
row.MedianBestRank = median(T.MedianBestRank, 'omitnan');
row.MedianBestRelativeDistance = median(T.MedianBestRelativeDistance, 'omitnan');
row.MedianBestCrowding = median(T.MedianBestCrowding, 'omitnan');
end

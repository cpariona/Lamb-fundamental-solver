clear; clc; close all;
launchFolder = pwd;
startup

%VALIDATE_ACOUSTOELASTIC_IOP_HGO_IDENTITYA0_DIAGNOSTIC_GRID
% Legacy descriptive implementation for identityA0Diagnostic grid validation.
% Prefer the short entrypoint:
%   validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
%
% New outputs are written to:
%   Results/ae_iop_hgo/idA0_grid

outputFolder = aeOutputFolder(launchFolder, 'idA0_grid');

baseParams = aeDefaultIdentityA0ValidationParams();
baseOptions = aeDefaultIdentityA0ValidationOptions();
grid = aeDefaultIdentityA0ValidationGrid();

fprintf('\nAcoustoelastic IOP/HGO identityA0Diagnostic grid validation\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n', outputFolder);
fprintf('Number of grid cases: %d\n\n', height(grid));

summaryRows = [];
caseRows = [];
identityByCase = struct();

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

    atlasOptions = baseOptions;
    atlasOptions.atlasBranchPolicy = "atlasA0";
    resultAtlas = solveAcoustoelasticIOPHGOBranch(params, atlasOptions);

    identityOptions = baseOptions;
    identityOptions.atlasBranchPolicy = "identityA0Diagnostic";
    resultIdentity = solveAcoustoelasticIOPHGOBranch(params, identityOptions);

    officialCpPreserved = isequaln(resultAtlas.Cp, resultIdentity.Cp);
    officialValidPreserved = isequal(resultAtlas.validCp, resultIdentity.validCp);
    if ~officialCpPreserved || ~officialValidPreserved
        error('identityA0Diagnostic modified official atlas output for case %s.', caseName);
    end
    if ~isfield(resultIdentity, 'identityA0')
        error('identityA0Diagnostic did not add result.identityA0 for case %s.', caseName);
    end

    identityByCase.(safeName) = compactIdentity(resultIdentity.identityA0);

    row = buildSummaryRow(i, grid(i,:), resultIdentity, caseName);
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    addedRows = buildAddedCandidateRows(i, grid(i,:), resultIdentity, caseName);
    caseRows = [caseRows; addedRows]; %#ok<AGROW>
end

summaryTable = struct2table(summaryRows);
if isempty(caseRows)
    addedCandidateTable = table();
else
    addedCandidateTable = struct2table(caseRows);
end
aggregateTable = buildAggregateTable(summaryTable);

writetable(summaryTable, fullfile(outputFolder, 'idA0_grid_summary.csv'));
writetable(addedCandidateTable, fullfile(outputFolder, 'idA0_grid_added_candidates.csv'));
writetable(aggregateTable, fullfile(outputFolder, 'idA0_grid_aggregate.csv'));
save(fullfile(outputFolder, 'idA0_grid_workspace.mat'), ...
    'summaryTable', 'addedCandidateTable', 'aggregateTable', 'identityByCase', 'grid', 'baseParams', 'baseOptions', 'launchFolder', '-v7.3');

fprintf('\nAggregate summary\n');
disp(aggregateTable);
fprintf('\nidentityA0Diagnostic grid files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOIdentityA0DiagnosticGridSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOIdentityA0DiagnosticGridAddedCandidates', addedCandidateTable);
assignin('base', 'AcoustoelasticIOPHGOIdentityA0DiagnosticGridAggregate', aggregateTable);
assignin('base', 'AcoustoelasticIOPHGOIdentityA0DiagnosticGridOutputFolder', outputFolder);

function compact = compactIdentity(identity)
compact = struct();
compact.summary = identity.summary;
compact.frequency = identity.frequency;
compact.CpCandidate = identity.CpCandidate;
compact.validCandidate = identity.validCandidate;
compact.addedFromIdentityScore = identity.addedFromIdentityScore;
compact.branchIdentityScore = identity.branchIdentityScore;
compact.candidateRank = identity.candidateRank;
compact.candidateClass = identity.candidateClass;
end

function row = buildSummaryRow(caseIndex, gridRow, result, caseName)
id = result.identityA0.summary;
valid = logical(result.validCp(:)) & isfinite(result.Cp(:));
row = struct();
row.CaseIndex = caseIndex;
row.CaseName = string(caseName);
row.IOP_mmHg = gridRow.IOP_mmHg;
row.mu_kPa = gridRow.mu_kPa;
row.k1_kPa = gridRow.k1_kPa;
row.k2 = gridRow.k2;
row.thickness_um = gridRow.thickness_um;
row.GridFamily = string(gridRow.GridFamily);
row.OfficialValidPoints = id.OfficialValidPoints;
row.CandidateValidPoints = id.CandidateValidPoints;
row.AddedCandidatePoints = id.AddedCandidatePoints;
row.TotalPoints = id.TotalPoints;
row.OfficialValidFraction = id.OfficialValidFraction;
row.CandidateValidFraction = id.CandidateValidFraction;
row.ValidFractionGain = id.CandidateValidFraction - id.OfficialValidFraction;
row.FirstOfficialMissingFrequency_kHz = id.FirstOfficialMissingFrequency_kHz;
row.FirstCandidateMissingFrequency_kHz = id.FirstCandidateMissingFrequency_kHz;
row.LastOfficialValidFrequency_kHz = id.LastOfficialValidFrequency_kHz;
row.LastCandidateValidFrequency_kHz = id.LastCandidateValidFrequency_kHz;
row.MedianAddedScore = id.MedianAddedScore;
row.MedianAddedRank = id.MedianAddedRank;
row.OfficialTruncated = any(~valid) && isfinite(id.FirstOfficialMissingFrequency_kHz);
row.CandidateExtendsOfficial = id.AddedCandidatePoints > 0;
row.CandidateReachesFinalFrequency = logical(result.identityA0.validCandidate(end));
row.Note = "identityA0Diagnostic only; official atlas fields preserved.";
end

function rows = buildAddedCandidateRows(caseIndex, gridRow, result, caseName)
rows = [];
id = result.identityA0;
idx = find(logical(id.addedFromIdentityScore));
for i = 1:numel(idx)
    k = idx(i);
    row = struct();
    row.CaseIndex = caseIndex;
    row.CaseName = string(caseName);
    row.IOP_mmHg = gridRow.IOP_mmHg;
    row.mu_kPa = gridRow.mu_kPa;
    row.k1_kPa = gridRow.k1_kPa;
    row.k2 = gridRow.k2;
    row.thickness_um = gridRow.thickness_um;
    row.Frequency_kHz = id.frequency(k) / 1e3;
    row.CpCandidate_mps = id.CpCandidate(k);
    row.BranchIdentityScore = id.branchIdentityScore(k);
    row.CandidateRank = id.candidateRank(k);
    row.CandidateClass = id.candidateClass(k);
    rows = [rows; row]; %#ok<AGROW>
end
end

function aggregate = buildAggregateTable(summaryTable)
rows = [];
families = unique(summaryTable.GridFamily, 'stable');
for i = 1:numel(families)
    rows = [rows; aggregateRows(summaryTable(summaryTable.GridFamily == families(i), :), families(i))]; %#ok<AGROW>
end
rows = [rows; aggregateRows(summaryTable, "all")];
aggregate = struct2table(rows);
end

function row = aggregateRows(T, label)
row = struct();
row.Group = string(label);
row.NumCases = height(T);
row.NumOfficialTruncated = nnz(T.OfficialTruncated);
row.NumCandidateExtendsOfficial = nnz(T.CandidateExtendsOfficial);
row.TruncatedExtended = nnz(T.OfficialTruncated & T.CandidateExtendsOfficial);
row.TruncatedNotExtended = nnz(T.OfficialTruncated & ~T.CandidateExtendsOfficial);
row.NumCandidateReachesFinalFrequency = nnz(T.CandidateReachesFinalFrequency);
row.MedianOfficialValidFraction = median(T.OfficialValidFraction, 'omitnan');
row.MedianCandidateValidFraction = median(T.CandidateValidFraction, 'omitnan');
row.MedianValidFractionGain = median(T.ValidFractionGain, 'omitnan');
row.MedianAddedPoints = median(T.AddedCandidatePoints, 'omitnan');
row.MedianAddedScore = median(T.MedianAddedScore, 'omitnan');
row.MedianAddedRank = median(T.MedianAddedRank, 'omitnan');
end

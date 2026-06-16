clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_IDENTITYA0_PHYSICAL_PLAUSIBILITY
% Inspect identityA0Diagnostic candidate curves for visual/physical plausibility.
%
% This diagnostic consumes the workspace produced by:
%   validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid
%
% It does not rerun the solver and does not modify official atlas outputs.

inputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_identityA0_diagnostic_grid');
inputFile = fullfile(inputFolder, 'acoustoelastic_iop_hgo_identityA0_diagnostic_grid_workspace.mat');
outputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_identityA0_physical_plausibility');
plotFolder = fullfile(outputFolder, 'plots');

if ~exist(inputFile, 'file')
    error('Input workspace not found. Run validate_acoustoelastic_iop_hgo_identityA0_diagnostic_grid first. Expected: %s', inputFile);
end
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end
if ~exist(plotFolder, 'dir'), mkdir(plotFolder); end

data = load(inputFile, 'summaryTable', 'identityByCase');
summaryTable = data.summaryTable;
identityByCase = data.identityByCase;

fprintf('\nidentityA0Diagnostic physical plausibility diagnostic\n');
fprintf('Input workspace:\n%s\n', inputFile);
fprintf('Output folder:\n%s\n\n', outputFolder);

caseRows = [];
caseNames = fieldnames(identityByCase);
for i = 1:numel(caseNames)
    name = caseNames{i};
    identity = identityByCase.(name);
    row = analyzeIdentityCase(name, identity, summaryTable);
    caseRows = [caseRows; row]; %#ok<AGROW>
end

plausibilityTable = struct2table(caseRows);
plausibilityTable = sortrows(plausibilityTable, {'PlausibilityClass', 'CandidateValidFraction', 'MaxRelativeDrop'}, {'ascend', 'ascend', 'descend'});
aggregateTable = buildAggregateTable(plausibilityTable);

writetable(plausibilityTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_identityA0_physical_plausibility_summary.csv'));
writetable(aggregateTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_identityA0_physical_plausibility_aggregate.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_identityA0_physical_plausibility_workspace.mat'), ...
    'plausibilityTable', 'aggregateTable', 'summaryTable', 'identityByCase', 'launchFolder', '-v7.3');

plotWorstCases(plausibilityTable, identityByCase, plotFolder, 18);

fprintf('\nAggregate plausibility summary\n');
disp(aggregateTable);
fprintf('\nWorst plausibility cases\n');
disp(plausibilityTable(1:min(20,height(plausibilityTable)), :));
fprintf('\nPhysical plausibility files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilitySummary', plausibilityTable);
assignin('base', 'AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilityAggregate', aggregateTable);
assignin('base', 'AcoustoelasticIOPHGOIdentityA0PhysicalPlausibilityOutputFolder', outputFolder);

function row = analyzeIdentityCase(caseFieldName, identity, summaryTable)
frequency_kHz = identity.frequency(:) / 1e3;
cpCandidate = identity.CpCandidate(:);
validCandidate = logical(identity.validCandidate(:));
added = logical(identity.addedFromIdentityScore(:));
cpOfficial = cpCandidate;
cpOfficial(added) = nan;
validOfficial = isfinite(cpOfficial);

s = findSummaryRow(caseFieldName, summaryTable);
metrics = curveMetrics(frequency_kHz, cpCandidate, validCandidate, added);

row = struct();
row.CaseFieldName = string(caseFieldName);
row.CaseName = s.CaseName;
row.IOP_mmHg = s.IOP_mmHg;
row.mu_kPa = s.mu_kPa;
row.k1_kPa = s.k1_kPa;
row.k2 = s.k2;
row.thickness_um = s.thickness_um;
row.GridFamily = s.GridFamily;
row.OfficialValidFraction = nnz(validOfficial) / max(numel(validOfficial), 1);
row.CandidateValidFraction = nnz(validCandidate) / max(numel(validCandidate), 1);
row.ValidFractionGain = row.CandidateValidFraction - row.OfficialValidFraction;
row.AddedCandidatePoints = nnz(added);
row.CandidateReachesFinalFrequency = validCandidate(end);
row.MaxRelativeJump = metrics.MaxRelativeJump;
row.MaxRelativeDrop = metrics.MaxRelativeDrop;
row.NumLargeJumps = metrics.NumLargeJumps;
row.NumLargeDrops = metrics.NumLargeDrops;
row.NumSlopeSignChanges = metrics.NumSlopeSignChanges;
row.Roughness = metrics.Roughness;
row.HighFrequencyRelativeSlope = metrics.HighFrequencyRelativeSlope;
row.HighFrequencyVariation = metrics.HighFrequencyVariation;
row.MedianAddedScore = median(identity.branchIdentityScore(added), 'omitnan');
row.MedianAddedRank = median(identity.candidateRank(added), 'omitnan');
row.PlausibilityClass = classifyPlausibility(row);
row.PlausibilityNote = plausibilityNote(row);
end

function s = findSummaryRow(caseFieldName, summaryTable)
% The saved summary table includes CaseName, but MATLAB field names were made
% valid. Reconstruct the same valid name to find the row robustly.
validNames = strings(height(summaryTable), 1);
for i = 1:height(summaryTable)
    validNames(i) = matlab.lang.makeValidName(char(summaryTable.CaseName(i)));
end
idx = find(validNames == string(caseFieldName), 1, 'first');
if isempty(idx)
    error('Could not match identityByCase field %s to summaryTable.CaseName.', caseFieldName);
end
s = summaryTable(idx, :);
end

function metrics = curveMetrics(frequency_kHz, cp, valid, added)
metrics = struct();
metrics.MaxRelativeJump = nan;
metrics.MaxRelativeDrop = nan;
metrics.NumLargeJumps = 0;
metrics.NumLargeDrops = 0;
metrics.NumSlopeSignChanges = 0;
metrics.Roughness = nan;
metrics.HighFrequencyRelativeSlope = nan;
metrics.HighFrequencyVariation = nan;

idx = find(valid & isfinite(cp));
if numel(idx) < 2
    return;
end
% Only compare adjacent frequency indices to avoid measuring gaps as jumps.
adj = idx(diff(idx) == 1);
next = adj + 1;
if isempty(adj)
    return;
end
relStep = diffPair(cp(adj), cp(next));
relDrop = max(0, (cp(adj) - cp(next)) ./ max(abs(cp(adj)), eps));
metrics.MaxRelativeJump = max(abs(relStep), [], 'omitnan');
metrics.MaxRelativeDrop = max(relDrop, [], 'omitnan');
metrics.NumLargeJumps = nnz(abs(relStep) > 0.08);
metrics.NumLargeDrops = nnz(relDrop > 0.05);

validCp = cp(idx);
validF = frequency_kHz(idx);
if numel(validCp) >= 4
    slope = diff(validCp) ./ max(diff(validF), eps);
    slope(abs(slope) < 1e-9) = 0;
    metrics.NumSlopeSignChanges = nnz(slope(1:end-1) .* slope(2:end) < 0);
    metrics.Roughness = median(abs(diff(validCp, 2)), 'omitnan') / max(median(abs(validCp), 'omitnan'), eps);
end

hfStart = max(1, floor(0.75 * numel(idx)));
hfIdx = idx(hfStart:end);
if numel(hfIdx) >= 3
    hfCp = cp(hfIdx);
    hfF = frequency_kHz(hfIdx);
    p = polyfit(hfF, hfCp, 1);
    df = max(hfF) - min(hfF);
    metrics.HighFrequencyRelativeSlope = p(1) * df / max(abs(hfCp(1)), eps);
    metrics.HighFrequencyVariation = (max(hfCp) - min(hfCp)) / max(median(abs(hfCp), 'omitnan'), eps);
end
end

function rel = diffPair(a, b)
rel = (b - a) ./ max(abs(a), eps);
end

function cls = classifyPlausibility(row)
if row.CandidateValidFraction < 0.85
    cls = "poor_coverage_manual_inspection";
elseif row.NumLargeDrops >= 2 || row.MaxRelativeDrop > 0.12
    cls = "caution_large_high_frequency_drop";
elseif row.NumLargeJumps >= 3 || row.MaxRelativeJump > 0.18
    cls = "caution_large_jumps";
elseif row.NumSlopeSignChanges >= 6 || row.Roughness > 0.05
    cls = "caution_oscillatory_branch";
elseif ~row.CandidateReachesFinalFrequency
    cls = "plausible_partial_extension";
else
    cls = "plausible_full_extension";
end
end

function note = plausibilityNote(row)
switch string(row.PlausibilityClass)
    case "poor_coverage_manual_inspection"
        note = "Candidate improves coverage but remains too incomplete for promotion.";
    case "caution_large_high_frequency_drop"
        note = "Candidate contains large downward jumps; check physical plausibility and competing minima.";
    case "caution_large_jumps"
        note = "Candidate contains large phase-velocity jumps; likely branch ambiguity.";
    case "caution_oscillatory_branch"
        note = "Candidate is oscillatory or rough; inspect objective landscape and neighboring branches.";
    case "plausible_partial_extension"
        note = "Candidate is locally smooth but does not reach final frequency.";
    otherwise
        note = "Candidate is smooth under current metrics and reaches final frequency.";
end
end

function aggregate = buildAggregateTable(T)
classes = unique(string(T.PlausibilityClass), 'stable');
rows = [];
for i = 1:numel(classes)
    mask = string(T.PlausibilityClass) == classes(i);
    rows = [rows; aggregateRows(T(mask,:), classes(i))]; %#ok<AGROW>
end
rows = [rows; aggregateRows(T, "all")];
aggregate = struct2table(rows);
end

function row = aggregateRows(T, label)
row = struct();
row.Group = string(label);
row.NumCases = height(T);
row.NumFinalFrequencyReached = nnz(T.CandidateReachesFinalFrequency);
row.MedianOfficialValidFraction = median(T.OfficialValidFraction, 'omitnan');
row.MedianCandidateValidFraction = median(T.CandidateValidFraction, 'omitnan');
row.MedianGain = median(T.ValidFractionGain, 'omitnan');
row.MedianMaxRelativeJump = median(T.MaxRelativeJump, 'omitnan');
row.MedianMaxRelativeDrop = median(T.MaxRelativeDrop, 'omitnan');
row.MedianRoughness = median(T.Roughness, 'omitnan');
row.MedianAddedRank = median(T.MedianAddedRank, 'omitnan');
end

function plotWorstCases(T, identityByCase, plotFolder, nCases)
if isempty(T)
    return;
end
nCases = min(nCases, height(T));
for i = 1:nCases
    row = T(i,:);
    identity = identityByCase.(char(row.CaseFieldName));
    f = identity.frequency(:) / 1e3;
    cpCandidate = identity.CpCandidate(:);
    added = logical(identity.addedFromIdentityScore(:));
    cpOfficial = cpCandidate;
    cpOfficial(added) = nan;

    fig = figure('Visible', 'off');
    plot(f, cpOfficial, 'o-', 'DisplayName', 'official atlasA0'); hold on; grid on;
    plot(f, cpCandidate, '-', 'DisplayName', 'identityA0 candidate');
    scatter(f(added), cpCandidate(added), 32, 'filled', 'DisplayName', 'added candidate points');
    xlabel('Frequency [kHz]');
    ylabel('Cp [m/s]');
    title(strrep(string(row.PlausibilityClass) + " | " + string(row.CaseName), '_', '\_'));
    legend('Location', 'best');
    fileName = sprintf('%02d_%s_%s.png', i, char(row.PlausibilityClass), char(row.CaseFieldName));
    saveas(fig, fullfile(plotFolder, fileName));
    close(fig);
end
end

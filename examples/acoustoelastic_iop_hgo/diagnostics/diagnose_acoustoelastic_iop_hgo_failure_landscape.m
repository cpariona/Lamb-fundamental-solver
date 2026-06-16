clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_FAILURE_LANDSCAPE
% Focused objective-landscape diagnostic near atlasA0 terminal failures.

outputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_failure_landscape');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

cases = makeCaseSpecs(launchFolder);
yGrid = linspace(0.02, 3.40, 2600);
windowOffsets = -2:4;
summaryRows = [];
caseLandscapeByName = struct();

fprintf('\nAcoustoelastic IOP/HGO focused failure-landscape diagnostic\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n\n', outputFolder);

for c = 1:numel(cases)
    spec = cases(c);
    fprintf('Processing %s\n', spec.caseName);
    if ~exist(spec.workspacePath, 'file')
        warning('Workspace not found: %s. Run the corresponding sweep from the same launch folder first.', spec.workspacePath);
        continue;
    end

    data = load(spec.workspacePath, 'sweepResult');
    idx = findConditionIndex(data.sweepResult, spec.sweepField, spec.targetValue, spec.valueTolerance);
    if isempty(idx)
        warning('Target condition not found for %s.', spec.caseName);
        continue;
    end

    params = data.sweepResult.conditions(idx).params;
    result = data.sweepResult.conditions(idx).result;
    diagnosis = aeDiagnoseAtlasA0TruncationCause(result, 'Label', spec.caseName);
    landscape = analyzeCaseLandscape(params, result, diagnosis, yGrid, windowOffsets, spec.caseName);
    caseLandscapeByName.(matlab.lang.makeValidName(spec.caseName)) = landscape;

    writetable(landscape.frequencyTable, fullfile(outputFolder, spec.filePrefix + "_failure_landscape_frequency_table.csv"));
    writetable(landscape.minimaTable, fullfile(outputFolder, spec.filePrefix + "_failure_landscape_minima_table.csv"));
    writetable(struct2table(landscape.summary), fullfile(outputFolder, spec.filePrefix + "_failure_landscape_summary.csv"));
    plotCaseLandscape(landscape, plotFolder, spec.filePrefix);

    row = landscape.summary;
    row.CaseName = spec.caseName;
    row.SweepField = spec.sweepField;
    row.TargetDisplayValue = spec.targetDisplayValue;
    summaryRows = [summaryRows; row]; %#ok<AGROW>
end

if isempty(summaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(summaryRows);
end

writetable(summaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_failure_landscape_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_failure_landscape_workspace.mat'), ...
    'summaryTable', 'caseLandscapeByName', 'cases', 'yGrid', 'windowOffsets', 'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nFailure-landscape diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOFailureLandscapeSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOFailureLandscapeByCase', caseLandscapeByName);
assignin('base', 'AcoustoelasticIOPHGOFailureLandscapeOutputFolder', outputFolder);

function cases = makeCaseSpecs(launchFolder)
baseResults = fullfile(launchFolder, 'Results');
cases = struct([]);

cases(1).caseName = "iop_25mmHg";
cases(1).filePrefix = "acoustoelastic_iop_hgo_iop_25mmHg";
cases(1).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
cases(1).sweepField = "IOP";
cases(1).targetValue = 25 * 133.322;
cases(1).targetDisplayValue = 25;
cases(1).valueTolerance = 1e-6;

cases(2).caseName = "mu_25kPa";
cases(2).filePrefix = "acoustoelastic_iop_hgo_mu_25kPa";
cases(2).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
cases(2).sweepField = "mu";
cases(2).targetValue = 25e3;
cases(2).targetDisplayValue = 25;
cases(2).valueTolerance = 1e-6;
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

function landscape = analyzeCaseLandscape(params, result, diagnosis, yGrid, offsets, caseName)
f = result.frequency(:);
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);
alpha = result.alpha;
rho = params.rho;
cShear = sqrt(alpha / rho);
cGrid = yGrid(:) * cShear;

center = diagnosis.summary.FirstTerminalMissingIndex;
if isnan(center)
    center = find(valid, 1, 'last');
end
idx = unique(max(1, min(numel(f), center + offsets(:))));

freqRows = [];
minRows = [];
for ii = 1:numel(idx)
    k = idx(ii);
    objective = nan(numel(cGrid), 1);
    for j = 1:numel(cGrid)
        objective(j) = objectiveAcoustoelasticResidual(result.alpha(k), result.beta(k), result.gamma(k), ...
            params.thickness, params.rho, params.rhoF, params.fluidBulkModulus, f(k), cGrid(j), result.options);
    end
    minima = findLocalMinima(yGrid(:), cGrid, objective, cShear);
    previousIdx = find(valid & (1:numel(valid)).' < k, 1, 'last');
    if isempty(previousIdx), previousCp = nan; else, previousCp = cp(previousIdx); end
    [freqRow, minimaRows] = summarizeFrequency(caseName, k, f(k), valid(k), cp(k), previousCp, minima);
    freqRows = [freqRows; freqRow]; %#ok<AGROW>
    minRows = [minRows; minimaRows]; %#ok<AGROW>
end

landscape = struct();
landscape.caseName = caseName;
landscape.frequencyIndex = idx;
landscape.frequencyTable = struct2table(freqRows);
if isempty(minRows)
    landscape.minimaTable = table();
else
    landscape.minimaTable = struct2table(minRows);
end
landscape.summary = summarizeCase(landscape.frequencyTable, landscape.minimaTable, diagnosis);
landscape.diagnosisSummary = diagnosis.summary;
end

function minima = findLocalMinima(yGrid, cGrid, objective, cShear)
idx = [];
for i = 2:numel(objective)-1
    if isfinite(objective(i-1)) && isfinite(objective(i)) && isfinite(objective(i+1)) && ...
            objective(i) <= objective(i-1) && objective(i) <= objective(i+1)
        idx(end+1) = i; %#ok<AGROW>
    end
end
if isempty(idx)
    minima = table();
    return;
end
obj = objective(idx);
[obj, order] = sort(obj, 'ascend');
idx = idx(order);
minima = table();
minima.MinRank = (1:numel(idx)).';
minima.GridIndex = idx(:);
minima.y = yGrid(idx(:));
minima.Cp_mps = cGrid(idx(:));
minima.Objective = obj(:);
minima.log10Objective = log10(max(obj(:), realmin));
minima.cShear = repmat(cShear, numel(idx), 1);
end

function [freqRow, minimaRows] = summarizeFrequency(caseName, k, fHz, officialValid, officialCp, previousCp, minima)
freqRow = struct();
freqRow.CaseName = string(caseName);
freqRow.Index = k;
freqRow.Frequency_kHz = fHz / 1e3;
freqRow.OfficialValid = officialValid;
freqRow.OfficialCp_mps = officialCp;
freqRow.PreviousValidCp_mps = previousCp;
freqRow.NumMinima = height(minima);
freqRow.DeepestY = nan;
freqRow.DeepestCp_mps = nan;
freqRow.DeepestObjective = nan;
freqRow.NearestToPreviousY = nan;
freqRow.NearestToPreviousCp_mps = nan;
freqRow.NearestToPreviousRank = nan;
freqRow.NearestToPreviousRelativeDistance = nan;
freqRow.NearestToPreviousObjective = nan;
freqRow.ObjectiveRatioSecondToFirst = nan;
freqRow.CrowdingWithin5pct = 0;
freqRow.LandscapeClass = "no_minima";

minimaRows = [];
if isempty(minima)
    return;
end
freqRow.DeepestY = minima.y(1);
freqRow.DeepestCp_mps = minima.Cp_mps(1);
freqRow.DeepestObjective = minima.Objective(1);
if height(minima) >= 2 && minima.Objective(1) > 0
    freqRow.ObjectiveRatioSecondToFirst = minima.Objective(2) / minima.Objective(1);
end
if isfinite(previousCp)
    rel = abs(minima.Cp_mps - previousCp) ./ max(abs(previousCp), eps);
    [freqRow.NearestToPreviousRelativeDistance, j] = min(rel);
    freqRow.NearestToPreviousY = minima.y(j);
    freqRow.NearestToPreviousCp_mps = minima.Cp_mps(j);
    freqRow.NearestToPreviousRank = minima.MinRank(j);
    freqRow.NearestToPreviousObjective = minima.Objective(j);
    freqRow.CrowdingWithin5pct = nnz(rel <= 0.05);
end
freqRow.LandscapeClass = classifyLandscape(freqRow);

topN = min(12, height(minima));
for i = 1:topN
    row = struct();
    row.CaseName = string(caseName);
    row.Index = k;
    row.Frequency_kHz = fHz / 1e3;
    row.MinRank = minima.MinRank(i);
    row.y = minima.y(i);
    row.Cp_mps = minima.Cp_mps(i);
    row.Objective = minima.Objective(i);
    row.log10Objective = minima.log10Objective(i);
    row.RelativeDistanceToPreviousCp = abs(minima.Cp_mps(i) - previousCp) ./ max(abs(previousCp), eps);
    minimaRows = [minimaRows; row]; %#ok<AGROW>
end
end

function cls = classifyLandscape(row)
if row.NumMinima == 0
    cls = "no_minima";
elseif isfinite(row.NearestToPreviousRelativeDistance) && row.NearestToPreviousRelativeDistance > 0.15
    cls = "nearest_minimum_far";
elseif row.CrowdingWithin5pct >= 2
    cls = "crowded_near_previous_cp";
elseif isfinite(row.ObjectiveRatioSecondToFirst) && row.ObjectiveRatioSecondToFirst < 1.25
    cls = "flat_competing_minima";
elseif isfinite(row.NearestToPreviousRank) && row.NearestToPreviousRank > 3
    cls = "continuation_is_low_rank";
else
    cls = "clean_candidate";
end
end

function summary = summarizeCase(freqTable, minimaTable, diagnosis)
missingRows = freqTable(~freqTable.OfficialValid, :);
if isempty(missingRows)
    targetRows = freqTable;
else
    targetRows = missingRows;
end
summary = struct();
summary.CaseLabel = diagnosis.summary.CaseLabel;
summary.FirstTerminalMissingFrequency_kHz = diagnosis.summary.FirstTerminalMissingFrequency_kHz;
summary.LastOfficialValidFrequency_kHz = diagnosis.summary.LastOfficialValidFrequency_kHz;
summary.NumInspectedFrequencies = height(freqTable);
summary.NumMissingInspectedFrequencies = height(missingRows);
summary.MedianNearestRelativeDistance = median(targetRows.NearestToPreviousRelativeDistance, 'omitnan');
summary.MedianNearestRank = median(targetRows.NearestToPreviousRank, 'omitnan');
summary.MinObjectiveRatioSecondToFirst = min(targetRows.ObjectiveRatioSecondToFirst, [], 'omitnan');
summary.MaxCrowdingWithin5pct = max(targetRows.CrowdingWithin5pct, [], 'omitnan');
summary.DominantLandscapeClass = dominantString(targetRows.LandscapeClass);
summary.NumTopMinimaRows = height(minimaTable);
summary.Note = "Focused failure landscape; diagnostic only.";
end

function value = dominantString(labels)
labels = string(labels);
priority = ["nearest_minimum_far", "continuation_is_low_rank", "crowded_near_previous_cp", ...
    "flat_competing_minima", "no_minima", "clean_candidate"];
for i = 1:numel(priority)
    if any(labels == priority(i))
        value = priority(i);
        return;
    end
end
if isempty(labels)
    value = "none";
else
    value = labels(1);
end
end

function plotCaseLandscape(landscape, plotFolder, filePrefix)
T = landscape.frequencyTable;
fig = figure('Visible', 'off');
plot(T.Frequency_kHz, T.NearestToPreviousRelativeDistance, 'o-'); grid on;
xlabel('Frequency [kHz]'); ylabel('nearest relative distance to previous Cp');
title(strrep(filePrefix + " failure landscape distance", '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_nearest_distance.png"));
close(fig);

fig = figure('Visible', 'off');
plot(T.Frequency_kHz, T.NearestToPreviousRank, 'o-'); grid on;
xlabel('Frequency [kHz]'); ylabel('nearest minimum rank');
title(strrep(filePrefix + " failure landscape rank", '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_nearest_rank.png"));
close(fig);

if ~isempty(landscape.minimaTable)
    M = landscape.minimaTable;
    fig = figure('Visible', 'off');
    scatter(M.Frequency_kHz, M.y, 18, M.MinRank, 'filled'); grid on; colorbar;
    xlabel('Frequency [kHz]'); ylabel('y = Cp / c_s');
    title(strrep(filePrefix + " top minima cloud near failure", '_', '\_'));
    saveas(fig, fullfile(plotFolder, filePrefix + "_top_minima_cloud.png"));
    close(fig);
end
end

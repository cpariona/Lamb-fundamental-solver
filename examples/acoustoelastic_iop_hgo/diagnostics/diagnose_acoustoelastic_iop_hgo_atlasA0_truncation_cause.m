clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_ATLASA0_TRUNCATION_CAUSE
% Diagnose likely root causes of atlasA0 high-frequency truncation.

outputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_atlasA0_truncation_cause');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

cases = makeCaseSpecs(launchFolder);
summaryRows = [];
caseDiagnosisByName = struct();

fprintf('\nAcoustoelastic IOP/HGO atlasA0 truncation-cause diagnostic\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n\n', outputFolder);

for i = 1:numel(cases)
    spec = cases(i);
    fprintf('Processing %s\n', spec.caseName);

    if ~exist(spec.workspacePath, 'file')
        warning('Workspace not found: %s. Run the corresponding sweep from the same launch folder first.', spec.workspacePath);
        continue;
    end

    data = load(spec.workspacePath, 'sweepResult', 'options');
    idx = findConditionIndex(data.sweepResult, spec.sweepField, spec.targetValue, spec.valueTolerance);
    if isempty(idx)
        warning('Target condition not found for %s.', spec.caseName);
        continue;
    end

    result = data.sweepResult.conditions(idx).result;
    diagnosis = aeDiagnoseAtlasA0TruncationCause(result, 'Label', spec.caseName);

    key = matlab.lang.makeValidName(spec.caseName);
    caseDiagnosisByName.(key) = diagnosis;

    row = diagnosis.summary;
    row.CaseName = spec.caseName;
    row.SweepField = spec.sweepField;
    row.TargetDisplayValue = spec.targetDisplayValue;
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    writetable(struct2table(row), fullfile(outputFolder, spec.filePrefix + "_truncation_cause_summary.csv"));
    writetable(diagnosis.localCauseTable, fullfile(outputFolder, spec.filePrefix + "_local_cause_table.csv"));
    writetable(diagnosis.atlasResolutionPlan, fullfile(outputFolder, spec.filePrefix + "_atlas_resolution_plan.csv"));

    writeLandscapePlots(result, diagnosis, outputFolder, spec.filePrefix);
end

if isempty(summaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(summaryRows);
end

writetable(summaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_atlasA0_truncation_cause_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_atlasA0_truncation_cause_workspace.mat'), ...
    'caseDiagnosisByName', 'summaryTable', 'cases', 'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nAtlasA0 truncation-cause diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOAtlasA0TruncationCause', caseDiagnosisByName);
assignin('base', 'AcoustoelasticIOPHGOAtlasA0TruncationCauseSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOAtlasA0TruncationCauseOutputFolder', outputFolder);

function cases = makeCaseSpecs(launchFolder)
baseResults = fullfile(launchFolder, 'Results');
cases = struct([]);

cases(1).caseName = "iop_20mmHg";
cases(1).filePrefix = "acoustoelastic_iop_hgo_iop_20mmHg";
cases(1).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
cases(1).sweepField = "IOP";
cases(1).targetValue = 20 * 133.322;
cases(1).targetDisplayValue = 20;
cases(1).valueTolerance = 1e-6;

cases(2) = cases(1);
cases(2).caseName = "iop_25mmHg";
cases(2).filePrefix = "acoustoelastic_iop_hgo_iop_25mmHg";
cases(2).targetValue = 25 * 133.322;
cases(2).targetDisplayValue = 25;

cases(3).caseName = "mu_25kPa";
cases(3).filePrefix = "acoustoelastic_iop_hgo_mu_25kPa";
cases(3).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
cases(3).sweepField = "mu";
cases(3).targetValue = 25e3;
cases(3).targetDisplayValue = 25;
cases(3).valueTolerance = 1e-6;
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

function writeLandscapePlots(result, diagnosis, outputFolder, filePrefix)
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

f = result.frequency(:) / 1e3;
cp = result.Cp(:);
valid = logical(result.validCp(:)) & isfinite(cp);
T = diagnosis.localCauseTable;

fig = figure('Visible', 'off');
plot(f(valid), cp(valid), 'o-'); hold on;
if ismember('AcceptedPersistenceCandidate', T.Properties.VariableNames)
    A = T(logical(T.AcceptedPersistenceCandidate), :);
    if ~isempty(A)
        plot(A.Frequency_kHz, A.NearestMinimumCp_mps, 'x');
    end
end
xlabel('Frequency [kHz]'); ylabel('Cp [m/s]'); grid on;
title(strrep(filePrefix, '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_cp_official_and_candidates.png"));
close(fig);

if isfield(result, 'minimaTable') && ~isempty(result.minimaTable)
    M = result.minimaTable;
    fig = figure('Visible', 'off');
    scatter(M.Frequency_kHz, M.log10y, 8, M.MinRank, 'filled'); hold on;
    if ~isempty(T)
        scatter(T.Frequency_kHz, log10(T.NearestMinimumCp_mps ./ max(result.cShear, eps)), 30, 'x');
    end
    xlabel('Frequency [kHz]'); ylabel('log10(y)'); grid on;
    title(strrep(filePrefix + " local minima cloud", '_', '\_'));
    colorbar;
    saveas(fig, fullfile(plotFolder, filePrefix + "_local_minima_logy_cloud.png"));
    close(fig);
end

if ~isempty(T)
    fig = figure('Visible', 'off');
    plot(T.Frequency_kHz, T.NearestMinimumRank, 'o-');
    xlabel('Frequency [kHz]'); ylabel('Nearest minimum rank'); grid on;
    title(strrep(filePrefix + " nearest rank near break", '_', '\_'));
    saveas(fig, fullfile(plotFolder, filePrefix + "_nearest_rank_near_break.png"));
    close(fig);
end
end

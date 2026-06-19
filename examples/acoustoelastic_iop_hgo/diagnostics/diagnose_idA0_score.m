clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_BRANCH_IDENTITY_SCORE
% Legacy descriptive implementation. Prefer the short entrypoint:
%   diagnose_idA0_score
%
% New outputs are written to:
%   Results/ae_iop_hgo/idA0_score

outputFolder = aeOutputFolder(launchFolder, 'idA0_score');
plotFolder = fullfile(outputFolder, 'plots');
if ~exist(plotFolder, 'dir')
    mkdir(plotFolder);
end

cases = makeCaseSpecs(launchFolder);
summaryRows = [];
scoreByCase = struct();

fprintf('\nAcoustoelastic IOP/HGO branch-identity score diagnostic\n');
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

    result = data.sweepResult.conditions(idx).result;
    score = aeScoreBranchIdentityCandidates(result, 'Label', spec.caseName);
    scoreByCase.(matlab.lang.makeValidName(spec.caseName)) = score;

    writetable(score.candidateTable, fullfile(outputFolder, spec.filePrefix + "_candidates.csv"));
    writetable(struct2table(score.summary), fullfile(outputFolder, spec.filePrefix + "_summary.csv"));
    plotScoreDiagnostics(score, plotFolder, spec.filePrefix);

    row = score.summary;
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

writetable(summaryTable, fullfile(outputFolder, 'idA0_score_summary.csv'));
save(fullfile(outputFolder, 'idA0_score_workspace.mat'), ...
    'summaryTable', 'scoreByCase', 'cases', 'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nBranch-identity score diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreByCase', scoreByCase);
assignin('base', 'AcoustoelasticIOPHGOBranchIdentityScoreOutputFolder', outputFolder);

function cases = makeCaseSpecs(launchFolder)
cases = struct([]);

cases(1).caseName = "iop_25mmHg";
cases(1).filePrefix = "iop_25mmHg";
cases(1).workspacePath = aeResolveResultFile(launchFolder, 'iop_sweep', 'iop_sweep_workspace.mat', ...
    'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
cases(1).sweepField = "IOP";
cases(1).targetValue = 25 * 133.322;
cases(1).targetDisplayValue = 25;
cases(1).valueTolerance = 1e-6;

cases(2).caseName = "mu_25kPa";
cases(2).filePrefix = "mu_25kPa";
cases(2).workspacePath = aeResolveResultFile(launchFolder, 'mu_sweep', 'mu_sweep_workspace.mat', ...
    'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
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

function plotScoreDiagnostics(score, plotFolder, filePrefix)
T = score.candidateTable;
if isempty(T)
    return;
end
B = T(logical(T.IsBestAtFrequency), :);

fig = figure('Visible', 'off');
plot(B.Frequency_kHz, B.BranchIdentityScore, 'o-'); grid on;
xlabel('Frequency [kHz]'); ylabel('best branch-identity score');
title(strrep(filePrefix + " branch identity score", '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_best_score.png"));
close(fig);

fig = figure('Visible', 'off');
plot(B.Frequency_kHz, B.CandidateRank, 'o-'); grid on;
xlabel('Frequency [kHz]'); ylabel('best candidate rank');
title(strrep(filePrefix + " best candidate rank", '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_best_rank.png"));
close(fig);

fig = figure('Visible', 'off');
plot(B.Frequency_kHz, B.RelativeDistanceToPreviousCp, 'o-'); grid on;
xlabel('Frequency [kHz]'); ylabel('relative distance to previous Cp');
title(strrep(filePrefix + " best candidate distance", '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_best_distance.png"));
close(fig);

fig = figure('Visible', 'off');
scatter(T.Frequency_kHz, T.CandidateCp_mps, 18, T.BranchIdentityScore, 'filled'); grid on; colorbar;
xlabel('Frequency [kHz]'); ylabel('candidate Cp [m/s]');
title(strrep(filePrefix + " scored candidate cloud", '_', '\_'));
saveas(fig, fullfile(plotFolder, filePrefix + "_candidate_cloud.png"));
close(fig);
end

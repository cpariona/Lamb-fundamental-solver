clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_BRANCH_PERSISTENCE_REFINEMENT
% Inspect diagnostic A0 branch-persistence continuation after atlasA0 truncation.
% Results are written under fullfile(launchFolder, 'Results', ...), where
% launchFolder is the folder from which this script was started.

outputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_branch_persistence_refinement');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

cases = makeCaseSpecs(launchFolder);
summaryRows = [];
caseRefinementByName = struct();

fprintf('\nAcoustoelastic IOP/HGO branch-persistence refinement diagnostic\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n\n', outputFolder);

for i = 1:numel(cases)
    spec = cases(i);
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

    refinement = aeRefineAtlasA0BranchPersistence(result, ...
        'MaxRelativeCpJump', spec.maxRelativeCpJump, ...
        'MaxRelativeBridgeMismatch', spec.maxRelativeBridgeMismatch, ...
        'MaxGapPoints', spec.maxGapPoints, ...
        'MaxGapFrequencyRatio', spec.maxGapFrequencyRatio, ...
        'MaxCandidateRank', spec.maxCandidateRank, ...
        'StrongCandidateRank', spec.strongCandidateRank);

    key = matlab.lang.makeValidName(spec.caseName);
    caseRefinementByName.(key) = refinement;

    row = refinement.summary;
    row.CaseName = spec.caseName;
    row.SweepField = spec.sweepField;
    row.TargetDisplayValue = spec.targetDisplayValue;
    summaryRows = [summaryRows; row]; %#ok<AGROW>

    writetable(struct2table(row), fullfile(outputFolder, spec.filePrefix + "_branch_persistence_summary.csv"));

    if ~isempty(refinement.analysis.candidateTable)
        writetable(refinement.analysis.candidateTable, ...
            fullfile(outputFolder, spec.filePrefix + "_branch_persistence_candidates.csv"));
    end
end

if isempty(summaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(summaryRows);
end

writetable(summaryTable, ...
    fullfile(outputFolder, 'acoustoelastic_iop_hgo_branch_persistence_refinement_summary.csv'));

save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_branch_persistence_refinement_workspace.mat'), ...
    'caseRefinementByName', 'summaryTable', 'cases', 'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nBranch-persistence refinement diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOBranchPersistenceRefinement', caseRefinementByName);
assignin('base', 'AcoustoelasticIOPHGOBranchPersistenceRefinementSummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOBranchPersistenceRefinementOutputFolder', outputFolder);

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
cases(1).maxRelativeCpJump = 0.15;
cases(1).maxRelativeBridgeMismatch = 0.03;
cases(1).maxGapPoints = 2;
cases(1).maxGapFrequencyRatio = 1.12;
cases(1).maxCandidateRank = 12;
cases(1).strongCandidateRank = 3;

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
cases(3).maxRelativeCpJump = 0.15;
cases(3).maxRelativeBridgeMismatch = 0.03;
cases(3).maxGapPoints = 2;
cases(3).maxGapFrequencyRatio = 1.12;
cases(3).maxCandidateRank = 12;
cases(3).strongCandidateRank = 3;
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

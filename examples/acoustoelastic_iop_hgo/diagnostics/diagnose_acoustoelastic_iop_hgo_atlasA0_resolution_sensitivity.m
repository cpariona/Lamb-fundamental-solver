clear; clc; close all;
launchFolder = pwd;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_ATLASA0_RESOLUTION_SENSITIVITY
% Rerun selected cases with controlled atlas resolution settings.

outputFolder = fullfile(launchFolder, 'Results', 'acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

cases = makeCaseSpecs(launchFolder);
atlasNumYPointsValues = [1000 1500 2000 3000];
atlasTopNMinimaValues = [18 24 32];

summaryRows = [];
resultByCase = struct();

fprintf('\nAcoustoelastic IOP/HGO atlasA0 resolution sensitivity diagnostic\n');
fprintf('Launch folder:\n%s\n', launchFolder);
fprintf('Output folder:\n%s\n\n', outputFolder);

for c = 1:numel(cases)
    spec = cases(c);
    fprintf('Processing %s\n', spec.caseName);

    if ~exist(spec.workspacePath, 'file')
        warning('Workspace not found: %s. Run the corresponding sweep from the same launch folder first.', spec.workspacePath);
        continue;
    end

    data = load(spec.workspacePath, 'baseParams', 'options');
    baseParams = data.baseParams;
    baseOptions = data.options;
    baseParams.(char(spec.sweepField)) = spec.targetValue;

    caseRows = [];
    for ny = atlasNumYPointsValues
        for nt = atlasTopNMinimaValues
            options = baseOptions;
            options.atlasBranchPolicy = "atlasA0";
            options.atlasNumYPoints = ny;
            options.atlasTopNMinima = nt;

            fprintf('  atlasNumYPoints=%d, atlasTopNMinima=%d\n', ny, nt);
            result = solveAcoustoelasticIOPHGOBranch(baseParams, options);
            diagnosis = aeDiagnoseAtlasA0TruncationCause(result, 'Label', spec.caseName);

            row = buildSensitivityRow(spec, result, diagnosis, ny, nt);
            caseRows = [caseRows; row]; %#ok<AGROW>
            summaryRows = [summaryRows; row]; %#ok<AGROW>
        end
    end

    caseTable = struct2table(caseRows);
    writetable(caseTable, fullfile(outputFolder, spec.filePrefix + "_resolution_sensitivity.csv"));
    resultByCase.(matlab.lang.makeValidName(spec.caseName)) = caseTable;
end

if isempty(summaryRows)
    summaryTable = table();
else
    summaryTable = struct2table(summaryRows);
end

writetable(summaryTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_atlasA0_resolution_sensitivity_workspace.mat'), ...
    'summaryTable', 'resultByCase', 'cases', 'atlasNumYPointsValues', 'atlasTopNMinimaValues', 'launchFolder', '-v7.3');

disp(summaryTable);
fprintf('\nAtlasA0 resolution sensitivity files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOAtlasA0ResolutionSensitivitySummary', summaryTable);
assignin('base', 'AcoustoelasticIOPHGOAtlasA0ResolutionSensitivityByCase', resultByCase);
assignin('base', 'AcoustoelasticIOPHGOAtlasA0ResolutionSensitivityOutputFolder', outputFolder);

function cases = makeCaseSpecs(launchFolder)
baseResults = fullfile(launchFolder, 'Results');
cases = struct([]);

cases(1).caseName = "iop_20mmHg";
cases(1).filePrefix = "acoustoelastic_iop_hgo_iop_20mmHg";
cases(1).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
cases(1).sweepField = "IOP";
cases(1).targetValue = 20 * 133.322;
cases(1).targetDisplayValue = 20;

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
end

function row = buildSensitivityRow(spec, result, diagnosis, ny, nt)
valid = logical(result.validCp(:)) & isfinite(result.Cp(:));
rel = result.reliability;
s = diagnosis.summary;

row = struct();
row.CaseName = spec.caseName;
row.SweepField = spec.sweepField;
row.TargetDisplayValue = spec.targetDisplayValue;
row.AtlasNumYPoints = ny;
row.AtlasTopNMinima = nt;
row.TotalPoints = numel(valid);
row.ValidPoints = nnz(valid);
row.ValidFraction = nnz(valid) / max(numel(valid), 1);
row.LastOfficialValidFrequency_kHz = s.LastOfficialValidFrequency_kHz;
row.FirstTerminalMissingFrequency_kHz = s.FirstTerminalMissingFrequency_kHz;
row.FirstInternalGapFrequency_kHz = s.FirstInternalGapFrequency_kHz;
row.HasInternalGap = s.HasInternalGap;
row.DiagnosticAcceptedPoints = s.DiagnosticAcceptedPoints;
row.DiagnosticExtension_kHz = s.DiagnosticExtension_kHz;
row.DiagnosticMedianAcceptedRank = s.DiagnosticMedianAcceptedRank;
row.DominantCauseLabel = s.DominantCauseLabel;
row.AtlasYBoundaryStatus = s.AtlasYBoundaryStatus;
row.A0StartFilterPassed = getField(rel, 'A0StartFilterPassed', false);
row.SelectionFallbackUsed = getField(rel, 'SelectionFallbackUsed', false);
row.StartRank = getField(rel, 'StartRank', nan);
row.YStart = getField(rel, 'YStart', nan);
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name)
    value = s.(name);
else
    value = defaultValue;
end
end

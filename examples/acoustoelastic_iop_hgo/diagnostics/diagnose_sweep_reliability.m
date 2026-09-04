clear; clc; close all;
launchFolder = pwd;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%DIAGNOSE_SWEEP_RELIABILITY Analyze maintained sweep workspaces.
%
% Outputs are written to:
%   Results/ae_iop_hgo/sweep_reliability

specs = makeWorkspaceSpecs(launchFolder);
outputFolder = resolveModelOutputFolder(launchFolder, 'ae_iop_hgo', 'sweep_reliability');

allOverallRows = [];
analysisBySweep = struct();

fprintf('\nAcoustoelastic IOP/HGO sweep reliability diagnostic\n');
fprintf('Output folder:\n%s\n', outputFolder);

for i = 1:numel(specs)
    spec = specs(i);
    fprintf('Processing %s\n', spec.label);

    if ~exist(spec.workspacePath, 'file')
        fprintf('  Missing workspace. Run the corresponding sweep first:\n  %s\n', spec.workspacePath);
        continue;
    end

    data = load(spec.workspacePath, 'sweepResult', 'summary');
    if isfield(data, 'sweepResult')
        inputData = data.sweepResult;
    else
        inputData = data.summary;
    end

    strictAnalysis = aeAnalyzeSweepReliability(inputData, ...
        'ExpectedDirection', spec.expectedDirection, ...
        'Tolerance', spec.strictTolerance, ...
        'MinFrequencyForMonotonicity_kHz', spec.strictMinFrequency_kHz, ...
        'Label', spec.label + "_strict");

    effectiveAnalysis = aeAnalyzeSweepReliability(inputData, ...
        'ExpectedDirection', spec.expectedDirection, ...
        'Tolerance', spec.effectiveTolerance, ...
        'MinFrequencyForMonotonicity_kHz', spec.effectiveMinFrequency_kHz, ...
        'Label', spec.label + "_effective");

    key = matlab.lang.makeValidName(spec.label);
    analysisBySweep.(key).strict = strictAnalysis;
    analysisBySweep.(key).effective = effectiveAnalysis;

    writetable(strictAnalysis.truncationTable, fullfile(outputFolder, spec.filePrefix + "_truncation.csv"));
    writetable(strictAnalysis.branchConsistencyTable, fullfile(outputFolder, spec.filePrefix + "_branch_consistency.csv"));
    writetable(strictAnalysis.monotonicityTable, fullfile(outputFolder, spec.filePrefix + "_strict_monotonicity.csv"));
    writetable(effectiveAnalysis.monotonicityTable, fullfile(outputFolder, spec.filePrefix + "_effective_monotonicity.csv"));

    strictRow = strictAnalysis.overallSummary;
    strictRow.MetricType = "strict";
    effectiveRow = effectiveAnalysis.overallSummary;
    effectiveRow.MetricType = "effective";
    allOverallRows = [allOverallRows; strictRow; effectiveRow]; %#ok<AGROW>

    plotSweepReliability(strictAnalysis, effectiveAnalysis, spec, outputFolder);
end

if isempty(allOverallRows)
    overallTable = table();
else
    overallTable = struct2table(allOverallRows);
end

writetable(overallTable, fullfile(outputFolder, 'sweep_reliability_overall.csv'));
save(fullfile(outputFolder, 'sweep_reliability_workspace.mat'), ...
    'analysisBySweep', 'overallTable', 'specs', 'launchFolder', '-v7.3');

disp(overallTable);
fprintf('\nReliability diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOSweepReliabilityAnalysis', analysisBySweep);
assignin('base', 'AcoustoelasticIOPHGOSweepReliabilityOverallTable', overallTable);

function specs = makeWorkspaceSpecs(launchFolder)
specs = struct([]);

specs(1).label = "iop_sweep";
specs(1).filePrefix = "iop_sweep";
specs(1).expectedDirection = "increasing";
specs(1).workspacePath = aeResolveResultFile(launchFolder, 'iop_sweep', 'iop_sweep_workspace.mat', ...
    'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
specs(1).xLabel = "IOP [mmHg]";
specs(1).strictTolerance = 1e-9;
specs(1).strictMinFrequency_kHz = -inf;
specs(1).effectiveTolerance = 1e-9;
specs(1).effectiveMinFrequency_kHz = -inf;

specs(2).label = "mu_sweep";
specs(2).filePrefix = "mu_sweep";
specs(2).expectedDirection = "increasing";
specs(2).workspacePath = aeResolveResultFile(launchFolder, 'mu_sweep', 'mu_sweep_workspace.mat', ...
    'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
specs(2).xLabel = "mu [kPa]";
specs(2).strictTolerance = 1e-9;
specs(2).strictMinFrequency_kHz = -inf;
specs(2).effectiveTolerance = 0.02;
specs(2).effectiveMinFrequency_kHz = 0.25;
end

function plotSweepReliability(strictAnalysis, effectiveAnalysis, spec, outputFolder)
if isempty(strictAnalysis.truncationTable)
    return;
end
T = strictAnalysis.truncationTable;
figure('Color', 'w', 'Name', sprintf('%s valid fraction', spec.label));
plot(T.SweepValueScaled, T.ValidFraction, 'o-', 'LineWidth', 1.5);
grid on; xlabel(spec.xLabel); ylabel('valid Cp fraction [-]');
title(sprintf('%s: valid Cp fraction', strrep(spec.label, '_', ' ')));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_valid_fraction.fig"));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_valid_fraction.png"));

figure('Color', 'w', 'Name', sprintf('%s last valid frequency', spec.label));
plot(T.SweepValueScaled, T.LastValidFrequency_kHz, 'o-', 'LineWidth', 1.5);
grid on; xlabel(spec.xLabel); ylabel('last valid frequency [kHz]');
title(sprintf('%s: truncation limit', strrep(spec.label, '_', ' ')));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_last_valid_frequency.fig"));
saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_last_valid_frequency.png"));

M1 = strictAnalysis.monotonicityTable;
M2 = effectiveAnalysis.monotonicityTable;
if ~isempty(M1)
    figure('Color', 'w', 'Name', sprintf('%s monotonicity', spec.label));
    plot(M1.Frequency_kHz, double(M1.SharedValid), '-', 'LineWidth', 1.5);
    hold on;
    plot(M1.Frequency_kHz, double(M1.IsMonotonic), '--', 'LineWidth', 1.5);
    if ~isempty(M2)
        plot(M2.Frequency_kHz, double(M2.IsMonotonic), ':', 'LineWidth', 2.0);
    end
    grid on; xlabel('frequency [kHz]'); ylabel('flag [-]'); ylim([-0.05, 1.05]);
    legend({'shared valid', 'strict monotonic', 'effective monotonic'}, 'Location', 'best');
    title(sprintf('%s: strict vs effective monotonicity', strrep(spec.label, '_', ' ')));
    hold off;
    saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_monotonicity_flags.fig"));
    saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_monotonicity_flags.png"));
end
end

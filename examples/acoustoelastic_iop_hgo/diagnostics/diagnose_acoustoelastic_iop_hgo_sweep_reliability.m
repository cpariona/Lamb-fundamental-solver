clear; clc; close all;
startup

%DIAGNOSE_ACOUSTOELASTIC_IOP_HGO_SWEEP_RELIABILITY Analyze maintained sweep workspaces.

specs = makeWorkspaceSpecs();
outputFolder = fullfile(pwd, 'Results', 'acoustoelastic_iop_hgo_sweep_reliability');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

allOverallRows = [];
analysisBySweep = struct();

fprintf('\nAcoustoelastic IOP/HGO sweep reliability diagnostic\n');

for i = 1:numel(specs)
    spec = specs(i);
    fprintf('Processing %s\n', spec.label);

    if ~exist(spec.workspacePath, 'file')
        fprintf('  Missing workspace. Run the corresponding sweep first:\n  %s\n', spec.workspacePath);
        continue;
    end

    data = load(spec.workspacePath, 'sweepResult', 'summary');
    if isfield(data, 'sweepResult')
        analysis = aeAnalyzeSweepReliability(data.sweepResult, 'ExpectedDirection', spec.expectedDirection, 'Label', spec.label);
    else
        analysis = aeAnalyzeSweepReliability(data.summary, 'ExpectedDirection', spec.expectedDirection, 'Label', spec.label);
    end

    key = matlab.lang.makeValidName(spec.label);
    analysisBySweep.(key) = analysis;

    writetable(analysis.truncationTable, fullfile(outputFolder, spec.filePrefix + "_truncation_table.csv"));
    writetable(analysis.branchConsistencyTable, fullfile(outputFolder, spec.filePrefix + "_branch_consistency_table.csv"));
    writetable(analysis.monotonicityTable, fullfile(outputFolder, spec.filePrefix + "_monotonicity_table.csv"));

    allOverallRows = [allOverallRows; analysis.overallSummary]; %#ok<AGROW>
    plotSweepReliability(analysis, spec, outputFolder);
end

if isempty(allOverallRows)
    overallTable = table();
else
    overallTable = struct2table(allOverallRows);
end

writetable(overallTable, fullfile(outputFolder, 'acoustoelastic_iop_hgo_sweep_reliability_overall_summary.csv'));
save(fullfile(outputFolder, 'acoustoelastic_iop_hgo_sweep_reliability_workspace.mat'), ...
    'analysisBySweep', 'overallTable', 'specs', '-v7.3');

disp(overallTable);
fprintf('\nReliability diagnostic files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOSweepReliabilityAnalysis', analysisBySweep);
assignin('base', 'AcoustoelasticIOPHGOSweepReliabilityOverallTable', overallTable);

function specs = makeWorkspaceSpecs()
baseResults = fullfile(pwd, 'Results');
specs = struct([]);
specs(1).label = "iop_sweep";
specs(1).filePrefix = "acoustoelastic_iop_hgo_iop_sweep";
specs(1).expectedDirection = "increasing";
specs(1).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_iop_sweep', 'acoustoelastic_iop_hgo_iop_sweep_workspace.mat');
specs(1).xLabel = "IOP [mmHg]";
specs(2).label = "mu_sweep";
specs(2).filePrefix = "acoustoelastic_iop_hgo_mu_sweep";
specs(2).expectedDirection = "increasing";
specs(2).workspacePath = fullfile(baseResults, 'acoustoelastic_iop_hgo_mu_sweep', 'acoustoelastic_iop_hgo_mu_sweep_workspace.mat');
specs(2).xLabel = "mu [kPa]";
end

function plotSweepReliability(analysis, spec, outputFolder)
if isempty(analysis.truncationTable)
    return;
end
T = analysis.truncationTable;
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

M = analysis.monotonicityTable;
if ~isempty(M)
    figure('Color', 'w', 'Name', sprintf('%s monotonicity', spec.label));
    plot(M.Frequency_kHz, double(M.SharedValid), '-', 'LineWidth', 1.5);
    hold on;
    plot(M.Frequency_kHz, double(M.IsMonotonic), '--', 'LineWidth', 1.5);
    grid on; xlabel('frequency [kHz]'); ylabel('flag [-]'); ylim([-0.05, 1.05]);
    legend({'shared valid', 'monotonic'}, 'Location', 'best');
    title(sprintf('%s: shared-valid monotonicity', strrep(spec.label, '_', ' ')));
    hold off;
    saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_monotonicity_flags.fig"));
    saveas(gcf, fullfile(outputFolder, spec.filePrefix + "_monotonicity_flags.png"));
end
end

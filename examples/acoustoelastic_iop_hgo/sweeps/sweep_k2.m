clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_K2 Maintained fiber-nonlinearity sweep for the AE IOP/HGO model.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/k2_sweep
%
% Figures are written next to this script under:
%   figures/k2_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

k2_values = [50, 100, 200, 300, 400];

sweepConfig = struct();
sweepConfig.Name = "k2";
sweepConfig.Label = "Fiber nonlinearity k2";
sweepConfig.Unit = "-";
sweepConfig.ValueScale = 1;
sweepConfig.ValueFormatter = "%.0f";

sweepMetadata = struct();
sweepMetadata.k2 = k2_values;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAcoustoelastic IOP/HGO k2 sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('k2 values: %s\n', mat2str(k2_values));
fprintf('Fixed IOP: %.1f mmHg\n', baseParams.IOP / 133.322);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "k2", k2_values, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "k2_sweep", "k2_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

fig = aePlotSweepCp(sweepResult, "Title", "AE IOP/HGO A0-like sensitivity to k2");
figureFolder = aeSaveExampleFigure(fig, scriptFile, "k2_sweep", "k2_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOK2SweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOK2SweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOK2SweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOK2SweepFigureFolder', figureFolder);
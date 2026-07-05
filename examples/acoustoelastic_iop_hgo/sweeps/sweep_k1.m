clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_K1 Maintained fiber-stiffness sweep for the AE IOP/HGO model.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/k1_sweep
%
% Figures are written next to this script under:
%   figures/k1_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

k1_kPa = [10, 25, 50, 75, 100];
k1_Pa = k1_kPa * 1e3;

sweepConfig = struct();
sweepConfig.Name = "k1";
sweepConfig.Label = "Fiber stiffness k1";
sweepConfig.Unit = "kPa";
sweepConfig.ValueScale = 1e3;
sweepConfig.ValueFormatter = "%.1f";

sweepMetadata = struct();
sweepMetadata.k1_kPa = k1_kPa;
sweepMetadata.k1_Pa = k1_Pa;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAcoustoelastic IOP/HGO k1 sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('k1 values: %s kPa\n', mat2str(k1_kPa));
fprintf('Fixed IOP: %.1f mmHg\n', baseParams.IOP / 133.322);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "k1", k1_Pa, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "k1_sweep", "k1_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

fig = aePlotSweepCp(sweepResult, "Title", "AE IOP/HGO A0-like sensitivity to k1");
figureFolder = aeSaveExampleFigure(fig, scriptFile, "k1_sweep", "k1_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOK1SweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOK1SweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOK1SweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOK1SweepFigureFolder', figureFolder);
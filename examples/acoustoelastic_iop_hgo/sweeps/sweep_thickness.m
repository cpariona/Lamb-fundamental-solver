clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_THICKNESS Maintained thickness sweep for the AE IOP/HGO model.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/thickness_sweep
%
% Figures are written next to this script under:
%   figures/thickness_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

thickness_um = [400, 475, 550, 625, 700];
thickness_m = thickness_um * 1e-6;

sweepConfig = struct();
sweepConfig.Name = "thickness";
sweepConfig.Label = "Thickness";
sweepConfig.Unit = "um";
sweepConfig.ValueScale = 1e-6;
sweepConfig.ValueFormatter = "%.0f";

sweepMetadata = struct();
sweepMetadata.thickness_um = thickness_um;
sweepMetadata.thickness_m = thickness_m;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAcoustoelastic IOP/HGO thickness sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('Thickness values: %s um\n', mat2str(thickness_um));
fprintf('Fixed IOP: %.1f mmHg\n', baseParams.IOP / 133.322);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "thickness", thickness_m, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "thickness_sweep", "thickness_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

fig = aePlotSweepCp(sweepResult, "Title", "AE IOP/HGO A0-like sensitivity to thickness");
figureFolder = aeSaveExampleFigure(fig, scriptFile, "thickness_sweep", "thickness_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOThicknessSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOThicknessSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOThicknessSweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOThicknessSweepFigureFolder', figureFolder);
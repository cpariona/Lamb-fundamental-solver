clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_RADIUS Maintained curvature-radius sweep for the AE IOP/HGO model.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/radius_sweep
%
% Figures are written next to this script under:
%   figures/radius_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

radius_mm = [7.0, 7.4, 7.8, 8.2, 8.6];
radius_m = radius_mm * 1e-3;

sweepConfig = struct();
sweepConfig.Name = "radius";
sweepConfig.Label = "Curvature radius R";
sweepConfig.Unit = "mm";
sweepConfig.ValueScale = 1e-3;
sweepConfig.ValueFormatter = "%.1f";

sweepMetadata = struct();
sweepMetadata.radius_mm = radius_mm;
sweepMetadata.radius_m = radius_m;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAcoustoelastic IOP/HGO radius sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('Radius values: %s mm\n', mat2str(radius_mm));
fprintf('Fixed IOP: %.1f mmHg\n', baseParams.IOP / 133.322);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "R", radius_m, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "radius_sweep", "radius_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

fig = aePlotSweepCp(sweepResult, "Title", "AE IOP/HGO A0-like sensitivity to curvature radius");
figureFolder = aeSaveExampleFigure(fig, scriptFile, "radius_sweep", "radius_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGORadiusSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGORadiusSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGORadiusSweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGORadiusSweepFigureFolder', figureFolder);
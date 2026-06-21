clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_MU Maintained shear-modulus sweep for the acoustoelastic IOP/HGO model.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/mu_sweep
%
% Figures are written next to this script under:
%   figures/mu_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

mu_kPa = [25, 50, 75, 100];
mu_Pa = mu_kPa * 1e3;

sweepConfig = struct();
sweepConfig.Name = "mu";
sweepConfig.Label = "Shear modulus mu";
sweepConfig.Unit = "kPa";
sweepConfig.ValueScale = 1e3;
sweepConfig.ValueFormatter = "%.1f";

sweepMetadata = struct();
sweepMetadata.mu_kPa = mu_kPa;
sweepMetadata.mu_Pa = mu_Pa;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAcoustoelastic IOP/HGO mu sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('mu values: %s kPa\n', mat2str(mu_kPa));
fprintf('Fixed IOP: %.1f mmHg\n', baseParams.IOP / 133.322);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "mu", mu_Pa, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "mu_sweep", "mu_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

fig = aePlotSweepCp(sweepResult, "Title", "AE IOP/HGO A0-like sensitivity to shear modulus");
figureFolder = aeSaveExampleFigure(fig, scriptFile, "mu_sweep", "mu_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOMuSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOMuSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOMuSweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOMuSweepFigureFolder', figureFolder);

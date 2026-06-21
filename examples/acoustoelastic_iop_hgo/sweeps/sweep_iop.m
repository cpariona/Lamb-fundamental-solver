clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_IOP Maintained IOP sweep for the acoustoelastic IOP/HGO model.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/iop_sweep
%
% Figures are written next to this script under:
%   figures/iop_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

IOP_mmHg = [5, 10, 15, 20, 25];
IOP_Pa = IOP_mmHg * 133.322;

sweepConfig = struct();
sweepConfig.Name = "iop";
sweepConfig.Label = "IOP";
sweepConfig.Unit = "mmHg";
sweepConfig.ValueScale = 133.322;
sweepConfig.ValueFormatter = "%.1f";

fprintf('\nAcoustoelastic IOP/HGO IOP sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('IOP values: %s mmHg\n', mat2str(IOP_mmHg));
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "IOP", IOP_Pa, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "iop_sweep", "iop_sweep", ...
    baseParams, options, IOP_mmHg, IOP_Pa, sweepResult, summary);

fig = aePlotSweepCp(sweepResult, "Title", "AE IOP/HGO A0-like sensitivity to IOP");
figureFolder = aeSaveExampleFigure(fig, scriptFile, "iop_sweep", "iop_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOIOPSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepFigureFolder', figureFolder);

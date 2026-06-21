clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
startup

%SWEEP_MU_IOP Combined mu and IOP case-study sweep for the AE IOP/HGO model.
%
% Case-study intent:
%   Evaluate how a small physiological IOP range changes the A0-like curve
%   across a narrow biomechanical shear-modulus range.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/mu_iop_sweep
%
% Figures are written next to this script under:
%   figures/mu_iop_sweep

baseParams = aeDefaultSweepParams();
options = aeDefaultSweepOptions("Robust");

mu_kPa = [60, 65, 70, 75, 80];
IOP_mmHg = [12.5, 15, 17.5];

sweepAxes = repmat(struct( ...
    'Field', "", ...
    'Values', [], ...
    'Name', "", ...
    'Label', "", ...
    'Unit', "", ...
    'ValueScale', 1, ...
    'ValueFormatter', "%.6g"), 1, 2);

sweepAxes(1).Field = "mu";
sweepAxes(1).Values = mu_kPa * 1e3;
sweepAxes(1).Name = "mu";
sweepAxes(1).Label = "Shear modulus mu";
sweepAxes(1).Unit = "kPa";
sweepAxes(1).ValueScale = 1e3;
sweepAxes(1).ValueFormatter = "%.1f";

sweepAxes(2).Field = "IOP";
sweepAxes(2).Values = IOP_mmHg * 133.322;
sweepAxes(2).Name = "IOP";
sweepAxes(2).Label = "IOP";
sweepAxes(2).Unit = "mmHg";
sweepAxes(2).ValueScale = 133.322;
sweepAxes(2).ValueFormatter = "%.1f";

sweepConfig = struct();
sweepConfig.Name = "mu_iop";
sweepConfig.Label = "mu and IOP";

sweepMetadata = struct();
sweepMetadata.mu_kPa = mu_kPa;
sweepMetadata.IOP_mmHg = IOP_mmHg;
sweepMetadata.sweepAxes = sweepAxes;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAcoustoelastic IOP/HGO combined mu-IOP case-study sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('mu values: %s kPa\n', mat2str(mu_kPa));
fprintf('IOP values: %s mmHg\n', mat2str(IOP_mmHg));
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Conditions: %d\n', numel(mu_kPa) * numel(IOP_mmHg));
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunGridSweep(baseParams, sweepAxes, options, sweepConfig);
summary = aeSummarizeGridSweep(sweepResult);

outputFolder = aeWriteSweepOutputs(launchFolder, "mu_iop_sweep", "mu_iop_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

figs = aePlotGridSweepCpByAxis(sweepResult, "IOP", "mu", ...
    "TitlePrefix", "AE IOP/HGO A0-like sensitivity to mu");
figureFolder = "";
for i = 1:numel(figs)
    filePrefix = "mu_iop_sweep_cp_iop_" + replace(sprintf('%.1f', IOP_mmHg(i)), '.', 'p') + "mmHg";
    figureFolder = aeSaveExampleFigure(figs(i), scriptFile, "mu_iop_sweep", filePrefix);
end

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOMuIOPSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOMuIOPSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOMuIOPSweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOMuIOPSweepFigureFolder', figureFolder);

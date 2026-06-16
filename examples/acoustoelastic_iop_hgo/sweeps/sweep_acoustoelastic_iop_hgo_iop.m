clear; clc; close all;
launchFolder = pwd;
startup

%SWEEP_ACOUSTOELASTIC_IOP_HGO_IOP Maintained IOP sweep for the acoustoelastic IOP/HGO model.
% Prefer the short entrypoint:
%   sweep_iop
%
% New outputs are written to:
%   Results/ae_iop_hgo/iop_sweep

baseParams = struct();

% Geometry.
baseParams.R = 7.8e-3;                  % m
baseParams.thickness = 550e-6;          % m

% HGO parameters. These values are current pipeline defaults for diagnostic
% sweeps and should be replaced by calibrated values when available.
baseParams.mu = 50e3;                   % Pa
baseParams.k1 = 25e3;                   % Pa
baseParams.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
baseParams.rho = 1060;                  % kg/m^3
baseParams.rhoF = 1000;                 % kg/m^3
baseParams.fluidBulkModulus = 2.2e9;    % Pa

% Frequency vector. Extend below 100 Hz in later diagnostics if the flexural
% onset remains unclear.
baseParams.frequency = logspace(log10(100), log10(35e3), 120); % Hz

% IOP sweep.
IOP_mmHg = [5, 10, 15, 20, 25];
IOP_Pa = IOP_mmHg * 133.322;

options = defaultAcoustoelasticIOPHGOOptions();

% Current recommended atlas settings for this diagnostic-stage solver.
% These options may change as the matrix/tracker is made more robust.
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasBranchPolicy = "atlasA0";
options.atlasNumYPoints = 1000;
options.atlasTopNMinima = 18;

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

outputFolder = aeOutputFolder(launchFolder, 'iop_sweep');

writetable(summary.conditionTable, fullfile(outputFolder, 'iop_sweep_condition_summary.csv'));
writetable(summary.dispersionTable, fullfile(outputFolder, 'iop_sweep_dispersion_table.csv'));
if ~isempty(summary.branchTable)
    writetable(summary.branchTable, fullfile(outputFolder, 'iop_sweep_selected_branch_table.csv'));
end

save(fullfile(outputFolder, 'iop_sweep_workspace.mat'), ...
    'baseParams', 'options', 'IOP_mmHg', 'IOP_Pa', 'sweepResult', 'summary', 'launchFolder', '-v7.3');

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOIOPSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepOutputFolder', outputFolder);

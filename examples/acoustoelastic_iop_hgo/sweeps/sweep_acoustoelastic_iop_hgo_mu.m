clear; clc; close all;
launchFolder = pwd;
startup

%SWEEP_ACOUSTOELASTIC_IOP_HGO_MU Maintained shear-modulus sweep for the acoustoelastic IOP/HGO model.
% Prefer the short entrypoint:
%   sweep_mu
%
% New outputs are written to:
%   Results/ae_iop_hgo/mu_sweep

baseParams = struct();

% Geometry.
baseParams.R = 7.8e-3;                  % m
baseParams.thickness = 550e-6;          % m

% IOP fixed for this sweep.
baseParams.IOP = 15 * 133.322;          % Pa

% HGO parameters. mu is swept below; k1 and k2 are held fixed.
baseParams.mu = 50e3;                   % Pa, overwritten by sweep
baseParams.k1 = 25e3;                   % Pa
baseParams.k2 = 100;                    % dimensionless

% Densities and fluid bulk modulus.
baseParams.rho = 1060;                  % kg/m^3
baseParams.rhoF = 1000;                 % kg/m^3
baseParams.fluidBulkModulus = 2.2e9;    % Pa

% Frequency vector. Extend below 100 Hz in later diagnostics if the flexural
% onset remains unclear.
baseParams.frequency = logspace(log10(100), log10(35e3), 120); % Hz

% Shear-modulus sweep.
mu_kPa = [25, 50, 75, 100];
mu_Pa = mu_kPa * 1e3;

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
sweepConfig.Name = "mu";
sweepConfig.Label = "Shear modulus mu";
sweepConfig.Unit = "kPa";
sweepConfig.ValueScale = 1e3;
sweepConfig.ValueFormatter = "%.1f";

fprintf('\nAcoustoelastic IOP/HGO mu sweep\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('mu values: %s kPa\n', mat2str(mu_kPa));
fprintf('Fixed IOP: %.1f mmHg\n', baseParams.IOP / 133.322);
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSweep(baseParams, "mu", mu_Pa, options, sweepConfig);
summary = aeSummarizeSweep(sweepResult);

outputFolder = aeOutputFolder(launchFolder, 'mu_sweep');

writetable(summary.conditionTable, fullfile(outputFolder, 'mu_sweep_condition_summary.csv'));
writetable(summary.dispersionTable, fullfile(outputFolder, 'mu_sweep_dispersion_table.csv'));
if ~isempty(summary.branchTable)
    writetable(summary.branchTable, fullfile(outputFolder, 'mu_sweep_selected_branch_table.csv'));
end

save(fullfile(outputFolder, 'mu_sweep_workspace.mat'), ...
    'baseParams', 'options', 'mu_kPa', 'mu_Pa', 'sweepResult', 'summary', 'launchFolder', '-v7.3');

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);

assignin('base', 'AcoustoelasticIOPHGOMuSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOMuSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOMuSweepOutputFolder', outputFolder);

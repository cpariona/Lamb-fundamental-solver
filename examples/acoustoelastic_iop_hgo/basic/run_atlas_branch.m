clear; clc; close all;
launchFolder = pwd;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%RUN_ATLAS_BRANCH Maintained AE IOP/HGO atlas-branch example.
%
% This user-facing entrypoint calls the maintained solver directly and writes
% outputs under Results/ae_iop_hgo/atlas_branch.

params = struct();
params.R = 7.8e-3;
params.thickness = 550e-6;
params.mu = 50e3;
params.k1 = 25e3;
params.k2 = 100;
params.rho = 1060;
params.rhoF = 1000;
params.fluidBulkModulus = 2.2e9;
params.frequency = logspace(log10(300), log10(15e3), 35);
params.IOP = 15 * 133.322;

options = lamb.models.acoustoelastic_iop_hgo.defaultAcoustoelasticIOPHGOOptions();
options.M54_variant = "corrected";
options.normalizeRows = false;
options.usePhysicalCpWindow = false;
options.atlasNumYPoints = 300;
options.atlasTopNMinima = 12;
options.atlasBranchPolicy = "atlasA0";

result = lamb.models.acoustoelastic_iop_hgo.solveAcoustoelasticIOPHGOBranch(params, options);

outputFolder = resolveStudyOutputFolder(launchFolder, 'ae_iop_hgo', 'atlas_branch');
save(fullfile(outputFolder, 'atlas_branch_workspace.mat'), 'params', 'options', 'result');

validMask = result.validMask(:) & isfinite(result.phaseVelocity_mps(:));

fprintf('run_atlas_branch complete. Valid points: %d/%d. Output: %s\n', ...
    nnz(validMask), numel(result.phaseVelocity_mps), outputFolder);

figure('Color', 'w');
plot(result.frequency_Hz(validMask) ./ 1e3, result.phaseVelocity_mps(validMask), 'o-', 'LineWidth', 1.2);
grid on;
xlabel('Frequency [kHz]');
ylabel('Phase speed [m/s]');
title('AE IOP/HGO atlasA0 branch');
saveas(gcf, fullfile(outputFolder, 'atlas_branch_phase_speed.png'));

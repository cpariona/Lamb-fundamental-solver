clear; clc; close all;
launchFolder = pwd;
scriptFile = mfilename('fullpath');
repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(repoRoot);
addpath(fullfile(repoRoot, 'studies'));
configureStudyPath(repoRoot);

%AE_STUDY_IOP_ATLASA0 Maintained IOP sensitivity study for the AE IOP/HGO atlasA0 branch.
%
% Tables/workspace are written to:
%   Results/ae_iop_hgo/iop_sweep
%
% Figures are written next to this script under:
%   figures/iop_sweep

baseParams = aeSensitivityParameters();
options = aeSensitivityOptions("Robust");

IOP_mmHg = [5, 10, 15, 20, 25];
IOP_Pa = IOP_mmHg * 133.322;

sweepConfig = struct();
sweepConfig.Name = "iop";
sweepConfig.Label = "IOP";
sweepConfig.Unit = "mmHg";
sweepConfig.ValueScale = 133.322;
sweepConfig.ValueFormatter = "%.1f";

sweepMetadata = struct();
sweepMetadata.IOP_mmHg = IOP_mmHg;
sweepMetadata.IOP_Pa = IOP_Pa;
sweepMetadata.sweepConfig = sweepConfig;

fprintf('\nAE IOP/HGO IOP sensitivity study\n');
fprintf('Launch folder: %s\n', launchFolder);
fprintf('IOP values: %s mmHg\n', mat2str(IOP_mmHg));
fprintf('Frequency range: %.3g Hz to %.3g kHz\n', min(baseParams.frequency), max(baseParams.frequency)/1e3);
fprintf('Branch policy: %s\n\n', string(options.atlasBranchPolicy));

sweepResult = aeRunSensitivity(baseParams, "IOP", IOP_Pa, options, sweepConfig);
summary = aeSummarizeSensitivity(sweepResult);

outputFolder = aeWriteSensitivityOutputs(launchFolder, "iop_sweep", "iop_sweep", ...
    baseParams, options, sweepMetadata, sweepResult, summary);

fig = aePlotSensitivity(sweepResult, "Title", "AE IOP/HGO atlasA0 sensitivity to IOP");
figureFolder = aeSaveStudyFigure(fig, scriptFile, "iop_sweep", "iop_sweep_cp");

fprintf('\nCondition summary\n');
disp(summary.conditionTable);
fprintf('\nData files written to:\n%s\n', outputFolder);
fprintf('Figure files written to:\n%s\n', figureFolder);

assignin('base', 'AcoustoelasticIOPHGOIOPSweepResult', sweepResult);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepSummary', summary);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepOutputFolder', outputFolder);
assignin('base', 'AcoustoelasticIOPHGOIOPSweepFigureFolder', figureFolder);

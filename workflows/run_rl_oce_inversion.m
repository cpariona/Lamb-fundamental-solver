%% 1. USER CONFIGURATION
% Run each MATLAB Editor section in order. Re-run downstream sections when
% changing an upstream selection. Original OCE observations are never edited.
% Supply literal IDs and exact numeric condition values from the acquisition log.
oce_repository_root = "";  % Full path to OCE_Workflow (not its src folder)
study = struct();
study.experimentRoot = "";  % Experiment root with original Data/ and Results/
study.summaryFile = "";     % Optional root-relative override; default Results/<sub>/summary.mat
study.experimentId = "";
study.subexperimentId = "";
study.sampleId = "";
study.excitationMode = "Pulse";       % "Pulse" | "QH"
study.period_us = "";       % Literal saved Pulse period; "" for QH
study.repetitions = ["1","2","3"];
study.conditionId = "";     % Reviewed condition label; not inferred from folder
study.condition = struct(); % e.g. struct('strain_percent', exactRecordedDouble)
study.scanAxisIndex = 1;
study.direction = "left";   % "left" | "right" along scan axis
study.estimator = "kf_ridge"; % QH may use recorded "phase_gradient"
study.curve = "raw";        % k-f: "raw" | "smoothed"
study.fitFrequencySelection = "all"; % "all" | "interval" | "explicit"
study.fitFrequency_Hz = [];   % [low high] for interval; nominal Hz for explicit
study.fullBandReviewed = false; % Set true only after reviewing the full fitted band
study.observationMask = []; % [] retains documented source-quality selection
study.thicknessPolicy = "oce_directional_per_acquisition"; % or "explicit_constant"

% Rayleigh-Lamb native physical configuration (SI units).
% Density (kg/m^3), nu and mu bounds remain explicitly reviewed.
% With OCE thickness enabled, recorded directional measurements replace the
% placeholder thickness; an explicit constant is available for other studies.
study.fitConfig = struct( ...
    'branchName', "A0", 'freeParams', "mu_Pa", ...
    'fixedParams', struct('density_kgpm3', NaN, 'thickness_m', NaN, 'poisson_ratio', NaN), ...
    'initialGuess', struct('mu_Pa', NaN), ...
    'bounds', struct('mu_Pa', [NaN NaN]));
study.review = struct( ...
    'thicknessSource', "", 'thicknessJustification', "", ...
    'densitySource', "", 'fitParameterJustification', "", ...
    'modelAssumptionsJustification', "");

% Keep fitting and file writes off until data and physics have been reviewed.
study.reuseOnly = true;      % false explicitly enables a new native fit
study.saveResult = false;
study.showFigure = false;
study.exportFigure = false;
study.resultFile = "";
study.existingNativeResult = [];
study.existingAssembly = [];
study.plotTargetFrequency_Hz = []; % Pulse plot only; not fitting mask
study.displayLabel = "";
study.displaySubtitle = "";
study.figureFolder = "";
study.figureName = "";

%% 2. INITIALIZE LAMB AND OCE (MATLAB Editor Run Section)
% Run Section may use a temporary MATLAB file; never use mfilename here.
workflow_file = string(matlab.desktop.editor.getActiveFilename);
[~, active_name, active_ext] = fileparts(char(workflow_file));
if ismissing(workflow_file) || strlength(workflow_file) == 0 || ...
        ~strcmpi(string(active_name) + string(active_ext), "run_rl_oce_inversion.m")
    error('lamb:workflow:EditorFile', ...
        'Open run_rl_oce_inversion.m in MATLAB Editor and run this section.');
end
projectRoot = fileparts(fileparts(char(workflow_file)));
assert(isfile(fullfile(projectRoot, 'startup.m')), ...
    'lamb:workflow:RepositoryRoot', 'Lamb startup.m was not found.');
addpath(projectRoot);
startup;
addpath(fullfile(projectRoot, 'workflows', 'inversion'), '-end');
assert(strlength(string(oce_repository_root)) > 0 && ...
    isfile(fullfile(oce_repository_root, 'src', '+oce', '+results', ...
    'recoverSummaryObservations.m')), 'lamb:workflow:OceRepository', ...
    'Set oce_repository_root to the maintained local OCE_Workflow root.');
addpath(fullfile(oce_repository_root, 'src'), '-end');
assert(~isempty(which('oce.results.recoverSummaryObservations')), ...
    'lamb:workflow:OceRecovery', 'OCE recovery API is not accessible.');
assert(~isempty(which('prepareOceInversionObservations')), ...
    'lamb:workflow:PreparationPath', 'Workflow preparation is not accessible.');

%% 3. RECOVER ORIGINAL OBSERVATIONS (no fitting)
% Section 1 must contain a real summary path, exact IDs, and a nonempty
% condition. OCE owns all MAT/schema validation and source recovery.
study=resolveOceInversionPaths(study,"RayleighLamb");
inputs=prepareOceInversionObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;experimental=assembly.experimental;

%% 4. REVIEW OBSERVATIONS (no fitting)
% Keep DC, invalid/excluded rows and all repetitions in their original order.
% observationReview retains original source flags, bins and frequency mappings.
assert(isequal(experimental.validMask,observationReview.validMask));
disp(sourceMetadata);
disp(observationReview);
fprintf('Selected %d of %d original observations.\n', ...
    nnz(experimental.validMask), numel(experimental.validMask));

%% 5. REVIEW RAYLEIGH-LAMB PHYSICS AND CONFIGURATION
[experimental,fitConfig,review]=reviewOceInversionPhysics( ...
    study,assembly,observationReview,"RayleighLamb");
assembly.experimental=experimental;
study.fitConfig=fitConfig; % Keep review as derived output, not editable study input.

%% 6. RUN OR REUSE THE NATIVE INVERSE FIT (explicit opt-in)
[nativeResult,reusedResult,fitConfig]=fitOceInversionNative( ...
    study,assembly,experimental,fitConfig,review,sourceFiles,"RayleighLamb");

%% 7. OPTIONAL PERSISTENCE (no overwrite)
inputs.assembly=assembly;
studyRecord=persistOceInversionStudy( ...
    study,inputs,nativeResult,fitConfig,review,reusedResult,projectRoot,"RayleighLamb");
fprintf('RL %s: %d / %d selected rows; reused=%d; RMSE=%.15g m/s; optimizer exit=%d\n', ...
    nativeResult.branchName,nnz(nativeResult.validMask),numel(nativeResult.validMask), ...
    reusedResult,nativeResult.metrics.RMSE,nativeResult.optimizer.exitFlag);

%% 8. OPTIONAL VISUALIZATION (FIG and 300-dpi TIF)
[fig,figureEvidence,figurePaths]=renderOceInversionStudy( ...
    study,inputs,nativeResult,review,"RayleighLamb");

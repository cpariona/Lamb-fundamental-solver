%% 1. USER CONFIGURATION
% Run each MATLAB Editor section in order. Change options here and rerun
% downstream sections; never average, repair or overwrite original OCE data.
oce_repository_root = ""; % Full local OCE_Workflow repository root
study = struct();
study.experimentRoot = ""; % Original experiment root
study.summaryFile = "";    % Optional root-relative override; default Results/<sub>/summary.mat
study.experimentId = "";
study.subexperimentId = "";
study.sampleId = "";
study.excitationMode = "Pulse";      % "Pulse" | "QH"
study.period_us = "";      % Literal Pulse period, "" for QH
study.repetitions = ["1","2","3"];
study.conditionId = "";
study.condition = struct(); % e.g. struct('strain_percent', exactRecordedDouble)
study.scanAxisIndex = 1;
study.direction = "left";  % "left" | "right" along one principal scan axis
study.estimator = "kf_ridge";
study.curve = "raw";       % "raw" | "smoothed"
study.fitFrequencySelection = "all"; % "all" | "interval" | "explicit"
study.fitFrequency_Hz = [];  % Hz: [low high] or physical requested frequencies
study.fullBandReviewed = false; % Set true only after reviewing the full fitted band

% Plate A0 native physical inputs (SI); OCE source thickness is per row.
% The scalar thickness_m is a non-operative reference under the OCE policy.
study.physical = struct('density_kgpm3', NaN, 'thickness_m', NaN);
study.review = struct( ...
    'thicknessSource', "", 'thicknessJustification', "", ...
    'densitySource', "", 'modelAssumptionsJustification', "");
study.fitOptions = struct(); % Native Plate SVD qualification settings
study.thicknessPolicy = "oce_directional_per_acquisition"; % or "explicit_constant_current_thickness" | "oce_reference_acquisition"
study.thicknessReferenceSourceIndex = NaN; % Only for scalar reference acquisition

% Conservative defaults: review data/physics before enabling a fit.
study.reuseOnly = true;      % false explicitly enables native fitting
study.saveResult = false;
study.showFigure = false;
study.exportFigure = false;
study.resultFile = "";
study.existingNativeResult = [];
study.existingAssembly = [];
study.plotTargetFrequency_Hz = []; % Pulse presentation only
study.displayLabel = "";
study.displaySubtitle = "";
study.figureFolder = "";
study.figureName = "";

%% 2. INITIALIZE LAMB AND OCE (MATLAB Editor Run Section)
% MATLAB may run sections from Temp; resolve the real open Editor file.
workflow_file = string(matlab.desktop.editor.getActiveFilename);
[~, active_name, active_ext] = fileparts(char(workflow_file));
if ismissing(workflow_file) || strlength(workflow_file) == 0 || ...
        ~strcmpi(string(active_name) + string(active_ext), "run_ae_plate_oce_inversion.m")
    error('lamb:workflow:EditorFile', ...
        'Open run_ae_plate_oce_inversion.m in MATLAB Editor and run this section.');
end
projectRoot = fileparts(fileparts(fileparts(char(workflow_file))));
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

%% 3. RECOVER AND REVIEW ORIGINAL OBSERVATIONS (no fitting)
% Source/condition/repetition identities and original rows are retained.
if ~isfield(study,'estimator'),study.estimator="kf_ridge";end
assert(study.estimator=="kf_ridge",'The reviewed Plate study uses k-f observations.');
study=resolveOceInversionPaths(study,"Plate");
inputs=prepareOceInversionObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;
experimental=assembly.experimental;
frequency=experimental.frequency_Hz;validMask=experimental.validMask;
sourceIndex=observationReview.sourceIndex;bins=observationReview.sourceBinIndex;
repetitionId=observationReview.repetitionId;ridge=observationReview.ridgeValid;
interpolated=observationReview.interpolated;extrapolated=observationReview.extrapolated;
graphicRequested=zeros(0,1);
if study.excitationMode=="Pulse"&&study.showFigure
    graphicRequested=unique(graphicSamplingMapping.requestedFrequency_Hz,'stable');
end
disp(sourceMetadata);
disp(observationReview);
fprintf('Selected %d of %d original observations.\n', nnz(validMask), numel(validMask));
%% 4. REVIEW CURRENT PLATE PHYSICAL INPUTS
[experimental,physical,review]=reviewOceInversionPhysics( ...
    study,assembly,observationReview,"Plate");
assembly.experimental=experimental;
study.physical=physical; % Keep review as derived output, not editable study input.

%% 5. RUN OR REUSE THE NATIVE PLATE A0 FIT (explicit opt-in)
[nativeResult,reusedResult,physical]=fitOceInversionNative( ...
    study,assembly,experimental,physical,review,sourceFiles,"Plate");

%% 6. OPTIONAL PERSISTENCE (no overwrite)
inputs.assembly=assembly;
studyRecord=persistOceInversionStudy( ...
    study,inputs,nativeResult,physical,review,reusedResult,projectRoot,"Plate");
fprintf('AE Plate: %d selected rows; reused=%d; alpha=%.15g Pa; gamma=%.15g Pa; RMSE=%.15g Pa; accepted=%d\n', ...
    nnz(experimental.validMask),reusedResult,nativeResult.alpha_Pa, ...
    nativeResult.gamma_Pa,nativeResult.regressionRMSE_Pa,nativeResult.accepted);

%% 7. OPTIONAL VISUALIZATION (FIG and 300-dpi TIF)
[fig,figureEvidence,figurePaths]=renderOceInversionStudy( ...
    study,inputs,nativeResult,review,"Plate");

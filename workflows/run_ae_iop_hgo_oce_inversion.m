%% 1. USER CONFIGURATION
% Run each MATLAB Editor section in order. Change options here and rerun
% downstream sections; never average, repair or overwrite original OCE data.
% Match study.condition types to OCE's persisted acquisition_table; the
% maintained XLSX loader stores numeric Excel measurements as text.
% Override this preference with an explicit OCE_Workflow checkout root if needed.
oce_repository_root = string(getpref('LambFundamentalSolver','oceRepositoryRoot',''));
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
study.condition = struct(); % e.g. struct('added_mass_g', "9.053886") if stored as text
study.scanAxisIndex = 1;
study.direction = "left";  % "left" | "right" along one principal scan axis
study.estimator = "kf_ridge";
study.curve = "raw";       % "raw" | "smoothed"
study.fitFrequencySelection = "interval"; % "all" | "interval" | "explicit"
study.fitFrequency_Hz = [];  % Hz: [low high] or physical requested frequencies
study.fullBandReviewed = false; % Set true only after reviewing the full fitted band

% AE IOP/HGO inputs (canonical SI). Every value is a researcher decision: no
% defaults are inferred and NaN/empty placeholders are rejected. Only the
% official atlasA0 curve is fitted; S0 is rejected. executionProfile changes
% computational cost only ("Fast" | "Balanced" | "Robust").
% Selected observations must lie at or above the native atlasA0 initialization
% anchor (300 Hz by default); lower selected rows are an error, not trimmed.
% Move each free parameter out of fixedPhysical into initialGuess and bounds.
% Free parameters may be iop_Pa, mu_Pa, k1_Pa and k2 (dimensionless). Thickness is
% one reviewed scalar current full thickness; OCE directional thickness is not used.
study.ae = struct('branchName',"atlasA0",'executionProfile',"", ...
    'freeParams',strings(0,1), ...
    'fixedPhysical',struct('radius_m',NaN,'thickness_m',NaN,'iop_Pa',NaN, ...
        'mu_Pa',NaN,'k1_Pa',NaN,'k2',NaN,'density_kgpm3',NaN, ...
        'fluidDensity_kgpm3',NaN,'fluidBulkModulus_Pa',NaN), ...
    'initialGuess',struct(),'bounds',struct());
study.review = struct( ...
    'thicknessSource',"",'thicknessJustification',"",'densitySource',"", ...
    'radiusSource',"",'iopSource',"",'fluidSource',"", ...
    'fitParameterJustification',"",'modelAssumptionsJustification',"");

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
        ~strcmpi(string(active_name) + string(active_ext), "run_ae_iop_hgo_oce_inversion.m")
    error('lamb:workflow:EditorFile', ...
        'Open run_ae_iop_hgo_oce_inversion.m in MATLAB Editor and run this section.');
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
    'Set oce_repository_root or the LambFundamentalSolver/oceRepositoryRoot MATLAB preference.');
addpath(fullfile(oce_repository_root, 'src'), '-end');
assertOceInversionProducerPath(oce_repository_root);
assert(~isempty(which('prepareOceInversionObservations')), ...
    'lamb:workflow:PreparationPath', 'Workflow preparation is not accessible.');

%% 3. RECOVER AND REVIEW ORIGINAL OBSERVATIONS (no fitting)
% Source/condition/repetition identities, the complete original frequency
% axis and the fixed mask are retained.
if ~isfield(study,'estimator'),study.estimator="kf_ridge";end
study=resolveOceInversionPaths(study,"AcoustoelasticIOPHGO");
inputs=prepareOceInversionObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;
experimental=assembly.experimental;
validMask=experimental.validMask;
disp(sourceMetadata);
disp(observationReview);
fprintf('Selected %d of %d original observations.\n', nnz(validMask), numel(validMask));

%% 4. REVIEW AE IOP/HGO PHYSICAL INPUTS (no forward solve)
% Translates canonical SI inputs to native symbols and checks the full axis,
% the fixed mask and the selected-frequency anchor.
[experimental,physics,review]=reviewOceInversionPhysics( ...
    study,assembly,observationReview,"AcoustoelasticIOPHGO");
assembly.experimental=experimental;

%% 5. RUN OR REUSE THE NATIVE AE IOP/HGO FIT (explicit opt-in)
[nativeResult,reusedResult,physics]=fitOceInversionNative( ...
    study,assembly,experimental,physics,review,sourceFiles,"AcoustoelasticIOPHGO");

%% 6. OPTIONAL PERSISTENCE (no overwrite)
inputs.assembly=assembly;
studyRecord=persistOceInversionStudy( ...
    study,inputs,nativeResult,physics,review,reusedResult,projectRoot,"AcoustoelasticIOPHGO");
fprintf('AE IOP/HGO atlasA0: %d selected rows; reused=%d; RMSE=%.15g m/s\n', ...
    nnz(experimental.validMask),reusedResult,nativeResult.metrics.RMSE);
disp(nativeResult.bestParams);
% A numerical fit does not validate the biomechanical model or its assumptions.

%% 7. OPTIONAL VISUALIZATION (FIG and 300-dpi TIF)
[fig,figureEvidence,figurePaths]=renderOceInversionStudy( ...
    study,inputs,nativeResult,review,"AcoustoelasticIOPHGO");

%% 1. USER CONFIGURATION
% Run each MATLAB Editor section in order. Re-run downstream sections when
% changing an upstream selection. Original OCE observations are never edited.
% Match each condition value's MATLAB type to the persisted OCE acquisition_table.
% The maintained OCE XLSX loader imports columns as text; numeric Excel cells
% may therefore require literal string selectors (legacy double tables differ).
% Override this preference with an explicit OCE_Workflow checkout root if needed.
oce_repository_root = string(getpref('LambFundamentalSolver','oceRepositoryRoot',''));
study = struct();
study.experimentRoot = "";  % Experiment root with original Data/ and Results/
study.summaryFile = "";     % Optional root-relative override; default Results/<sub>/summary.mat
study.experimentId = "";
study.subexperimentId = "";
study.sampleId = "";
study.excitationMode = "Pulse";       % "Pulse" | "QH"
study.period_us = "";       % Literal saved Pulse period; "" for QH
study.repetitions = ["1"];  % Native mRLFE rejects duplicate frequencies: see section 5
study.conditionId = "";     % Reviewed condition label; not inferred from folder
study.condition = struct(); % e.g. struct('added_mass_g', "9.053886") if stored as text
study.scanAxisIndex = 1;
study.direction = "left";   % "left" | "right" along scan axis
study.estimator = "kf_ridge";
study.curve = "raw";        % k-f: "raw" | "smoothed"
study.fitFrequencySelection = "all"; % "all" | "interval" | "explicit"
study.fitFrequency_Hz = [];   % [low high] for interval; nominal Hz for explicit
study.fullBandReviewed = false; % Set true only after reviewing the full fitted band
study.observationMask = []; % [] retains documented source-quality selection
% mRLFE uses ONE scalar current full thickness (the native model has no
% per-observation geometry). Choose "oce_median_per_case" (median of one OCE
% directional thickness per selected acquisition) or "explicit_constant"
% (then set fixedParams.thickness_m). The empty placeholder is rejected.
study.thicknessPolicy = "";

% mRLFE native physical configuration, canonical SI names; no value is defaulted.
% Every physical input below must be supplied (fixed) or fitted (free, with a
% finite initial guess and bounds): mu_Pa, etaS_Pas (Pa s), density_kgpm3,
% thickness_m, poisson_ratio (native support 0.49 <= nu < 0.5),
% fluidDensity_kgpm3 and fluidSoundSpeed_mps. Thickness and fluid properties are
% always fixed. branchName is "A0Like" or "S0Like". Optional solverOptions and
% fitOptions are forwarded unchanged (numerical options, not physics).
study.fitConfig = struct( ...
    'branchName', "", 'freeParams', "mu_Pa", ...
    'fixedParams', struct('density_kgpm3', NaN, 'thickness_m', NaN, ...
        'poisson_ratio', NaN, 'etaS_Pas', NaN, ...
        'fluidDensity_kgpm3', NaN, 'fluidSoundSpeed_mps', NaN), ...
    'initialGuess', struct('mu_Pa', NaN), ...
    'bounds', struct('mu_Pa', [NaN NaN]));
% Researcher-supplied provenance and assumptions; not solver-calculated support.
study.review = struct( ...
    'thicknessSource', "", 'thicknessJustification', "", ...
    'densitySource', "", 'fluidSource', "", 'fitParameterJustification', "", ...
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
        ~strcmpi(string(active_name) + string(active_ext), "run_mrlfe_oce_inversion.m")
    error('lamb:workflow:EditorFile', ...
        'Open run_mrlfe_oce_inversion.m in MATLAB Editor and run this section.');
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

%% 3. RECOVER ORIGINAL OBSERVATIONS (no fitting)
% Section 1 must contain a real summary path, exact IDs, and a nonempty
% condition. OCE owns all MAT/schema validation and source recovery.
study=resolveOceInversionPaths(study,"mRLFE");
inputs=prepareOceInversionObservations(study);
assembly=inputs.assembly;observationReview=inputs.observationReview;
frequencySelectionMapping=inputs.frequencySelectionMapping;
graphicSamplingMapping=inputs.graphicSamplingMapping;
sourceMetadata=inputs.sourceMetadata;sourceFiles=inputs.sourceResultFiles;
inputHashes=inputs.inputHashes;experimental=assembly.experimental;

%% 4. REVIEW OBSERVATIONS (no fitting)
% Keep DC, invalid/excluded rows and all repetitions in their original order.
% The native mRLFE axis must be positive, finite and strictly ascending over
% ALL rows: an excluded DC row, repeated frequencies (pooled repetitions) or an
% unordered axis are rejected in section 5, never trimmed, sorted or averaged.
assert(isequal(experimental.validMask,observationReview.validMask));
disp(sourceMetadata);
disp(observationReview);
fprintf('Selected %d of %d original observations.\n', ...
    nnz(experimental.validMask), numel(experimental.validMask));

%% 5. REVIEW mRLFE PHYSICS AND CONFIGURATION (native preflight, no fit)
[experimental,fitConfig,review]=reviewOceInversionPhysics( ...
    study,assembly,observationReview,"mRLFE");
assembly.experimental=experimental;
study.fitConfig=fitConfig; % Keep review as derived output, not editable study input.

%% 6. RUN OR REUSE THE NATIVE INVERSE FIT (explicit opt-in)
[nativeResult,reusedResult,fitConfig]=fitOceInversionNative( ...
    study,assembly,experimental,fitConfig,review,sourceFiles,"mRLFE");

%% 7. OPTIONAL PERSISTENCE (no overwrite)
inputs.assembly=assembly;
studyRecord=persistOceInversionStudy( ...
    study,inputs,nativeResult,fitConfig,review,reusedResult,projectRoot,"mRLFE");
fprintf('mRLFE %s: %d / %d selected rows; reused=%d; RMSE=%.15g m/s; optimizer exit=%d\n', ...
    nativeResult.branchName,nnz(nativeResult.validMask),numel(nativeResult.validMask), ...
    reusedResult,nativeResult.metrics.RMSE,nativeResult.optimizer.exitFlag);

%% 8. OPTIONAL VISUALIZATION (FIG and 300-dpi TIF)
[fig,figureEvidence,figurePaths]=renderOceInversionStudy( ...
    study,inputs,nativeResult,review,"mRLFE");

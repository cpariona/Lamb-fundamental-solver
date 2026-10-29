%% 1. USER CONFIGURATION
% Human-facing batch for previously processed OCE experiments.
% Inspect the discovered cases and native physics before enabling execution.
experiment_root = ""; % Full folder containing the experiment's Results/
inversions_root = ""; % Optional absolute root; default is beside OCE_Experiments
oce_repository_root = ""; % Local OCE_Workflow checkout
subexperiments = "all"; % "all" or exact recorded subexperiment IDs
condition_keys = "strain_percent"; % Exact mechanical metadata field(s) to group; edit as needed
families = ["RayleighLamb","Plate"];
repetitions = "all"; % "all" or exact recorded repetition IDs
scan_axes = "all"; % "all" or numeric scan axis indices
directions = ["left","right"]; % "all" or a subset
curve = "raw"; % "raw" | "smoothed"
fit_frequency_selection = "all"; % "all" | "interval" | "explicit"
fit_frequency_hz = []; % [low high] or explicitly reviewed target Hz
full_band_reviewed = false; % Required when using "all"
plot_target_frequency_hz = []; % Optional Pulse display requests only
thickness_policy = "oce_median_per_case"; % Default for batch; "oce_directional_per_acquisition" retains per-row thickness

% Shared material and separately reviewed current full geometry (SI).
% The batch median policy derives one scalar thickness from selected OCE acquisitions;
% the per-acquisition option instead uses each recorded directional thickness.
material = struct('density_kgpm3',NaN,'poisson_ratio',NaN);
geometry = struct('thickness_m',NaN);
density_source = "";
thickness_source = ""; % Used only when a constant thickness is reviewed
thickness_justification = "";
rl_mu_initial_guess_Pa = NaN;
rl_mu_bounds_Pa = [NaN NaN];
rl_fit_parameter_justification = "";
rl_model_assumptions_justification = "";
plate_model_assumptions_justification = "";
plate_fit_options = struct();

% Safe defaults: plan first, then enable an authorized new run.
run_batches = false;
reuse_only = false;
save_results = true;
export_figures = true;
continue_on_error = true;

%% 2. INITIALIZE AND DISCOVER OCE SOURCES
% Use maintained OCE recovery; never interpret PhaseSpeed.mat schemas here.
workflow_file = string(matlab.desktop.editor.getActiveFilename);
[~, active_name, active_ext] = fileparts(char(workflow_file));
assert(~ismissing(workflow_file) && ...
    string(active_name)+string(active_ext)=="run_experiment_inversion_batch.m", ...
    'lamb:workflow:EditorFile', ...
    'Open this exact workflow in MATLAB Editor and use Run Section.');
repo_root = fileparts(fileparts(char(workflow_file)));
addpath(repo_root);
startup;
addpath(fullfile(repo_root,"workflows","inversion"),"-end");
assert(isfile(fullfile(oce_repository_root,"src","+oce","+results", ...
    "recoverSummaryObservations.m")), ...
    'lamb:workflow:OceRepository','Set the maintained OCE checkout root.');
addpath(fullfile(oce_repository_root,"src"),"-end");
assert(isfolder(experiment_root),'lamb:workflow:ExperimentRoot', ...
    'Select an existing OCE experiment root.');
assert(~isempty(families) && all(ismember(families,["RayleighLamb","Plate"])) && ...
    numel(unique(families))==numel(families), ...
    'lamb:workflow:Families','Select distinct supported families.');

summary_files = dir(fullfile(experiment_root,"Results","*","summary.mat"));
assert(~isempty(summary_files),'lamb:workflow:NoSummaries', ...
    'No per-subexperiment OCE summary.mat files were found.');
available_subexperiments = strings(numel(summary_files),1);
for j = 1:numel(summary_files)
    [~, available_subexperiments(j)] = fileparts(summary_files(j).folder);
end
if isequal(string(subexperiments),"all")
    chosen = available_subexperiments;
else
    chosen = string(subexperiments(:));
    assert(numel(unique(chosen))==numel(chosen) && ...
        all(ismember(chosen,available_subexperiments)), ...
        'lamb:workflow:UnknownSubexperiment', ...
        'Select only discovered subexperiments, without duplicates.');
end

% Construct native requests from one unit-qualified physical configuration.
% The fitting boundary translates SI labels to the RL solver's math symbols.
rl_fit = struct('branchName',"A0",'freeParams',"mu_Pa", ...
    'fixedParams',struct('density_kgpm3',material.density_kgpm3, ...
        'thickness_m',geometry.thickness_m,'poisson_ratio',material.poisson_ratio), ...
    'initialGuess',struct('mu_Pa',rl_mu_initial_guess_Pa), ...
    'bounds',struct('mu_Pa',rl_mu_bounds_Pa));
rl_review = struct('thicknessSource',thickness_source, ...
    'thicknessJustification',thickness_justification, ...
    'densitySource',density_source, ...
    'fitParameterJustification',rl_fit_parameter_justification, ...
    'modelAssumptionsJustification',rl_model_assumptions_justification);
plate_physical = struct('density_kgpm3',material.density_kgpm3, ...
    'thickness_m',geometry.thickness_m);
plate_review = struct('thicknessSource',thickness_source, ...
    'thicknessJustification',thickness_justification, ...
    'densitySource',density_source, ...
    'modelAssumptionsJustification',plate_model_assumptions_justification);

% Each family receives independently reviewed case structs.
case_lists = cell(numel(families),1);
for k = 1:numel(families),case_lists{k}=struct([]);end
for sub = chosen(:)'
    summary_path = fullfile(experiment_root,"Results",sub,"summary.mat");
    saved = load(summary_path,"experiment");
    recovered = oce.results.recoverSummaryObservations(experiment_root,saved.experiment);
    assert(~isempty(recovered),'lamb:workflow:NoSources','Summary has no recovered sources.');
    metadata = vertcat(recovered.acquisition_metadata);

    % Physical condition keys are explicit. Subexperiment summaries may
    % group only by frequency, so their design cannot define mechanical state.
    mechanical_keys = string(condition_keys(:));
    assert(~isempty(mechanical_keys) && ...
        all(ismember(mechanical_keys,string(metadata.Properties.VariableNames))) && ...
        ~any(ismember(mechanical_keys,["frequency_Hz","period_us","rep_id"])), ...
        'lamb:workflow:ConditionKeys', ...
        'Select recorded mechanical-condition metadata keys explicitly.');
    group_columns = ["experiment_id","sample_id","excitation_type",mechanical_keys'];
    if ismember("period_us",string(metadata.Properties.VariableNames))
        group_columns(end+1)="period_us";
    end
    groups = unique(metadata(:,group_columns),"rows","stable");
    for g = 1:height(groups)
        group_rows = ismember(metadata(:,group_columns),groups(g,:),"rows");
        mode = string(groups.excitation_type(g));
        assert(ismember(mode,["quasi_harmonic","pulse"]), ...
            'lamb:workflow:Mode','Unsupported recorded excitation type.');
        period = "";
        if mode=="pulse"
            assert(ismember("period_us",string(groups.Properties.VariableNames)), ...
                'lamb:workflow:PulsePeriod','Recorded Pulse period is missing.');
            period = string(groups.period_us(g)); % Keep literal recorded text.
            assert(~ismissing(period) && strlength(period)>0, ...
                'lamb:workflow:PulsePeriod','A Pulse period is not recorded.');
        end
        requested_reps = unique(string(metadata.rep_id(group_rows)),"stable");
        if ~isequal(string(repetitions),"all")
            requested_reps = string(repetitions(:));
            assert(all(ismember(requested_reps,string(metadata.rep_id(group_rows)))), ...
                'lamb:workflow:Repetitions','A requested repetition is missing.');
        end
        source_rows = find(group_rows & ismember(string(metadata.rep_id),requested_reps));
        assert(~isempty(source_rows),'lamb:workflow:NoSources','Empty acquisition group.');
        first_directions = recovered(source_rows(1)).scientific_result.dispersion.directions;
        if isequal(string(scan_axes),"all")
            axes_to_use = unique([first_directions.scan_axis_index],"stable");
        else
            axes_to_use = scan_axes(:)';
        end
        if isequal(string(directions),"all")
            sides_to_use = unique(string({first_directions.direction}),"stable");
        else
            sides_to_use = string(directions(:))';
        end
        condition = table2struct(groups(g,mechanical_keys));
        % Output identity only; recorded condition values remain unchanged.
        condition_id = oceInversionConditionId(mechanical_keys,condition);
        for ax = axes_to_use
            for side = sides_to_use
                assert(ismember(side,["left","right"]), ...
                    'lamb:workflow:Direction','Select left/right signed directions.');
                % A batch case requires the same signed direction in every rep.
                for source_row = source_rows(:)'
                    identities = recovered(source_row).scientific_result.dispersion.directions;
                    assert(any([identities.scan_axis_index]==ax & ...
                        string({identities.direction})==side), ...
                        'lamb:workflow:MissingDirection', ...
                        'Not every acquisition has the selected signed direction.');
                end
                study = struct('experimentId',string(groups.experiment_id(g)), ...
                    'subexperimentId',sub,'sampleId',string(groups.sample_id(g)), ...
                    'excitationMode',"QH",'period_us',period,'repetitions',requested_reps(:)', ...
                    'conditionId',condition_id, ...
                    'condition',condition,'scanAxisIndex',double(ax), ...
                    'direction',side,'estimator',"kf_ridge",'curve',curve, ...
                    'fitFrequencySelection',fit_frequency_selection,'fitFrequency_Hz',fit_frequency_hz, ...
                    'fullBandReviewed',full_band_reviewed, ...
                    'plotTargetFrequency_Hz',plot_target_frequency_hz, ...
                    'displayLabel',"",'displaySubtitle',"",'outputTag',"");
                if mode=="pulse",study.excitationMode="Pulse";end
                for k = 1:numel(families)
                    current = study;
                    current.thicknessPolicy=thickness_policy;
                    if families(k)=="RayleighLamb"
                        current.fitConfig=rl_fit;
                        current.review=rl_review;
                        current.observationMask=[];
                    else
                        current.physical=plate_physical;
                        current.review=plate_review;
                        current.fitOptions=plate_fit_options;
                        current.thicknessReferenceSourceIndex=NaN;
                    end
                    if isempty(case_lists{k})
                        case_lists{k}=current;
                    else
                        case_lists{k}(end+1)=current;
                    end
                end
            end
        end
    end
end

%% 3. PREVIEW REVIEWED CASES AND OUTPUT DESTINATIONS
% No fitting or writes. Inspect original condition values in each case.
plans = cell(numel(families),1);
for k = 1:numel(families)
    plan = struct('experimentRoot',string(experiment_root), ...
        'oceRepositoryRoot',string(oce_repository_root), ...
        'cases',case_lists{k},'execute',false);
    if strlength(strtrim(string(inversions_root)))>0
        plan.inversionsRoot=string(inversions_root);
    end
    preview = runOceInversionBatch(plan,families(k));
    fprintf('\n%s: %d planned inversions\n',families(k),height(preview.report));
    disp(preview.report);
    for j = 1:numel(case_lists{k})
        fprintf('Case %d: %s | %s | %s | reps: %s\n',j, ...
            case_lists{k}(j).subexperimentId, ...
            case_lists{k}(j).conditionId, ...
            case_lists{k}(j).direction, ...
            strjoin(string(case_lists{k}(j).repetitions),","));
        disp(case_lists{k}(j).condition);
    end
    plans{k}=plan;
end

%% 4. EXECUTE ONLY AFTER EXPLICIT REVIEW
batch_outputs = cell(numel(families),1);
if ~run_batches
    disp("Dry-run complete. Review the cases and set run_batches=true to execute.");
else
    recovery = []; % One active summary; source hashes are checked for every case.
    for k = 1:numel(families)
        plan = plans{k};
        plan.execute = true;
        plan.reuseOnly = reuse_only;
        plan.saveResult = save_results;
        plan.exportFigure = export_figures;
        plan.continueOnError = continue_on_error;
        [batch_outputs{k},recovery] = runOceInversionBatch(plan,families(k),recovery);
        disp(batch_outputs{k}.report);
    end
    recovery = []; % Release source products after this explicitly executed batch.
end

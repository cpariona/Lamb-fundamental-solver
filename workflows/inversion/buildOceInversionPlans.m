function plans = buildOceInversionPlans(config)
%BUILDOCEINVERSIONPLANS Discover saved OCE acquisitions and build read-only plans.
% CONFIG explicitly supplies the discovery, observation and physical-review
% fields from run_experiment_inversion section 1; no configuration defaults
% are supplied here. Initialize Lamb and add workflows/inversion to the path
% before calling. The configured OCE src is checked and added below.
% Required fields (same names and units as the human workflow):
%   experiment_root, inversions_root, oce_repository_root, subexperiments,
%   condition_keys, families, repetitions, scan_axes, directions, curve,
%   fit_frequency_selection, fit_frequency_hz, full_band_reviewed,
%   plot_target_frequency_hz, thickness_policy, material, geometry,
%   density_source, thickness_source, thickness_justification,
%   rl_mu_initial_guess_Pa, rl_mu_bounds_Pa, rl_fit_parameter_justification,
%   rl_model_assumptions_justification, plate_model_assumptions_justification,
%   plate_fit_options. Empty/NaN review placeholders remain unapproved inputs.
% Returns a column cell array in CONFIG.families order. Every plan has
% execute=false and the existing runOceInversionBatch contract. Discovery
% recovers each selected summary once through OCE, preserving exact condition
% values/types and literal Pulse periods. No fitting, result writes, output
% preflight or scientific approval is performed. Review cases and use
% runOceInversionBatch for preview and separately authorized execution.
assert(isstruct(config) && isscalar(config), ...
    'lamb:workflow:Configuration','Supply one explicit configuration struct.');
experiment_root = config.experiment_root;
inversions_root = config.inversions_root;
oce_repository_root = config.oce_repository_root;
subexperiments = config.subexperiments;
condition_keys = config.condition_keys;
families = config.families;
repetitions = config.repetitions;
scan_axes = config.scan_axes;
directions = config.directions;
curve = config.curve;
fit_frequency_selection = config.fit_frequency_selection;
fit_frequency_hz = config.fit_frequency_hz;
full_band_reviewed = config.full_band_reviewed;
plot_target_frequency_hz = config.plot_target_frequency_hz;
thickness_policy = config.thickness_policy;
material = config.material;
geometry = config.geometry;
density_source = config.density_source;
thickness_source = config.thickness_source;
thickness_justification = config.thickness_justification;
rl_mu_initial_guess_Pa = config.rl_mu_initial_guess_Pa;
rl_mu_bounds_Pa = config.rl_mu_bounds_Pa;
rl_fit_parameter_justification = config.rl_fit_parameter_justification;
rl_model_assumptions_justification = config.rl_model_assumptions_justification;
plate_model_assumptions_justification = config.plate_model_assumptions_justification;
plate_fit_options = config.plate_fit_options;

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

plans = cell(numel(families),1);
for k = 1:numel(families)
    plan = struct('experimentRoot',string(experiment_root), ...
        'oceRepositoryRoot',string(oce_repository_root), ...
        'cases',case_lists{k},'execute',false);
    if strlength(strtrim(string(inversions_root)))>0
        plan.inversionsRoot=string(inversions_root);
    end
    plans{k}=plan;
end
end

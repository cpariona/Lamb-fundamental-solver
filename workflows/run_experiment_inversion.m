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
    string(active_name)+string(active_ext)=="run_experiment_inversion.m", ...
    'lamb:workflow:EditorFile', ...
    'Open this exact workflow in MATLAB Editor and use Run Section.');
repo_root = fileparts(fileparts(char(workflow_file)));
addpath(repo_root);
startup;
addpath(fullfile(repo_root,"workflows","inversion"),"-end");
config = struct( ...
    'experiment_root',experiment_root, 'inversions_root',inversions_root, ...
    'oce_repository_root',oce_repository_root, 'subexperiments',subexperiments, ...
    'condition_keys',condition_keys, 'families',families, ...
    'repetitions',repetitions, 'scan_axes',scan_axes, ...
    'directions',directions, 'curve',curve, ...
    'fit_frequency_selection',fit_frequency_selection, 'fit_frequency_hz',fit_frequency_hz, ...
    'full_band_reviewed',full_band_reviewed, 'plot_target_frequency_hz',plot_target_frequency_hz, ...
    'thickness_policy',thickness_policy, 'material',material, ...
    'geometry',geometry, 'density_source',density_source, ...
    'thickness_source',thickness_source, 'thickness_justification',thickness_justification, ...
    'rl_mu_initial_guess_Pa',rl_mu_initial_guess_Pa, 'rl_mu_bounds_Pa',rl_mu_bounds_Pa, ...
    'rl_fit_parameter_justification',rl_fit_parameter_justification, 'rl_model_assumptions_justification',rl_model_assumptions_justification, ...
    'plate_model_assumptions_justification',plate_model_assumptions_justification, 'plate_fit_options',plate_fit_options);
plans = buildOceInversionPlans(config);

%% 3. PREVIEW REVIEWED CASES AND OUTPUT DESTINATIONS
% No fitting or writes. Inspect original condition values in each case.
for k = 1:numel(families)
    plan = plans{k};
    preview = runOceInversionBatch(plan,families(k));
    fprintf('\n%s: %d planned inversions\n',families(k),height(preview.report));
    disp(preview.report);
    for j = 1:numel(plan.cases)
        fprintf('Case %d: %s | %s | %s | reps: %s\n',j, ...
            plan.cases(j).subexperimentId, ...
            plan.cases(j).conditionId, ...
            plan.cases(j).direction, ...
            strjoin(string(plan.cases(j).repetitions),","));
        disp(plan.cases(j).condition);
    end
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

function matrix = validateExecutionProfileMatrix(varargin)
%VALIDATEEXECUTIONPROFILEMATRIX Build an end-to-end execution profile matrix.
%
% The validator exercises maintained headless app entrypoints for Main GUI,
% SweepTool, and FitTool. It does not open figures. CSV export is opt-in.

p = inputParser;
addParameter(p, 'WriteCsv', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'OutputFile', fullfile('analysis', 'execution_profiles', 'execution_profile_validation_matrix.csv'), ...
    @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

startup;

profiles = guiExecutionProfileValues();
surfaces = ["Main GUI", "SweepTool", "FitTool"];
scenarios = [
    struct('Model', "Rayleigh-Lamb", 'Scenario', "A0", 'EtaS', NaN)
    struct('Model', "mRLFE", 'Scenario', "A0Like etaS=0", 'EtaS', 0)
    struct('Model', "mRLFE", 'Scenario', "A0Like etaS>0", 'EtaS', 0.05)
    struct('Model', "AE IOP/HGO", 'Scenario', "atlasA0", 'EtaS', NaN)
    ];

rows = {};
for iSurface = 1:numel(surfaces)
    for iScenario = 1:numel(scenarios)
        for iProfile = 1:numel(profiles)
            rows(end+1, :) = validateCase(surfaces(iSurface), scenarios(iScenario), profiles(iProfile)); %#ok<AGROW>
        end
    end
end

matrix = cell2table(rows, 'VariableNames', ...
    {'Surface', 'Model', 'Scenario', 'RequestedProfile', 'EffectiveProfile', ...
    'SupportMode', 'InternalSolverPreset', 'InternalAtlasPreset', 'RoutePolicy', ...
    'ProfileOverrideApplied', 'ProfileOverrideReason', 'ExecutionProfileSource', ...
    'ResultValidity', 'NumericalOutputAvailable', 'ExportMetadataAvailable', ...
    'SyntheticFittingApplicability', 'Notes', 'ElapsedSeconds'});

if logical(p.Results.WriteCsv)
    writetable(matrix, fullfile(testRepositoryRoot(), char(p.Results.OutputFile)));
end

disp(matrix);
end

function row = validateCase(surface, scenario, profile)
timer = tic;
notes = "";
try
    switch surface
        case "Main GUI"
            [metadata, cp, notes] = validateMain(scenario, profile);
            exportMetadataAvailable = false;
            syntheticFit = "not_applicable";
        case "SweepTool"
            [metadata, cp, notes] = validateSweep(scenario, profile);
            exportMetadataAvailable = true;
            syntheticFit = "not_applicable";
        case "FitTool"
            [metadata, cp, notes] = validateFit(scenario, profile);
            exportMetadataAvailable = true;
            syntheticFit = "synthetic_fit_and_fitted_curve";
        otherwise
            error('validateExecutionProfileMatrix:UnknownSurface', ...
                'Unknown surface %s.', surface);
    end
    resultValidity = metadataIsComplete(metadata) && profileOverrideContractOK(metadata);
    numericalAvailable = any(isfinite(cp(:)) & cp(:) > 0);
catch ME
    metadata = emptyMetadata(profile);
    cp = nan;
    notes = "error: " + string(ME.identifier) + " " + string(ME.message);
    exportMetadataAvailable = false;
    syntheticFit = "not_completed";
    resultValidity = false;
    numericalAvailable = false;
end

row = {string(surface), string(scenario.Model), string(scenario.Scenario), ...
    string(profile), string(metadata.effectiveExecutionProfile), ...
    string(metadata.profileSupportMode), string(metadata.internalSolverPreset), ...
    string(metadata.internalAtlasPreset), string(metadata.routePolicy), ...
    logical(metadata.profileOverrideApplied), string(metadata.profileOverrideReason), ...
    string(metadata.executionProfileSource), logical(resultValidity), ...
    logical(numericalAvailable), logical(exportMetadataAvailable), string(syntheticFit), ...
    string(notes), toc(timer)};
end

function [metadata, cp, notes] = validateMain(scenario, profile)
notes = "";
switch string(scenario.Model)
    case "Rayleigh-Lamb"
        params = shortRLParams();
        options = rlDefaultOptions(profile);
        options.executionProfile = profile;
        options.computeA0 = true;
        options.computeS0 = false;
        out = guiRunRayleighLambModel(struct('params', params, 'options', options));
        metadata = out.metadata.executionProfile;
        cp = extractMainCp(out, "RayleighLamb", "A0");
    case "AE IOP/HGO"
        params = shortAEParams();
        options = guiBuildAcoustoelasticIOPHGOOptions(profile);
        out = guiRunAcoustoelasticIOPHGOModel(struct('params', params, 'options', options));
        metadata = out.metadata.executionProfile;
        cp = out.phaseVelocity(:);
    case "mRLFE"
        [out, cp] = runMainMRLFE(profile, scenario.EtaS);
        metadata = out.metadata.executionProfile;
        notes = "mRLFE main route " + strjoin(out.metadata.executionProfile.internalEngines, ",");
    otherwise
        error('validateExecutionProfileMatrix:UnknownModel', ...
            'Unknown model %s.', scenario.Model);
end
end

function [metadata, cp, notes] = validateSweep(scenario, profile)
notes = "";
switch string(scenario.Model)
    case "Rayleigh-Lamb"
        params = shortRLParams();
        request = guiBuildSweepRequest("rayleigh_lamb", ...
            'modelLabel', "Rayleigh-Lamb", ...
            'branchName', "A0", ...
            'sweepField', "thickness", ...
            'sweepLabel', "thickness", ...
            'sweepValuesDisplay', 0.5, ...
            'displayUnit', "mm", ...
            'displayScale', 1e-3, ...
            'baseParams', params, ...
            'controls', struct('executionProfile', profile), ...
            'outputMode', "workspace", ...
            'outputTaskName', "execution_profile_matrix_rl");
        out = guiRunSweep(request);
        metadata = out.executionProfile;
        cp = extractSweepCp(out);
    case "AE IOP/HGO"
        request = guiBuildSweepRequest("ae_iop_hgo", ...
            'modelLabel', "AE IOP/HGO", ...
            'branchName', "atlasA0", ...
            'sweepField', "IOP", ...
            'sweepLabel', "IOP", ...
            'sweepValuesDisplay', 15, ...
            'displayUnit', "mmHg", ...
            'displayScale', 133.322, ...
            'baseParams', shortAEParams(), ...
            'controls', struct('executionProfile', profile), ...
            'outputMode', "workspace", ...
            'outputTaskName', "execution_profile_matrix_ae");
        out = guiRunSweep(request);
        metadata = out.executionProfile;
        cp = extractAESweepCp(out);
    case "mRLFE"
        params = shortRLParams();
        controls = struct('executionProfile', profile, ...
            'etaS', scenario.EtaS, ...
            'fluidDensity', 1000, ...
            'fluidSoundSpeed', 1500, ...
            'mrlfeA0Policy', "physicalTail");
        request = guiBuildSweepRequest("mrlfe", ...
            'modelLabel', "mRLFE real-k", ...
            'branchName', "A0Like", ...
            'sweepField', "mu", ...
            'sweepLabel', "mu", ...
            'sweepValuesDisplay', 75, ...
            'displayUnit', "kPa", ...
            'displayScale', 1e3, ...
            'baseParams', params, ...
            'controls', controls, ...
            'outputMode', "workspace", ...
            'outputTaskName', "execution_profile_matrix_mrlfe");
        out = guiRunSweep(request);
        metadata = out.executionProfile;
        cp = extractSweepCp(out);
        notes = "mRLFE sweep route " + string(out.atlasPolicy.guiRoutePolicy);
    otherwise
        error('validateExecutionProfileMatrix:UnknownModel', ...
            'Unknown model %s.', scenario.Model);
end
end

function [metadata, cp, notes] = validateFit(scenario, profile)
notes = "";
switch string(scenario.Model)
    case "Rayleigh-Lamb"
        [request, cpReference] = makeRLFitRequest(profile);
        out = guiRunFit(request);
        metadata = out.executionProfile;
        cp = out.normalized.Cp_fit_mps(:);
        notes = maxDiffNote(cp, cpReference);
    case "AE IOP/HGO"
        [request, cpReference] = makeAEFitRequest(profile);
        out = guiRunFit(request);
        metadata = out.executionProfile;
        cp = out.normalized.Cp_fit_mps(:);
        notes = maxDiffNote(cp, cpReference);
    case "mRLFE"
        [request, cpReference] = makeMRLFEFitRequest(profile, scenario.EtaS);
        out = guiRunFit(request);
        metadata = out.executionProfile;
        cp = out.normalized.Cp_fit_mps(:);
        route = "";
        if isfield(out, 'routePolicy') && isfield(out.routePolicy, 'actualPath')
            route = string(out.routePolicy.actualPath);
        end
        notes = "mRLFE fit route " + route + "; " + maxDiffNote(cp, cpReference);
    otherwise
        error('validateExecutionProfileMatrix:UnknownModel', ...
            'Unknown model %s.', scenario.Model);
end
end

function [out, cp] = runMainMRLFE(profile, etaS)
params = shortRLParams();
options = rlDefaultOptions(profile);
options.executionProfile = profile;
options.computeA0 = true;
options.computeS0 = false;
options.computeMRLFERealK = true;
options.mrlfeComputeA0Like = true;
options.mrlfeComputeS0Like = false;
options.mrlfeA0Policy = "physicalTail";
options.mrlfeParams = defaultMRLFEParams();
options.mrlfeParams.etaS = etaS;
options.mrlfeParams.etaL = 0;
options.mrlfeParams.useComplexLambda = false;
out = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', etaS > 0));
cp = extractMainCp(out, "mRLFERealK", "A0Like");
end

function [request, cp] = makeRLFitRequest(profile)
params = rlDefaultParams();
params.mu = 85e3;
params.thickness = 0.5e-3;
frequency = linspace(1000, 3000, 4).';
options = rlDefaultOptions(profile);
options.computeA0 = true;
options.computeS0 = false;
cp = rlEvaluateFitModel(params, frequency, "A0", options);
request = guiBuildFitRequest("rayleigh_lamb", ...
    'branchName', "A0", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', isfinite(cp)), ...
    'fixedParams', struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', params.mu), ...
    'bounds', struct('mu', [20e3, 160e3]), ...
    'controls', struct('executionProfile', profile), ...
    'fitOptions', shortFitOptions(1, 3, 1e-4));
end

function [request, cp] = makeAEFitRequest(profile)
params = shortAEParams();
frequency = params.frequency(:);
params = rmfield(params, 'frequency');
options = aeDefaultSweepOptions(profile);
[cp, raw] = aeEvaluateFitModel(params, frequency, "atlasA0", options);
request = guiBuildFitRequest("acoustoelastic_iop_hgo", ...
    'branchName', "atlasA0", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', raw.validMask), ...
    'fixedParams', rmfield(params, 'mu'), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', params.mu), ...
    'bounds', struct('mu', [10e3, 150e3]), ...
    'controls', struct('executionProfile', profile, 'atlasInitializationNumFrequencyPoints', 50), ...
    'fitOptions', shortFitOptions(1, 3, 1e-3));
end

function [request, cp] = makeMRLFEFitRequest(profile, etaS)
params = mrlfeDefaultSweepParams();
params.mu = 75e3;
frequency = linspace(1000, 4000, 5).';
options = mrlfeDefaultSweepOptions("A0Like", ...
    'EtaS', etaS, ...
    'A0Policy', "physicalTail");
cp = mrlfeEvaluateFitModel(params, frequency, "A0Like", options);
request = guiBuildFitRequest("mrlfe", ...
    'branchName', "A0Like", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', isfinite(cp)), ...
    'fixedParams', struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu, 'etaS', etaS), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', params.mu), ...
    'bounds', struct('mu', [20e3, 160e3]), ...
    'controls', struct('executionProfile', profile, ...
        'etaS', etaS, ...
        'fluidDensity', 1000, ...
        'fluidSoundSpeed', 1500, ...
        'mrlfeA0Policy', "physicalTail"), ...
    'fitOptions', shortFitOptions(1, 3, 1e-4));
end

function fitOptions = shortFitOptions(maxIter, maxFunEvals, tolX)
fitOptions = struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', ...
    'MaxIter', maxIter, 'MaxFunEvals', maxFunEvals, 'TolX', tolX));
end

function params = shortRLParams()
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 3000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
end

function params = shortAEParams()
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'IOP', 15 * 133.322, ...
    'mu', 64e3, 'k1', 50e3, 'k2', 200, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9, ...
    'frequency', logspace(log10(300), log10(3000), 5).');
end

function cp = extractMainCp(out, modelName, branchName)
cp = nan;
if ~isfield(out, 'branches')
    return;
end
for i = 1:numel(out.branches)
    if string(out.branches(i).modelName) == modelName && string(out.branches(i).branchName) == branchName
        cp = out.branches(i).phaseVelocity(:);
        return;
    end
end
end

function cp = extractSweepCp(out)
cp = nan;
try
    curve = out.normalized.curves(1);
    cp = curve.Cp_mps(:);
catch
end
end

function cp = extractAESweepCp(out)
cp = extractSweepCp(out);
if all(~isfinite(cp))
    try
        cp = out.rawResults.results{1}.Cp(:);
    catch
    end
end
end

function tf = metadataIsComplete(metadata)
required = ["requestedExecutionProfile", "effectiveExecutionProfile", ...
    "executionProfileSource", "internalSolverPreset", "internalAtlasPreset", ...
    "profileOverrideApplied", "profileOverrideReason", "routePolicy", ...
    "supportedExecutionProfiles", "profileSupportMode", "surfaceDefaultExecutionProfile"];
tf = isstruct(metadata);
for i = 1:numel(required)
    tf = tf && isfield(metadata, char(required(i)));
end
end

function tf = profileOverrideContractOK(metadata)
tf = true;
if ~isstruct(metadata) || ~isfield(metadata, 'profileOverrideApplied')
    tf = false;
    return;
end
if logical(metadata.profileOverrideApplied)
    tf = isfield(metadata, 'profileOverrideReason') && ...
        strlength(string(metadata.profileOverrideReason)) > 0;
else
    tf = ~isfield(metadata, 'profileOverrideReason') || ...
        strlength(string(metadata.profileOverrideReason)) == 0;
end
end

function metadata = emptyMetadata(profile)
metadata = struct();
metadata.requestedExecutionProfile = string(profile);
metadata.effectiveExecutionProfile = "";
metadata.executionProfileSource = "";
metadata.internalSolverPreset = "";
metadata.internalAtlasPreset = "";
metadata.profileOverrideApplied = false;
metadata.profileOverrideReason = "";
metadata.routePolicy = "";
metadata.supportedExecutionProfiles = strings(1, 0);
metadata.profileSupportMode = "";
metadata.surfaceDefaultExecutionProfile = "";
end

function note = maxDiffNote(cp, cpReference)
delta = max(abs(cp(:) - cpReference(:)), [], 'omitnan');
if isempty(delta) || ~isfinite(delta)
    note = "maxAbsFitMinusSynthetic=nan";
else
    note = "maxAbsFitMinusSynthetic=" + string(delta);
end
end

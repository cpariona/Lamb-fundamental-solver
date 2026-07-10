function [resultsTable, summaryTable] = benchmarkMRLFEExecutionProfiles(varargin)
%BENCHMARKMRLFEEXECUTIONPROFILES Controlled mRLFE profile mapping benchmark.
%
% This benchmark compares Main, Sweep, and Fit mRLFE paths for requested
% Fast/Balanced/Robust when the maintained effective profile is Fast. Timing is
% recorded, but options and curve equality determine whether profiles differ.

p = inputParser;
addParameter(p, 'Repeats', 5, @(x)isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'FitRepeats', 3, @(x)isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'WriteCsv', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'OutputFile', fullfile('analysis', 'execution_profiles', 'mrlfe_execution_profile_benchmark.csv'), ...
    @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

startup;

surfaces = ["Main", "Sweep", "Fit"];
profiles = guiExecutionProfileValues();
etaCases = [0, 0.05];

rows = {};
for iSurface = 1:numel(surfaces)
    surface = surfaces(iSurface);
    repeats = p.Results.Repeats;
    if surface == "Fit"
        repeats = p.Results.FitRepeats;
    end
    for iEta = 1:numel(etaCases)
        etaS = etaCases(iEta);
        fastReference = runCase(surface, "Fast", etaS);
        for iProfile = 1:numel(profiles)
            profile = profiles(iProfile);
            warmup = runCase(surface, profile, etaS); %#ok<NASGU>
            for iRep = 1:repeats
                measured = runCase(surface, profile, etaS);
                optionsDiff = diffOptions(measured.options, fastReference.options);
                curveDiff = compareCurves(measured.cp, measured.validMask, fastReference.cp, fastReference.validMask);
                metadataEqual = compareMetadataForEffectiveFast(measured.metadata, fastReference.metadata);
                rows(end+1, :) = {surface, profile, measured.metadata.effectiveExecutionProfile, ...
                    string(measured.metadata.profileSupportMode), string(measured.metadata.internalAtlasPreset), ...
                    string(measured.actualRoute), etaS, iRep, measured.elapsedSeconds, ...
                    curveDiff.validFraction, curveDiff.maxAbsCpDiff, curveDiff.rmsCpDiff, ...
                    curveDiff.validMaskEqual, string(optionsDiff.Equal), string(optionsDiff.DiffFields), ...
                    measured.routeEqualToFast(fastReference.actualRoute), metadataEqual}; %#ok<AGROW>
            end
        end
    end
end

resultsTable = cell2table(rows, 'VariableNames', ...
    {'Surface', 'RequestedProfile', 'EffectiveProfile', 'SupportMode', ...
    'InternalPreset', 'ActualRoute', 'EtaS', 'Repetition', 'ElapsedSeconds', ...
    'ValidFraction', 'MaxAbsCpDiffVsFast', 'RmsCpDiffVsFast', ...
    'ValidMaskEqualVsFast', 'OptionsEqualVsFast', 'OptionDiffFieldsVsFast', ...
    'RouteEqualVsFast', 'MetadataEffectiveEqualVsFast'});

summaryRows = {};
groups = unique(resultsTable(:, {'Surface', 'RequestedProfile', 'EtaS'}), 'rows');
for i = 1:height(groups)
    mask = resultsTable.Surface == groups.Surface(i) & ...
        resultsTable.RequestedProfile == groups.RequestedProfile(i) & ...
        resultsTable.EtaS == groups.EtaS(i);
    times = resultsTable.ElapsedSeconds(mask);
    medianTime = median(times, 'omitnan');
    minTime = min(times, [], 'omitnan');
    maxTime = max(times, [], 'omitnan');
    if isfinite(medianTime) && medianTime > 0
        spread = (maxTime - minTime) / medianTime;
    else
        spread = nan;
    end
    summaryRows(end+1, :) = {groups.Surface(i), groups.RequestedProfile(i), groups.EtaS(i), ...
        medianTime, minTime, maxTime, spread, ...
        all(resultsTable.OptionsEqualVsFast(mask) == "true"), ...
        max(resultsTable.MaxAbsCpDiffVsFast(mask), [], 'omitnan'), ...
        all(resultsTable.ValidMaskEqualVsFast(mask)), ...
        all(resultsTable.RouteEqualVsFast(mask)), ...
        strjoin(unique(resultsTable.OptionDiffFieldsVsFast(mask)), "; ")}; %#ok<AGROW>
end

summaryTable = cell2table(summaryRows, 'VariableNames', ...
    {'Surface', 'RequestedProfile', 'EtaS', 'MedianTimeSeconds', ...
    'MinTimeSeconds', 'MaxTimeSeconds', 'RelativeSpread', ...
    'OptionsEqualVsFast', 'MaxAbsCpDiffVsFast', 'ValidMaskEqualVsFast', ...
    'RouteEqualVsFast', 'OptionDiffFieldsVsFast'});

if logical(p.Results.WriteCsv)
    root = testRepositoryRoot();
    writetable(resultsTable, fullfile(root, char(p.Results.OutputFile)));
    [folder, base, ext] = fileparts(char(p.Results.OutputFile));
    writetable(summaryTable, fullfile(root, folder, base + "_summary" + ext));
end

disp(summaryTable);
end

function out = runCase(surface, profile, etaS)
switch surface
    case "Main"
        out = runMainCase(profile, etaS);
    case "Sweep"
        out = runSweepCase(profile, etaS);
    case "Fit"
        out = runFitEvaluationCase(profile, etaS);
    otherwise
        error('benchmarkMRLFEExecutionProfiles:UnknownSurface', ...
            'Unknown surface %s.', surface);
end
end

function out = runMainCase(profile, etaS)
params = shortParams();
options = rlDefaultOptions(profile);
options.executionProfile = profile;
options.robustness = profile;
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
t = tic;
result = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', etaS > 0));
elapsed = toc(t);
out = makeOutput(result.metadata.executionProfile, result.metadata.options, ...
    extractMainCp(result), elapsed, strjoin(result.metadata.executionProfile.internalEngines, ","));
end

function out = runSweepCase(profile, etaS)
params = shortParams();
controls = struct('executionProfile', profile, 'etaS', etaS, ...
    'fluidDensity', 1000, 'fluidSoundSpeed', 1500, ...
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
    'outputTaskName', "mrlfe_profile_benchmark");
t = tic;
result = guiRunSweep(request);
elapsed = toc(t);
actualOptions = result.rawResults.options{1};
out = makeOutput(result.executionProfile, actualOptions, extractSweepCp(result), ...
    elapsed, getStructField(result.executionProfile, 'actualRoute', ""));
end

function out = runFitEvaluationCase(profile, etaS)
params = mrlfeDefaultSweepParams();
params.fmin = 1000;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
frequency = linspace(1000, 4000, 10).';
[options, metadata] = mrlfeResolveExecutionProfile("A0Like", ...
    struct('executionProfile', profile, 'etaS', etaS), ...
    'Surface', "fit", ...
    'DefaultProfile', "Fast", ...
    'DefaultSource', "FitTool default", ...
    'EtaS', etaS, ...
    'A0Policy', "physicalTail");
t = tic;
[cp, raw] = mrlfeEvaluateFitModel(params, frequency, "A0Like", options);
elapsed = toc(t);
if isfield(raw, 'evaluationPath') && isfield(raw.evaluationPath, 'path')
    route = string(raw.evaluationPath.path);
else
    route = "";
end
if isfield(raw, 'evaluationPath') && isfield(raw.evaluationPath, 'fitAtlasPreset')
    metadata.internalAtlasPreset = string(raw.evaluationPath.fitAtlasPreset);
end
out = makeOutput(metadata, options, cp, elapsed, route);
end

function params = shortParams()
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 75e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 1000;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
end

function out = makeOutput(metadata, options, cp, elapsed, route)
out = struct();
out.metadata = metadata;
out.options = options;
out.cp = cp(:);
out.validMask = isfinite(out.cp) & out.cp > 0;
out.elapsedSeconds = elapsed;
out.actualRoute = string(route);
out.routeEqualToFast = @(fastRoute) string(route) == string(fastRoute);
end

function cp = extractMainCp(result)
cp = nan;
for i = 1:numel(result.branches)
    branch = result.branches(i);
    if string(branch.modelName) == "mRLFERealK" && string(branch.branchName) == "A0Like"
        cp = branch.phaseVelocity(:);
        return;
    end
end
end

function cp = extractSweepCp(result)
cp = result.normalized.curves(1).Cp_mps(:);
end

function diff = compareCurves(cp, valid, fastCp, fastValid)
cp = cp(:);
fastCp = fastCp(:);
valid = logical(valid(:));
fastValid = logical(fastValid(:));
n = min([numel(cp), numel(fastCp), numel(valid), numel(fastValid)]);
cp = cp(1:n);
fastCp = fastCp(1:n);
valid = valid(1:n);
fastValid = fastValid(1:n);
both = valid & fastValid & isfinite(cp) & isfinite(fastCp);
delta = cp - fastCp;
diff = struct();
diff.validFraction = nnz(valid) / max(1, numel(valid));
diff.validMaskEqual = isequal(valid, fastValid);
if any(both)
    diff.maxAbsCpDiff = max(abs(delta(both)));
    diff.rmsCpDiff = sqrt(mean(delta(both).^2));
else
    diff.maxAbsCpDiff = nan;
    diff.rmsCpDiff = nan;
end
end

function diff = diffOptions(options, fastOptions)
ignore = ["executionProfile", "effectiveExecutionProfile", "robustness"];
fields = unique([string(fieldnames(options)); string(fieldnames(fastOptions))]);
different = strings(0, 1);
for i = 1:numel(fields)
    fieldName = fields(i);
    if any(fieldName == ignore)
        continue;
    end
    if ~isfield(options, char(fieldName)) || ~isfield(fastOptions, char(fieldName))
        different(end+1) = fieldName; %#ok<AGROW>
        continue;
    end
    if ~valuesEqual(options.(char(fieldName)), fastOptions.(char(fieldName)))
        different(end+1) = fieldName; %#ok<AGROW>
    end
end
diff = struct();
diff.Equal = isempty(different);
if isempty(different)
    diff.DiffFields = "";
else
    diff.DiffFields = strjoin(different, ",");
end
end

function tf = valuesEqual(a, b)
if isstruct(a) && isstruct(b)
    tf = diffOptions(a, b).Equal == true;
elseif isnumeric(a) && isnumeric(b)
    tf = isequaln(a, b);
elseif islogical(a) && islogical(b)
    tf = isequaln(a, b);
else
    tf = isequaln(string(a), string(b));
end
end

function tf = compareMetadataForEffectiveFast(metadata, fastMetadata)
tf = string(metadata.effectiveExecutionProfile) == "Fast" && ...
    string(fastMetadata.effectiveExecutionProfile) == "Fast" && ...
    string(metadata.profileSupportMode) == string(fastMetadata.profileSupportMode);
end

function value = getStructField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

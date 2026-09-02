function [resultsTable, summaryTable] = benchmarkMRLFEExecutionProfiles(varargin)
%BENCHMARKMRLFEEXECUTIONPROFILES Characterize direct public mRLFE profiles.
%
% Contract mode is bounded structural validation. Full mode is descriptive
% characterization and may be materially slower. Timing is never pass/fail.

p = inputParser;
addParameter(p, 'Mode', "contract", @(x)any(strcmpi(string(x), ["contract", "full"])));
addParameter(p, 'RepeatCount', 1, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
addParameter(p, 'Repeats', NaN, @(x)isnumeric(x) && isscalar(x) && (isnan(x) || (x >= 1 && fix(x) == x)));
addParameter(p, 'FitRepeats', NaN, @(x)isnumeric(x) && isscalar(x) && (isnan(x) || (x >= 1 && fix(x) == x)));
addParameter(p, 'WriteCsv', false, @(x)islogical(x) && isscalar(x));
addParameter(p, 'OutputFile', fullfile('analysis', 'execution_profiles', 'mrlfe_execution_profile_benchmark.csv'), ...
    @(x)ischar(x) || (isstring(x) && isscalar(x)));
parse(p, varargin{:});

if isempty(which('mrlfeSolve'))
    startup
end

mode = lower(string(p.Results.Mode));
profiles = guiExecutionProfileValues();
surfaces = ["Main", "Sweep", "Fit"];
etaCases = [0, 0.05];
branches = "A0Like";
pointCount = 10;
useWarmup = false;
repeatCount = p.Results.RepeatCount;
if mode == "full"
    branches = ["A0Like", "S0Like"];
    pointCount = 10;
    useWarmup = true;
end
if isfinite(p.Results.Repeats)
    repeatCount = p.Results.Repeats;
end

rows = cell(0, 26);
for iSurface = 1:numel(surfaces)
    surface = surfaces(iSurface);
    surfaceRepeats = repeatCount;
    if surface == "Fit" && isfinite(p.Results.FitRepeats)
        surfaceRepeats = p.Results.FitRepeats;
    end
    for iBranch = 1:numel(branches)
        branch = branches(iBranch);
        for iEta = 1:numel(etaCases)
            etaS = etaCases(iEta);
            fastReference = runCase(surface, branch, "Fast", etaS, pointCount);
            for iProfile = 1:numel(profiles)
                profile = profiles(iProfile);
                if useWarmup
                    runCase(surface, branch, profile, etaS, pointCount);
                end
                for iRep = 1:surfaceRepeats
                    measured = runCase(surface, branch, profile, etaS, pointCount);
                    comparison = compareCurves(measured, fastReference);
                    metadataValid = validateMetadata(measured.metadata, profile, measured.modelResult);
                    rows(end + 1, :) = { ...
                        surface, branch, viscosityLabel(etaS), etaS, profile, ...
                        string(measured.metadata.effectiveExecutionProfile), ...
                        string(measured.modelResult.execution.effectivePreset), ...
                        string(measured.metadata.internalAtlasPreset), ...
                        string(measured.gridPolicy), measured.internalFrequencyCount, ...
                        numel(measured.frequency_Hz), nnz(measured.validMask) / max(1, numel(measured.validMask)), ...
                        logical(measured.modelResult.quality.accepted), string(measured.modelResult.quality.reason), ...
                        logical(measured.modelResult.fallback.applied), measured.elapsedSeconds, ...
                        comparison.MaxAbsCpDiff, comparison.RmsCpDiff, comparison.CommonValidCount, ...
                        string(measured.metadata.routePolicy), metadataValid, ...
                        string(measured.metadata.profileSupportMode), ...
                        logical(measured.metadata.profileOverrideApplied), ...
                        all(diff(measured.frequency_Hz) > 0), iRep, mode}; %#ok<AGROW>
                end
            end
        end
    end
end

resultsTable = cell2table(rows, 'VariableNames', { ...
    'Surface', 'Branch', 'ViscosityCase', 'EtaS_Pas', 'RequestedProfile', ...
    'EffectiveProfile', 'InternalSolverPreset', 'InternalAtlasPreset', ...
    'GridPolicy', 'InternalFrequencyCount', 'RequestedFrequencyCount', ...
    'ValidFraction', 'QualityAccepted', 'QualityStatus', 'FallbackApplied', ...
    'ElapsedSeconds', 'MaxAbsCpDiffVsFast', 'RmsCpDiffVsFast', ...
    'CommonValidCountVsFast', 'RoutePolicy', 'MetadataValid', 'SupportMode', ...
    'ProfileOverrideApplied', 'FrequencyMonotonic', 'Repetition', 'Mode'});

summaryTable = summarizeResults(resultsTable);
if p.Results.WriteCsv
    root = testRepositoryRoot();
    outputFile = fullfile(root, char(p.Results.OutputFile));
    writetable(resultsTable, outputFile);
    [folder, base, ext] = fileparts(outputFile);
    writetable(summaryTable, fullfile(folder, base + "_summary" + ext));
end
disp(summaryTable);
end

function out = runCase(surface, branch, profile, etaS, pointCount)
switch surface
    case "Main"
        out = runMainCase(branch, profile, etaS, pointCount);
    case "Sweep"
        out = runSweepCase(branch, profile, etaS, pointCount);
    case "Fit"
        out = runFitCase(branch, profile, etaS, pointCount);
    otherwise
        error('benchmarkMRLFEExecutionProfiles:UnknownSurface', 'Unknown surface %s.', surface);
end
end

function out = runMainCase(branch, profile, etaS, pointCount)
params = shortParams(pointCount);
[options, ~] = mrlfeResolveExecutionProfile(branch, profile, ...
    'Surface', "main", 'EtaS', etaS);
options.branchNames = branch;
t = tic;
result = guiRunMRLFEModel(struct('params', params, 'options', options, ...
    'mrlfeParams', options.mrlfeParams, 'computeVisco', etaS > 0));
elapsed = toc(t);
out = makeOutput(result.modelResult, result.metadata.executionProfile, ...
    "numericalPreset", elapsed);
end

function out = runSweepCase(branch, profile, etaS, pointCount)
params = shortParams(pointCount);
controls = struct('executionProfile', profile, 'etaS', etaS, ...
    'fluidDensity', 1000, 'fluidSoundSpeed', 1500, 'mrlfeA0Policy', "physicalTail");
request = guiBuildSweepRequest("mrlfe", 'modelLabel', "mRLFE real-k", ...
    'branchName', branch, 'sweepField', "mu", 'sweepLabel', "mu", ...
    'sweepValuesDisplay', 75, 'displayUnit', "kPa", 'displayScale', 1e3, ...
    'baseParams', params, 'controls', controls, 'outputMode', "workspace", ...
    'outputTaskName', "mrlfe_profile_benchmark");
t = tic;
result = guiRunSweep(request);
elapsed = toc(t);
modelResult = result.sweepResult.points{1}.modelResult;
out = makeOutput(modelResult, result.executionProfile, "numericalPreset", elapsed);
end

function out = runFitCase(branch, profile, etaS, pointCount)
params = mrlfeDefaultSweepParams();
params.fmin = 1000;
params.fmax = 4000;
frequency = linspace(params.fmin, params.fmax, pointCount).';
[options, metadata] = mrlfeResolveExecutionProfile(branch, ...
    struct('executionProfile', profile, 'etaS', etaS), 'Surface', "fit", ...
    'DefaultProfile', "Fast", 'DefaultSource', "FitTool default", ...
    'EtaS', etaS, 'A0Policy', "physicalTail");
t = tic;
[~, raw] = mrlfeEvaluateFitModel(params, frequency, branch, options);
elapsed = toc(t);
metadata.routePolicy = string(raw.modelResult.termination.policy);
out = makeOutput(raw.modelResult, metadata, string(raw.fitGrid.gridPolicy), elapsed);
end

function params = shortParams(pointCount)
params = rlDefaultParams();
params.modelType = "ShearPoisson";
params.rho = 1070;
params.mu = 75e3;
params.nu = 0.4999;
params.thickness = 0.5e-3;
params.fmin = 1000;
params.fmax = 4000;
params.numFrequencyPoints = pointCount;
params.frequencySpacing = "linspace";
end

function out = makeOutput(modelResult, metadata, gridPolicy, elapsed)
out = struct();
out.modelResult = modelResult;
out.metadata = metadata;
out.frequency_Hz = modelResult.frequency_Hz(:);
out.cp = modelResult.phaseVelocity_mps(:);
out.validMask = logical(modelResult.validMask(:));
out.gridPolicy = gridPolicy;
out.elapsedSeconds = elapsed;
out.internalFrequencyCount = modelResult.diagnostics.summary.solvePointCount;
end

function value = viscosityLabel(etaS)
if etaS == 0
    value = "elastic";
else
    value = "viscous";
end
end

function comparison = compareCurves(measured, reference)
common = measured.validMask & reference.validMask & isfinite(measured.cp) & isfinite(reference.cp);
comparison.CommonValidCount = nnz(common);
if any(common)
    delta = measured.cp(common) - reference.cp(common);
    comparison.MaxAbsCpDiff = max(abs(delta));
    comparison.RmsCpDiff = sqrt(mean(delta .^ 2));
else
    comparison.MaxAbsCpDiff = NaN;
    comparison.RmsCpDiff = NaN;
end
end

function valid = validateMetadata(metadata, requestedProfile, modelResult)
expectedPreset = lower(requestedProfile);
valid = string(metadata.requestedExecutionProfile) == requestedProfile && ...
    string(metadata.effectiveExecutionProfile) == requestedProfile && ...
    string(metadata.profileSupportMode) == "direct" && ...
    string(modelResult.execution.effectivePreset) == expectedPreset && ...
    logical(metadata.profileOverrideApplied) == false;
end

function summary = summarizeResults(results)
groups = unique(results(:, {'Surface', 'Branch', 'ViscosityCase', 'RequestedProfile'}), 'rows');
rows = cell(height(groups), 10);
for i = 1:height(groups)
    mask = results.Surface == groups.Surface(i) & results.Branch == groups.Branch(i) & ...
        results.ViscosityCase == groups.ViscosityCase(i) & ...
        results.RequestedProfile == groups.RequestedProfile(i);
    elapsed = results.ElapsedSeconds(mask);
    rows(i, :) = {groups.Surface(i), groups.Branch(i), groups.ViscosityCase(i), ...
        groups.RequestedProfile(i), median(elapsed), min(elapsed), max(elapsed), ...
        all(results.MetadataValid(mask)), max(results.MaxAbsCpDiffVsFast(mask), [], 'omitnan'), ...
        min(results.CommonValidCountVsFast(mask))};
end
summary = cell2table(rows, 'VariableNames', {'Surface', 'Branch', 'ViscosityCase', ...
    'RequestedProfile', 'MedianTimeSeconds', 'MinTimeSeconds', 'MaxTimeSeconds', ...
    'MetadataValid', 'MaxAbsCpDiffVsFast', 'MinimumCommonValidCountVsFast'});
end

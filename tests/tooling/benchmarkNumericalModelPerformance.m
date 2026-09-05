function [summary, raw] = benchmarkNumericalModelPerformance(varargin)
%BENCHMARKNUMERICALMODELPERFORMANCE Benchmark maintained numerical model APIs.
%
% This is opt-in benchmark tooling, not a test. It records runtime and basic
% numerical-quality descriptors without imposing pass/fail timing thresholds.
%
% Historical-comparison fixtures are preserved for RL and AE. mRLFE uses the
% maintained production-core fixture used by the current performance suite.

parser = inputParser;
parser.addParameter('Repeats', 3, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
options = parser.Results;

repoRoot = findRepositoryRoot(mfilename('fullpath'));
originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>
cd(repoRoot);
startup;

profiles = ["Fast", "Balanced", "Robust"];
commit = gitHead(repoRoot);
release = string(version('-release'));
platform = string(computer);

fprintf('\nNumerical model performance baseline\n');
fprintf('====================================\n');
fprintf('Commit: %s\nMATLAB: %s | %s\nRepeats: %d\n\n', ...
    commit, release, platform, options.Repeats);

rows = repmat(emptyRow(), 0, 1);
rows = [rows; benchmarkRayleighLamb(profiles, options.Repeats, release, platform, commit)]; %#ok<AGROW>
rows = [rows; benchmarkMRLFE(profiles, options.Repeats, release, platform, commit)]; %#ok<AGROW>
rows = [rows; benchmarkAE(profiles, options.Repeats, release, platform, commit)]; %#ok<AGROW>
raw = struct2table(rows);
summary = summarizeBenchmark(raw);

disp(summary(:, {'Model','Case','Profile','MedianSeconds','MinSeconds','MaxSeconds', ...
    'SpeedupVsRobust','ValidFraction','MaxRelativeJump', ...
    'HighFrequencyMaxRelativeSecondDiff','MaxAbsCpDiffVsRobust_mps'}));

if options.WriteCsv
    outputFolder = fullfile(repoRoot, 'Results', 'validation', 'numerical_solver_baseline');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(raw, fullfile(outputFolder, 'numerical_model_performance_raw.csv'));
    writetable(summary, fullfile(outputFolder, 'numerical_model_performance_summary.csv'));
    fprintf('Saved benchmark output under Results/validation/numerical_solver_baseline\n');
end
end

function rows = benchmarkRayleighLamb(profiles, repeats, release, platform, commit)
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 12000;
params.numFrequencyPoints = 45;
params.frequencySpacing = "linspace";
caseName = "A0 historical fixture";

robustOptions = rlDefaultOptions("Robust");
robustOptions.computeA0 = true;
robustOptions.computeS0 = false;
robustResult = rlComputeFundamentalLambModes(params, robustOptions);
reference = branchData(robustResult.modes.A0);

rows = repmat(emptyRow(), 0, 1);
for profile = profiles
    solverOptions = rlDefaultOptions(profile);
    solverOptions.computeA0 = true;
    solverOptions.computeS0 = false;

    rlComputeFundamentalLambModes(params, solverOptions); % warm-up
    for runIndex = 1:repeats
        timer = tic;
        result = rlComputeFundamentalLambModes(params, solverOptions);
        elapsed = toc(timer);
        data = branchData(result.modes.A0);
        rows(end+1,1) = buildRow("RL", caseName, profile, runIndex, elapsed, ...
            data, reference, release, platform, commit); %#ok<AGROW>
    end
end
end

function rows = benchmarkMRLFE(profiles, repeats, release, platform, commit)
frequency_Hz = linspace(1000, 6000, 10).';
etaSValues = [0, 0.05];
rows = repmat(emptyRow(), 0, 1);

for etaS = etaSValues
    if etaS == 0
        caseName = "A0Like elastic";
    else
        caseName = "A0Like viscoelastic";
    end

    robustRequest = mrlfeRequest(frequency_Hz, etaS, "robust");
    robustResult = mrlfeSolve(robustRequest);
    reference = directData(robustResult.frequency_Hz, robustResult.phaseVelocity_mps, robustResult.validMask);

    for profile = profiles
        request = mrlfeRequest(frequency_Hz, etaS, lower(profile));
        mrlfeSolve(request); % warm-up
        for runIndex = 1:repeats
            timer = tic;
            result = mrlfeSolve(request);
            elapsed = toc(timer);
            data = directData(result.frequency_Hz, result.phaseVelocity_mps, result.validMask);
            rows(end+1,1) = buildRow("mRLFE", caseName, profile, runIndex, elapsed, ...
                data, reference, release, platform, commit); %#ok<AGROW>
        end
    end
end
end

function request = mrlfeRequest(frequency_Hz, etaS, preset)
defaults = mrlfeDefaultParameters();
publicOptions = mrlfeDefaultOptions();
request = struct();
request.branch = "A0Like";
request.frequency_Hz = frequency_Hz(:);
request.material = struct( ...
    'mu_Pa', defaults.mu_Pa, ...
    'etaS_Pas', etaS, ...
    'rho_kgm3', defaults.rho_kgm3, ...
    'nu', defaults.nu);
request.geometry = struct('thickness_m', defaults.thickness_m);
request.fluid = struct( ...
    'density_kgm3', defaults.fluidDensity_kgm3, ...
    'soundSpeed_mps', defaults.fluidSoundSpeed_mps);
request.numerics = struct('preset', string(preset));
request.selection = publicOptions.selection;
request.termination = struct('policy', publicOptions.termination.A0Like);
request.fallback = publicOptions.fallback;
end

function rows = benchmarkAE(profiles, repeats, release, platform, commit)
params = struct( ...
    'R', 7.8e-3, ...
    'thickness', 550e-6, ...
    'IOP', 15 * 133.322, ...
    'mu', 64e3, ...
    'k1', 50e3, ...
    'k2', 200, ...
    'rho', 1060, ...
    'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9, ...
    'frequency', logspace(log10(300), log10(15000), 24));
caseName = "atlasA0 historical fixture";

robustOptions = aeDefaultSweepOptions("Robust");
robustResult = solveAcoustoelasticIOPHGOBranch(params, robustOptions);
reference = directData(robustResult.frequency_Hz, robustResult.phaseVelocity_mps, robustResult.validMask);

rows = repmat(emptyRow(), 0, 1);
for profile = profiles
    solverOptions = aeDefaultSweepOptions(profile);
    solveAcoustoelasticIOPHGOBranch(params, solverOptions); % warm-up
    for runIndex = 1:repeats
        timer = tic;
        result = solveAcoustoelasticIOPHGOBranch(params, solverOptions);
        elapsed = toc(timer);
        data = directData(result.frequency_Hz, result.phaseVelocity_mps, result.validMask);
        rows(end+1,1) = buildRow("AE", caseName, profile, runIndex, elapsed, ...
            data, reference, release, platform, commit); %#ok<AGROW>
    end
end
end

function row = buildRow(model, caseName, profile, runIndex, elapsed, data, reference, release, platform, commit)
metrics = curveMetrics(data.frequency_Hz, data.phaseVelocity_mps, data.validMask);
[absDiff, relDiff] = differenceVsReference(data, reference);
row = emptyRow();
row.Model = string(model);
row.Case = string(caseName);
row.Profile = string(profile);
row.RunIndex = runIndex;
row.ElapsedSeconds = elapsed;
row.OutputPoints = numel(data.frequency_Hz);
row.ValidFraction = metrics.ValidFraction;
row.MaxRelativeJump = metrics.MaxRelativeJump;
row.MaxRelativeSecondDiff = metrics.MaxRelativeSecondDiff;
row.HighFrequencyMaxRelativeSecondDiff = metrics.HighFrequencyMaxRelativeSecondDiff;
row.HighFrequencyMedianRelativeSecondDiff = metrics.HighFrequencyMedianRelativeSecondDiff;
row.MaxAbsCpDiffVsRobust_mps = absDiff;
row.MaxRelativeCpDiffVsRobust = relDiff;
row.MATLABRelease = release;
row.Platform = platform;
row.Commit = commit;
end

function data = branchData(branch)
data = directData(branch.frequency_Hz, branch.phaseVelocity_mps, branch.validMask);
end

function data = directData(frequency_Hz, cp_mps, validMask)
data = struct();
data.frequency_Hz = frequency_Hz(:);
data.phaseVelocity_mps = cp_mps(:);
data.validMask = logical(validMask(:));
end

function metrics = curveMetrics(frequency_Hz, cp, validMask)
frequency_Hz = frequency_Hz(:);
cp = cp(:);
validMask = logical(validMask(:)) & isfinite(frequency_Hz) & isfinite(cp) & cp > 0;
metrics = struct();
metrics.ValidFraction = nnz(validMask) / max(1, numel(validMask));

[frequencyRun, cpRun] = longestValidRun(frequency_Hz, cp, validMask);
[metrics.MaxRelativeJump, metrics.MaxRelativeSecondDiff] = localShapeMetrics(cpRun);

if numel(frequencyRun) < 3
    metrics.HighFrequencyMaxRelativeSecondDiff = NaN;
    metrics.HighFrequencyMedianRelativeSecondDiff = NaN;
    return
end
threshold = frequencyRun(1) + 0.60 * (frequencyRun(end) - frequencyRun(1));
highCp = cpRun(frequencyRun >= threshold);
[~, highSecond] = localShapeMetrics(highCp);
metrics.HighFrequencyMaxRelativeSecondDiff = highSecond;
if numel(highCp) >= 3
    second = abs(diff(highCp, 2)) ./ max(abs(highCp(2:end-1)), eps);
    metrics.HighFrequencyMedianRelativeSecondDiff = median(second, 'omitnan');
else
    metrics.HighFrequencyMedianRelativeSecondDiff = NaN;
end
end

function [maxJump, maxSecond] = localShapeMetrics(cp)
cp = cp(:);
if numel(cp) < 2
    maxJump = NaN;
else
    maxJump = max(abs(diff(cp)) ./ max(abs(cp(1:end-1)), eps));
end
if numel(cp) < 3
    maxSecond = NaN;
else
    second = abs(diff(cp, 2)) ./ max(abs(cp(2:end-1)), eps);
    maxSecond = max(second);
end
end

function [frequencyRun, cpRun] = longestValidRun(frequency_Hz, cp, validMask)
indices = find(validMask);
if isempty(indices)
    frequencyRun = zeros(0,1);
    cpRun = zeros(0,1);
    return
end
breaks = [0; find(diff(indices) > 1); numel(indices)];
lengths = diff(breaks);
[~, block] = max(lengths);
selected = indices(breaks(block)+1:breaks(block+1));
frequencyRun = frequency_Hz(selected);
cpRun = cp(selected);
end

function [maxAbsDiff, maxRelativeDiff] = differenceVsReference(data, reference)
if numel(data.frequency_Hz) ~= numel(reference.frequency_Hz) || ...
        any(abs(data.frequency_Hz - reference.frequency_Hz) > 10 * eps(max(reference.frequency_Hz)))
    maxAbsDiff = NaN;
    maxRelativeDiff = NaN;
    return
end
valid = data.validMask & reference.validMask & ...
    isfinite(data.phaseVelocity_mps) & isfinite(reference.phaseVelocity_mps);
if ~any(valid)
    maxAbsDiff = NaN;
    maxRelativeDiff = NaN;
    return
end
delta = abs(data.phaseVelocity_mps(valid) - reference.phaseVelocity_mps(valid));
maxAbsDiff = max(delta);
maxRelativeDiff = max(delta ./ max(abs(reference.phaseVelocity_mps(valid)), eps));
end

function summary = summarizeBenchmark(raw)
keys = unique(raw(:, {'Model','Case','Profile'}), 'rows', 'stable');
rows = repmat(emptySummaryRow(), height(keys), 1);
for i = 1:height(keys)
    mask = raw.Model == keys.Model(i) & raw.Case == keys.Case(i) & raw.Profile == keys.Profile(i);
    subset = raw(mask, :);
    row = emptySummaryRow();
    row.Model = keys.Model(i);
    row.Case = keys.Case(i);
    row.Profile = keys.Profile(i);
    row.MedianSeconds = median(subset.ElapsedSeconds);
    row.MinSeconds = min(subset.ElapsedSeconds);
    row.MaxSeconds = max(subset.ElapsedSeconds);
    row.ValidFraction = median(subset.ValidFraction);
    row.MaxRelativeJump = max(subset.MaxRelativeJump);
    row.MaxRelativeSecondDiff = max(subset.MaxRelativeSecondDiff);
    row.HighFrequencyMaxRelativeSecondDiff = max(subset.HighFrequencyMaxRelativeSecondDiff);
    row.HighFrequencyMedianRelativeSecondDiff = median(subset.HighFrequencyMedianRelativeSecondDiff, 'omitnan');
    row.MaxAbsCpDiffVsRobust_mps = max(subset.MaxAbsCpDiffVsRobust_mps);
    row.MaxRelativeCpDiffVsRobust = max(subset.MaxRelativeCpDiffVsRobust);
    rows(i) = row;
end
summary = struct2table(rows);

for i = 1:height(summary)
    ref = summary.Model == summary.Model(i) & summary.Case == summary.Case(i) & summary.Profile == "Robust";
    if any(ref)
        summary.SpeedupVsRobust(i) = summary.MedianSeconds(ref) / summary.MedianSeconds(i);
    else
        summary.SpeedupVsRobust(i) = NaN;
    end
end
end

function row = emptyRow()
row = struct( ...
    'Model', "", ...
    'Case', "", ...
    'Profile', "", ...
    'RunIndex', 0, ...
    'ElapsedSeconds', NaN, ...
    'OutputPoints', 0, ...
    'ValidFraction', NaN, ...
    'MaxRelativeJump', NaN, ...
    'MaxRelativeSecondDiff', NaN, ...
    'HighFrequencyMaxRelativeSecondDiff', NaN, ...
    'HighFrequencyMedianRelativeSecondDiff', NaN, ...
    'MaxAbsCpDiffVsRobust_mps', NaN, ...
    'MaxRelativeCpDiffVsRobust', NaN, ...
    'MATLABRelease', "", ...
    'Platform', "", ...
    'Commit', "");
end

function row = emptySummaryRow()
row = struct( ...
    'Model', "", ...
    'Case', "", ...
    'Profile', "", ...
    'MedianSeconds', NaN, ...
    'MinSeconds', NaN, ...
    'MaxSeconds', NaN, ...
    'SpeedupVsRobust', NaN, ...
    'ValidFraction', NaN, ...
    'MaxRelativeJump', NaN, ...
    'MaxRelativeSecondDiff', NaN, ...
    'HighFrequencyMaxRelativeSecondDiff', NaN, ...
    'HighFrequencyMedianRelativeSecondDiff', NaN, ...
    'MaxAbsCpDiffVsRobust_mps', NaN, ...
    'MaxRelativeCpDiffVsRobust', NaN);
end

function root = findRepositoryRoot(anchorFile)
folder = fileparts(anchorFile);
while true
    if isfile(fullfile(folder, 'startup.m'))
        root = folder;
        return
    end
    parent = fileparts(folder);
    if strcmp(parent, folder)
        error('benchmark:RepositoryRootNotFound', 'Could not locate repository root.');
    end
    folder = parent;
end
end

function sha = gitHead(repoRoot)
[status, output] = system(sprintf('git -C "%s" rev-parse HEAD', repoRoot));
if status == 0
    sha = strip(string(output));
else
    sha = "unknown";
end
end

function restoreSession(originalFolder, originalPath)
path(originalPath);
cd(originalFolder);
end

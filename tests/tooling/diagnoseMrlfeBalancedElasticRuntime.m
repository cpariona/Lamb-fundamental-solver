% TEMPORARY_DIAGNOSTIC
function summary = diagnoseMrlfeBalancedElasticRuntime(varargin)
%DIAGNOSEMRLFEBALANCEDELASTICRUNTIME Isolate Balanced elastic runtime overhead.

parser = inputParser;
parser.addParameter('Repeats', 3, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.parse(varargin{:});
repeats = parser.Results.Repeats;

frequency_Hz = linspace(1000, 6000, 10).';
profiles = ["fast", "balanced", "robust"];
rows = repmat(emptyRow(), 0, 1);

fprintf('\nmRLFE elastic tracker runtime diagnostic\n');
fprintf('========================================\n');

for profile = profiles
    request = buildRequest(frequency_Hz, profile);
    configuration = mrlfeResolveConfiguration(request);
    problem = mrlfeBuildProblem(configuration);
    options = configuration.internalOptions;
    mrlfeParams = options.mrlfeParams;
    mrlfeParams.etaS = 0;
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;
    [seed, ~] = mrlfeBuildSeed(problem, configuration);

    mrlfeTrackBranchAdaptive(problem, seed, configuration, mrlfeParams, options);
    mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, options);

    adaptiveTimes = nan(repeats,1);
    robustTimes = nan(repeats,1);
    adaptive = struct();
    robust = struct();
    for r = 1:repeats
        t = tic;
        adaptive = mrlfeTrackBranchAdaptive(problem, seed, configuration, mrlfeParams, options);
        adaptiveTimes(r) = toc(t);

        t = tic;
        robust = mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, options);
        robustTimes(r) = toc(t);
    end

    row = emptyRow();
    row.Profile = profile;
    row.SolvePoints = numel(problem.frequencySolve_Hz);
    row.CpScanPoints = options.trackerCpScanPoints;
    row.AdaptiveMedianSeconds = median(adaptiveTimes);
    row.RobustStartMedianSeconds = median(robustTimes);
    row.RuntimeRatioRobustVsAdaptive = row.RobustStartMedianSeconds / row.AdaptiveMedianSeconds;
    row.AdaptiveValidCount = nnz(adaptive.validCp);
    row.RobustValidCount = nnz(robust.validCp);
    row.AdaptiveHasRequiredRun = hasValidRun(adaptive.validCp, options.robustStartMinValidRun);
    row.RobustStartAttempted = robust.robustStart.Attempted;
    row.RobustStartApplied = robust.robustStart.Applied;
    row.ProbesAttempted = robust.robustStart.ProbesAttempted;
    row.StartFrequency_Hz = robust.robustStart.StartFrequency_Hz;
    row.MaxAbsCpDifference_mps = maxCpDifference(adaptive, robust);
    rows(end+1,1) = row; %#ok<AGROW>
end

summary = struct2table(rows);
disp(summary);
end

function request = buildRequest(frequency_Hz, preset)
defaults = mrlfeDefaultParameters();
publicOptions = mrlfeDefaultOptions();
request = struct();
request.branch = "A0Like";
request.frequency_Hz = frequency_Hz(:);
request.material = struct('mu_Pa', defaults.mu_Pa, 'etaS_Pas', 0, ...
    'rho_kgm3', defaults.rho_kgm3, 'nu', defaults.nu);
request.geometry = struct('thickness_m', defaults.thickness_m);
request.fluid = struct('density_kgm3', defaults.fluidDensity_kgm3, ...
    'soundSpeed_mps', defaults.fluidSoundSpeed_mps);
request.numerics = struct('preset', string(preset));
request.selection = publicOptions.selection;
request.termination = struct('policy', publicOptions.termination.A0Like);
request.fallback = publicOptions.fallback;
end

function tf = hasValidRun(validMask, requiredRun)
runLength = 0;
tf = false;
for i = 1:numel(validMask)
    if validMask(i)
        runLength = runLength + 1;
        if runLength >= requiredRun
            tf = true;
            return
        end
    else
        runLength = 0;
    end
end
end

function value = maxCpDifference(a, b)
valid = a.validCp(:) & b.validCp(:) & isfinite(a.Cp(:)) & isfinite(b.Cp(:));
if any(valid)
    value = max(abs(a.Cp(valid) - b.Cp(valid)));
else
    value = NaN;
end
end

function row = emptyRow()
row = struct( ...
    'Profile', "", ...
    'SolvePoints', 0, ...
    'CpScanPoints', 0, ...
    'AdaptiveMedianSeconds', NaN, ...
    'RobustStartMedianSeconds', NaN, ...
    'RuntimeRatioRobustVsAdaptive', NaN, ...
    'AdaptiveValidCount', 0, ...
    'RobustValidCount', 0, ...
    'AdaptiveHasRequiredRun', false, ...
    'RobustStartAttempted', false, ...
    'RobustStartApplied', false, ...
    'ProbesAttempted', 0, ...
    'StartFrequency_Hz', NaN, ...
    'MaxAbsCpDifference_mps', NaN);
end

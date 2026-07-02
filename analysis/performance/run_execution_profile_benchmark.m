function results = run_execution_profile_benchmark(varargin)
%RUN_EXECUTION_PROFILE_BENCHMARK Headless benchmark for current profile behavior.
%
% The benchmark records relative cost and quality signals. It intentionally
% avoids hard pass/fail thresholds because timings are hardware dependent.

p = inputParser;
addParameter(p, 'Repeats', 3, @(x)isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'WriteCsv', true, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'OutputFile', fullfile('analysis', 'performance', 'execution_profile_benchmark_results.csv'), ...
    @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

startup;
root = testRepositoryRoot();
profiles = ["Fast", "Balanced", "Robust"];
rows = {};

fprintf('MATLAB %s | %s\n', version, computer);
rows = [rows; benchmarkRayleighLamb(profiles, p.Results.Repeats)]; %#ok<AGROW>
rows = [rows; benchmarkMRLFE(p.Results.Repeats)]; %#ok<AGROW>
rows = [rows; benchmarkAE(profiles, p.Results.Repeats)]; %#ok<AGROW>
rows = [rows; benchmarkShortFits(p.Results.Repeats)]; %#ok<AGROW>

results = cell2table(rows, 'VariableNames', {'Model', 'Surface', 'Branch', ...
    'RequestedProfile', 'EffectiveProfile', 'Route', 'AtlasPreset', ...
    'RunIndex', 'ElapsedSeconds', 'ValidFraction', 'MaxJumpRelative', ...
    'MaxAbsCpDiffVsRobust_mps', 'OptionsSummary', 'MatlabVersion', 'Platform'});

if logical(p.Results.WriteCsv)
    outputFile = fullfile(root, char(p.Results.OutputFile));
    writetable(results, outputFile);
    fprintf('Wrote benchmark table to %s\n', outputFile);
end
end

function rows = benchmarkRayleighLamb(profiles, repeats)
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 12000;
params.numFrequencyPoints = 45;
params.frequencySpacing = "linspace";
branches = ["A0", "S0"];
rows = {};
reference = struct();
for iBranch = 1:numel(branches)
    branchName = branches(iBranch);
    robustOptions = rlDefaultOptions("Robust");
    robustOptions.computeA0 = branchName == "A0";
    robustOptions.computeS0 = branchName == "S0";
    robust = rlComputeFundamentalLambModes(params, robustOptions);
    reference.(char(branchName)) = extractCp(robust, branchName);
end
for iBranch = 1:numel(branches)
    branchName = branches(iBranch);
    for iProfile = 1:numel(profiles)
        profile = profiles(iProfile);
        for iRun = 1:repeats
            options = rlDefaultOptions(profile);
            options.computeA0 = branchName == "A0";
            options.computeS0 = branchName == "S0";
            t = tic;
            raw = rlComputeFundamentalLambModes(params, options);
            elapsed = toc(t);
            cp = extractCp(raw, branchName);
            rows(end+1, :) = makeRow("RL", "API", branchName, profile, options.robustness, ...
                "direct", "none", iRun, elapsed, validFraction(cp), maxRelativeJump(cp), ...
                maxAbsDiff(cp, reference.(char(branchName))), ...
                sprintf('gridInitial=%g; gridTracking=%g; jumpTol=%g', ...
                options.gridPointsInitial, options.gridPointsTracking, options.jumpTol)); %#ok<AGROW>
        end
    end
end
end

function rows = benchmarkMRLFE(repeats)
params = mrlfeDefaultSweepParams();
params.fmin = 1000;
params.fmax = 8000;
params.numFrequencyPoints = 18;
params.frequencySpacing = "linspace";
cases = struct( ...
    'Branch', {"A0Like", "A0Like", "S0Like", "S0Like"}, ...
    'EtaS', {0, 0.05, 0, 0.05});
rows = {};
for iCase = 1:numel(cases)
    for iRun = 1:repeats
        options = mrlfeDefaultSweepOptions(cases(iCase).Branch, 'EtaS', cases(iCase).EtaS, ...
            'UseUnifiedAtlasRoute', cases(iCase).EtaS > 0, 'A0Policy', "adaptivePhysicalTail");
        t = tic;
        [cp, raw] = mrlfeEvaluateFitModel(params, linspace(1000, 8000, 10).', cases(iCase).Branch, options);
        elapsed = toc(t);
        path = raw.evaluationPath.path;
        preset = raw.evaluationPath.fitAtlasPreset;
        rows(end+1, :) = makeRow("mRLFE", "API/Fit evaluator", cases(iCase).Branch, ...
            "Fast", string(options.robustness), path, preset, iRun, elapsed, ...
            validFraction(cp), maxRelativeJump(cp), NaN, ...
            sprintf('etaS=%g; atlasCpScanPoints=%g; A0Policy=%s', cases(iCase).EtaS, ...
            raw.fitPerformanceDefaults.atlasCpScanPoints, raw.evaluationPath.mrlfeA0Policy)); %#ok<AGROW>
    end
end
end

function rows = benchmarkAE(profiles, repeats)
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'IOP', 15 * 133.322, ...
    'mu', 64e3, 'k1', 50e3, 'k2', 200, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9);
frequency = logspace(log10(300), log10(15000), 24).';
rows = {};
reference = [];
for iProfile = 1:numel(profiles)
    if profiles(iProfile) == "Robust"
        options = aeDefaultSweepOptions("Robust");
        [reference, ~] = aeEvaluateFitModel(params, frequency, "atlasA0", options);
    end
end
for iProfile = 1:numel(profiles)
    profile = profiles(iProfile);
    for iRun = 1:repeats
        options = aeDefaultSweepOptions(profile);
        t = tic;
        [cp, raw] = aeEvaluateFitModel(params, frequency, "atlasA0", options);
        elapsed = toc(t);
        rows(end+1, :) = makeRow("AE", "API", "atlasA0", profile, profile, ...
            "atlasA0", "aeDefaultSweepOptions", iRun, elapsed, validFraction(cp), ...
            maxRelativeJump(cp), maxAbsDiff(cp, reference), ...
            sprintf('atlasNumYPoints=%g; atlasTopNMinima=%g; valid=%d/%d', ...
            options.atlasNumYPoints, options.atlasTopNMinima, nnz(raw.validMask), numel(raw.validMask))); %#ok<AGROW>
    end
end
end

function rows = benchmarkShortFits(repeats)
rows = {};
for iRun = 1:repeats
    rows(end+1, :) = runShortRLFit(iRun); %#ok<AGROW>
    rows(end+1, :) = runShortMRLFEFit(iRun); %#ok<AGROW>
    rows(end+1, :) = runShortAEFit(iRun); %#ok<AGROW>
end
end

function row = runShortRLFit(iRun)
params = rlDefaultParams();
frequency = linspace(1000, 6000, 6).';
cp = rlEvaluateFitModel(params, frequency, "A0", rlDefaultOptions("Fast"));
request = guiBuildFitRequest("rayleigh_lamb", 'branchName', "A0", 'mode', "basic", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', isfinite(cp)), ...
    'fixedParams', struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu), ...
    'freeParams', "mu", 'initialGuess', struct('mu', params.mu), ...
    'bounds', struct('mu', [20e3, 160e3]), 'controls', struct('robustness', "Fast"), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 2, 'MaxFunEvals', 5, 'TolX', 1e-4)));
t = tic; out = guiRunFit(request); elapsed = toc(t);
row = makeRow("RL", "Fit", "A0", "Fast", "Fast", "direct", "none", iRun, elapsed, ...
    1, NaN, NaN, sprintf('RMSE=%g; MaxIter=2; MaxFunEvals=5', out.normalized.metrics.RMSE));
end

function row = runShortMRLFEFit(iRun)
params = mrlfeDefaultSweepParams();
frequency = linspace(1000, 6000, 6).';
options = mrlfeDefaultSweepOptions("A0Like", 'EtaS', 0.0);
cp = mrlfeEvaluateFitModel(params, frequency, "A0Like", options);
request = guiBuildFitRequest("mrlfe", 'branchName', "A0Like", 'mode', "basic", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', isfinite(cp)), ...
    'fixedParams', struct('thickness', params.thickness, 'rho', params.rho, 'nu', params.nu, 'etaS', 0), ...
    'freeParams', "mu", 'initialGuess', struct('mu', params.mu), ...
    'bounds', struct('mu', [20e3, 160e3]), ...
    'controls', struct('robustness', "Fast", 'etaS', 0, 'fluidDensity', 1000, 'fluidSoundSpeed', 1500), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 2, 'MaxFunEvals', 5, 'TolX', 1e-4)));
t = tic; out = guiRunFit(request); elapsed = toc(t);
row = makeRow("mRLFE", "Fit", "A0Like", "Fast", "Fast", out.routePolicy.actualPath, ...
    out.routePolicy.fitAtlasPreset, iRun, elapsed, 1, NaN, NaN, ...
    sprintf('RMSE=%g; MaxIter=2; MaxFunEvals=5', out.normalized.metrics.RMSE));
end

function row = runShortAEFit(iRun)
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'IOP', 15 * 133.322, ...
    'mu', 64e3, 'k1', 50e3, 'k2', 200, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9);
frequency = logspace(log10(300), log10(6000), 8).';
options = aeDefaultSweepOptions("Fast");
[cp, raw] = aeEvaluateFitModel(params, frequency, "atlasA0", options);
request = guiBuildFitRequest("acoustoelastic_iop_hgo", 'branchName', "atlasA0", 'mode', "basic", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', raw.validMask), ...
    'fixedParams', rmfield(params, 'mu'), 'freeParams', "mu", ...
    'initialGuess', struct('mu', params.mu), 'bounds', struct('mu', [10e3, 150e3]), ...
    'controls', struct('robustness', "Fast", 'atlasNumYPoints', 300, 'atlasTopNMinima', 12, ...
    'atlasInitializationNumFrequencyPoints', 50), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
    'optimizerOptions', optimset('Display', 'off', 'MaxIter', 1, 'MaxFunEvals', 3, 'TolX', 1e-3)));
t = tic; out = guiRunFit(request); elapsed = toc(t);
row = makeRow("AE", "Fit", "atlasA0", "Fast", "Fast", "atlasA0", "300/12/50", ...
    iRun, elapsed, validFraction(cp), maxRelativeJump(cp), NaN, ...
    sprintf('RMSE=%g; MaxIter=1; MaxFunEvals=3', out.normalized.metrics.RMSE));
end

function cp = extractCp(raw, branchName)
cp = raw.modes.(char(branchName)).Cp(:);
end

function f = validFraction(cp)
cp = cp(:);
f = nnz(isfinite(cp) & cp > 0) / max(1, numel(cp));
end

function y = maxRelativeJump(cp)
cp = cp(:);
cp = cp(isfinite(cp) & cp > 0);
if numel(cp) < 2
    y = NaN;
else
    y = max(abs(diff(cp)) ./ max(abs(cp(1:end-1)), eps));
end
end

function d = maxAbsDiff(cp, ref)
valid = isfinite(cp(:)) & isfinite(ref(:));
if ~any(valid)
    d = NaN;
else
    d = max(abs(cp(valid) - ref(valid)));
end
end

function row = makeRow(model, surface, branchName, requestedProfile, effectiveProfile, route, ...
    atlasPreset, runIndex, elapsed, valid, maxJump, maxDiff, optionsSummary)
row = {string(model), string(surface), string(branchName), string(requestedProfile), ...
    string(effectiveProfile), string(route), string(atlasPreset), runIndex, elapsed, ...
    valid, maxJump, maxDiff, string(optionsSummary), string(version), string(computer)};
end

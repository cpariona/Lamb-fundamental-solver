function results = run_execution_profile_regression_smoke(varargin)
%RUN_EXECUTION_PROFILE_REGRESSION_SMOKE Short profile infrastructure benchmark.
%
% This smoke benchmark checks qualitative profile behavior without hardware-
% dependent thresholds. It is intended for PR validation, not performance
% baselining.

p = inputParser;
addParameter(p, 'WriteCsv', false, @(x)islogical(x) || isnumeric(x));
addParameter(p, 'OutputFile', fullfile('analysis', 'performance', 'execution_profile_regression_smoke.csv'), ...
    @(x)ischar(x) || isstring(x));
parse(p, varargin{:});

startup;
rows = {};
rows(end+1, :) = benchmarkRL(); %#ok<AGROW>
rows(end+1, :) = benchmarkMRLFE(); %#ok<AGROW>
rows(end+1, :) = benchmarkAE(); %#ok<AGROW>
rows(end+1, :) = benchmarkAEFit(); %#ok<AGROW>

results = cell2table(rows, 'VariableNames', ...
    {'Model', 'CaseName', 'RequestedProfile', 'EffectiveProfile', ...
    'InternalPreset', 'ElapsedSeconds', 'ValidFraction', 'MetadataOK'});

if logical(p.Results.WriteCsv)
    writetable(results, fullfile(testRepositoryRoot(), char(p.Results.OutputFile)));
end

disp(results);
end

function row = benchmarkRL()
params = rlDefaultParams();
params.fmin = 1000;
params.fmax = 4000;
params.numFrequencyPoints = 10;
params.frequencySpacing = "linspace";
[options, metadata] = rlResolveExecutionProfile("Fast");
options.computeA0 = true;
options.computeS0 = false;
t = tic;
raw = rlComputeFundamentalLambModes(params, options);
elapsed = toc(t);
cp = raw.modes.A0.Cp(:);
metadataOK = metadata.requestedExecutionProfile == "Fast" && ...
    metadata.effectiveExecutionProfile == "Fast" && ...
    options.gridPointsInitial == rlDefaultOptions("Fast").gridPointsInitial;
row = makeRow("RL", "A0 short", metadata, metadata.internalSolverPreset, elapsed, cp, metadataOK);
end

function row = benchmarkMRLFE()
params = mrlfeDefaultSweepParams();
frequency = linspace(1000, 4000, 5).';
[options, metadata] = mrlfeResolveExecutionProfile("A0Like", struct('executionProfile', "Robust"), ...
    'Surface', "fit", 'EtaS', 0, 'A0Policy', "physicalTail");
t = tic;
[cp, raw] = mrlfeEvaluateFitModel(params, frequency, "A0Like", options);
elapsed = toc(t);
metadata.internalAtlasPreset = raw.evaluationPath.fitAtlasPreset;
metadataOK = metadata.requestedExecutionProfile == "Robust" && ...
    metadata.effectiveExecutionProfile == "Fast" && ...
    raw.evaluationPath.fitAtlasPreset == "fast";
row = makeRow("mRLFE", raw.evaluationPath.path, metadata, metadata.internalAtlasPreset, elapsed, cp, metadataOK);
end

function row = benchmarkAE()
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'IOP', 15 * 133.322, ...
    'mu', 64e3, 'k1', 50e3, 'k2', 200, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9);
frequency = logspace(log10(300), log10(3000), 5).';
[options, metadata] = aeResolveExecutionProfile("Robust");
t = tic;
[cp, raw] = aeEvaluateFitModel(params, frequency, "atlasA0", options);
elapsed = toc(t);
metadataOK = metadata.requestedExecutionProfile == "Robust" && ...
    metadata.effectiveExecutionProfile == "Robust" && ...
    options.atlasNumYPoints == 900 && options.atlasTopNMinima == 20 && ...
    any(raw.validMask);
row = makeRow("AE", "atlasA0 short", metadata, metadata.internalAtlasPreset, elapsed, cp, metadataOK);
end

function row = benchmarkAEFit()
params = struct('R', 7.8e-3, 'thickness', 550e-6, 'IOP', 15 * 133.322, ...
    'mu', 64e3, 'k1', 50e3, 'k2', 200, 'rho', 1060, 'rhoF', 1000, ...
    'fluidBulkModulus', 2.2e9);
frequency = logspace(log10(300), log10(3000), 5).';
options = aeDefaultSweepOptions("Robust");
[cp, raw] = aeEvaluateFitModel(params, frequency, "atlasA0", options);
request = guiBuildFitRequest("acoustoelastic_iop_hgo", ...
    'branchName', "atlasA0", ...
    'experimental', struct('frequency_Hz', frequency, 'Cp_mps', cp, 'validMask', raw.validMask), ...
    'fixedParams', rmfield(params, 'mu'), ...
    'freeParams', "mu", ...
    'initialGuess', struct('mu', params.mu), ...
    'bounds', struct('mu', [10e3, 150e3]), ...
    'controls', struct('executionProfile', "Robust", 'atlasInitializationNumFrequencyPoints', 50), ...
    'fitOptions', struct('useStandardErrorWeights', false, ...
        'optimizerOptions', optimset('Display', 'off', 'MaxIter', 1, 'MaxFunEvals', 3, 'TolX', 1e-3)));
t = tic;
fitOutput = guiRunFit(request);
elapsed = toc(t);
metadata = fitOutput.executionProfile;
metadataOK = metadata.requestedExecutionProfile == "Robust" && ...
    metadata.effectiveExecutionProfile == "Robust" && ...
    metadata.atlasNumYPoints == 900 && metadata.atlasTopNMinima == 20 && ...
    ~metadata.profileOverrideApplied;
row = makeRow("AE Fit", "atlasA0 robust short", metadata, metadata.internalAtlasPreset, elapsed, cp, metadataOK);
end

function row = makeRow(model, caseName, metadata, preset, elapsed, cp, metadataOK)
row = {string(model), string(caseName), metadata.requestedExecutionProfile, ...
    metadata.effectiveExecutionProfile, string(preset), elapsed, validFraction(cp), logical(metadataOK)};
end

function value = validFraction(cp)
cp = cp(:);
value = nnz(isfinite(cp) & cp > 0) / max(1, numel(cp));
end

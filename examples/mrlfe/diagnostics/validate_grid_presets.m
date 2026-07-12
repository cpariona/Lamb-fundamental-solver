%% validate_grid_presets.m
% Validate candidate mRLFE frequency-grid steps against a dense reference.
%
% This validation uses the exact internal solve-frequency override supported
% by mrlfeBuildProblem. It does not modify public preset definitions.
%
% The requested output grid is identical for reference and candidate runs.
% Each candidate uses:
%   1. a fixed low-frequency grid when fmin < 500 Hz;
%   2. a constant step from 500 Hz to the requested fmax.
%
% The constant post-start step is maintained through the complete range so a
% viscous physical-tail cut receives the same nominal frequency resolution
% regardless of where the cut occurs.

clear; clc;
startup

%% Output
launchFolder = pwd;
outDir = fullfile(launchFolder, 'Results', 'mrlfe', 'grid_presets');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% Validation scope
% Use quickMode=true for the first local run. Set false for the full matrix.
quickMode = true;

if quickMode
    muValues_Pa = [25 75 158] * 1e3;
    etaSValues_Pas = [0 0.05];
    thicknessValues_m = 0.5e-3;
    fmaxValues_Hz = [16000 32000];
else
    muValues_Pa = [10 25 50 75 158] * 1e3;
    etaSValues_Pas = [0 0.01 0.05 0.10];
    thicknessValues_m = [0.3 0.5 0.8] * 1e-3;
    fmaxValues_Hz = [8000 16000 32000];
end

fmin_Hz = 10;
rho_kgm3 = 1070;
nu = 0.4999;
branchName = "A0Like";

% Fine reference used to resolve viscous termination location.
referenceStep_Hz = 10;

% Candidate constant steps after the fixed low-frequency grid.
candidateSteps_Hz = [20 25 30 40 50 75 100];

% Fixed low-frequency grid shared by all candidate presets.
lowGrid_Hz = [ ...
    10:10:100, ...
    125:25:250, ...
    300:50:500].';

% Output/reference comparison grid. It must be at least as fine as the
% reference solve grid so cut and curve comparisons are not output-limited.
outputStep_Hz = referenceStep_Hz;

% Preset acceptance targets. The final preset is the largest candidate step
% satisfying all applicable targets across the selected validation matrix.
targets = struct();
targets.fast = makeTargets(0.03, 0.08, 0.10, 0.05);
targets.balanced = makeTargets(0.015, 0.04, 0.05, 0.02);
targets.robust = makeTargets(0.0075, 0.02, 0.03, 0.01);

%% Run reference and candidate grids
results = table();
caseIndex = 0;
totalConditions = numel(muValues_Pa) * numel(etaSValues_Pas) * ...
    numel(thicknessValues_m) * numel(fmaxValues_Hz);

fprintf('\nExact mRLFE grid validation\n');
fprintf('Conditions: %d\n', totalConditions);
fprintf('Reference step: %g Hz\n', referenceStep_Hz);
fprintf('Candidate steps: %s Hz\n\n', mat2str(candidateSteps_Hz));

for imu = 1:numel(muValues_Pa)
    for ieta = 1:numel(etaSValues_Pas)
        for ih = 1:numel(thicknessValues_m)
            for ifmax = 1:numel(fmaxValues_Hz)
                caseIndex = caseIndex + 1;

                mu_Pa = muValues_Pa(imu);
                etaS_Pas = etaSValues_Pas(ieta);
                thickness_m = thicknessValues_m(ih);
                fmax_Hz = fmaxValues_Hz(ifmax);

                outputFrequency_Hz = makeUniformGrid(fmin_Hz, fmax_Hz, outputStep_Hz);
                referenceGrid_Hz = makeSolveGrid( ...
                    fmin_Hz, fmax_Hz, lowGrid_Hz, referenceStep_Hz);

                fprintf('[%d/%d] mu=%g kPa, etaS=%g Pa.s, h=%g mm, fmax=%g Hz\n', ...
                    caseIndex, totalConditions, mu_Pa/1e3, etaS_Pas, ...
                    thickness_m*1e3, fmax_Hz);

                reference = runCase( ...
                    outputFrequency_Hz, referenceGrid_Hz, branchName, ...
                    mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m);

                for candidateStep_Hz = candidateSteps_Hz
                    candidateGrid_Hz = makeSolveGrid( ...
                        fmin_Hz, fmax_Hz, lowGrid_Hz, candidateStep_Hz);
                    candidate = runCase( ...
                        outputFrequency_Hz, candidateGrid_Hz, branchName, ...
                        mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m);

                    metrics = compareCandidate(reference, candidate);
                    row = buildResultRow( ...
                        mu_Pa, etaS_Pas, thickness_m, fmin_Hz, fmax_Hz, ...
                        referenceStep_Hz, candidateStep_Hz, reference, ...
                        candidate, metrics);
                    results = [results; row]; %#ok<AGROW>
                end
            end
        end
    end
end

%% Summaries
summaryByStep = summarizeByStep(results);
presetSelection = selectPresetSteps(results, targets);
fmaxConsistency = summarizeFmaxConsistency(results);

%% Save
stamp = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
fullFile = fullfile(outDir, "grid_validation_full_" + stamp + ".csv");
stepFile = fullfile(outDir, "grid_validation_steps_" + stamp + ".csv");
presetFile = fullfile(outDir, "grid_validation_presets_" + stamp + ".csv");
consistencyFile = fullfile(outDir, "grid_validation_fmax_" + stamp + ".csv");
matFile = fullfile(outDir, "grid_validation_" + stamp + ".mat");

writetable(results, fullFile);
writetable(summaryByStep, stepFile);
writetable(presetSelection, presetFile);
writetable(fmaxConsistency, consistencyFile);
save(matFile, 'results', 'summaryByStep', 'presetSelection', ...
    'fmaxConsistency', 'targets', 'candidateSteps_Hz', ...
    'referenceStep_Hz', 'lowGrid_Hz');

fprintf('\nSummary by candidate step:\n');
disp(summaryByStep);
fprintf('\nCandidate preset selection:\n');
disp(presetSelection);
fprintf('\nSaved results in:\n%s\n', outDir);

%% Local functions
function targets = makeTargets(medianRelative, p95Relative, cutRelative, fmaxRelative)
targets = struct();
targets.maxMedianRelativeError = medianRelative;
targets.maxP95RelativeError = p95Relative;
targets.maxRelativeCutError = cutRelative;
targets.maxFmaxExtensionError = fmaxRelative;
end

function frequency_Hz = makeUniformGrid(fmin_Hz, fmax_Hz, step_Hz)
frequency_Hz = (fmin_Hz:step_Hz:fmax_Hz).';
if frequency_Hz(end) < fmax_Hz
    frequency_Hz(end+1,1) = fmax_Hz;
end
frequency_Hz = unique(frequency_Hz, 'sorted');
end

function frequency_Hz = makeSolveGrid(fmin_Hz, fmax_Hz, lowGrid_Hz, step_Hz)
low = lowGrid_Hz(lowGrid_Hz >= fmin_Hz & lowGrid_Hz <= min(500, fmax_Hz));
if fmax_Hz > 500
    highStart = max(500, fmin_Hz);
    high = (highStart:step_Hz:fmax_Hz).';
else
    high = zeros(0,1);
end
frequency_Hz = unique([fmin_Hz; low(:); high(:); fmax_Hz], 'sorted');
end

function run = runCase(outputFrequency_Hz, solveFrequency_Hz, branchName, ...
    mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m)

request = struct();
request.branch = branchName;
request.frequency_Hz = outputFrequency_Hz;
request.material = struct( ...
    'mu_Pa', mu_Pa, ...
    'etaS_Pas', etaS_Pas, ...
    'rho_kgm3', rho_kgm3, ...
    'nu', nu);
request.geometry = struct('thickness_m', thickness_m);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct( ...
    'preset', "dense", ...
    'frequencySolveOverride_Hz', solveFrequency_Hz);
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");

t = tic;
result = mrlfeSolve(request);
elapsed_s = toc(t);

run = struct();
run.frequency_Hz = result.frequency_Hz(:);
run.Cp_mps = result.phaseVelocity_mps(:);
run.validMask = logical(result.validMask(:));
run.elapsed_s = elapsed_s;
run.solvePointCount = numel(solveFrequency_Hz);
run.solveFrequency_Hz = solveFrequency_Hz(:);
run.lastValidFrequency_Hz = lastValidFrequency(result.frequency_Hz, result.validMask);
run.terminationApplied = logical(result.termination.applied);
run.terminationFrequency_Hz = NaN;
if run.terminationApplied && isfinite(result.termination.firstRejectedFrequency_Hz)
    run.terminationFrequency_Hz = result.termination.firstRejectedFrequency_Hz;
end
run.terminationReason = string(result.termination.reason);
run.qualityReason = string(result.quality.reason);
end

function frequency_Hz = lastValidFrequency(frequency, validMask)
frequency = frequency(:);
validMask = logical(validMask(:));
if any(validMask)
    frequency_Hz = frequency(find(validMask, 1, 'last'));
else
    frequency_Hz = NaN;
end
end

function metrics = compareCandidate(reference, candidate)
common = reference.validMask & candidate.validMask & ...
    isfinite(reference.Cp_mps) & isfinite(candidate.Cp_mps);

metrics = struct();
metrics.commonValidCount = nnz(common);
metrics.commonValidFraction = nnz(common) / max(nnz(reference.validMask), 1);
metrics.medianRelativeError = NaN;
metrics.p95RelativeError = NaN;
metrics.maxRelativeError = NaN;
metrics.cutComparisonEligible = reference.terminationApplied && candidate.terminationApplied;
metrics.relativeCutError = terminationError(reference, candidate);
metrics.terminationStateMatches = reference.terminationApplied == candidate.terminationApplied;
metrics.terminationReasonMatches = reference.terminationReason == candidate.terminationReason;

if any(common)
    scale = max(abs(reference.Cp_mps(common)), eps);
    relativeError = abs(candidate.Cp_mps(common) - reference.Cp_mps(common)) ./ scale;
    metrics.medianRelativeError = median(relativeError, 'omitnan');
    metrics.p95RelativeError = percentile(relativeError, 95);
    metrics.maxRelativeError = max(relativeError, [], 'omitnan');
end
end

function value = terminationError(reference, candidate)
if reference.terminationApplied && candidate.terminationApplied && ...
        isfinite(reference.terminationFrequency_Hz) && ...
        isfinite(candidate.terminationFrequency_Hz)
    value = abs(candidate.terminationFrequency_Hz - reference.terminationFrequency_Hz) / ...
        max(reference.terminationFrequency_Hz, eps);
else
    value = NaN;
end
end

function value = percentile(x, p)
x = sort(x(isfinite(x)));
if isempty(x)
    value = NaN;
    return;
end
position = 1 + (numel(x)-1) * p/100;
lo = floor(position);
hi = ceil(position);
if lo == hi
    value = x(lo);
else
    value = x(lo) + (position-lo) * (x(hi)-x(lo));
end
end

function row = buildResultRow(mu_Pa, etaS_Pas, thickness_m, fmin_Hz, ...
    fmax_Hz, referenceStep_Hz, candidateStep_Hz, reference, candidate, metrics)

row = table();
row.mu_Pa = mu_Pa;
row.mu_kPa = mu_Pa/1e3;
row.etaS_Pas = etaS_Pas;
row.thickness_m = thickness_m;
row.thickness_mm = thickness_m*1e3;
row.fmin_Hz = fmin_Hz;
row.fmax_Hz = fmax_Hz;
row.referenceStep_Hz = referenceStep_Hz;
row.candidateStep_Hz = candidateStep_Hz;
row.referencePointCount = reference.solvePointCount;
row.candidatePointCount = candidate.solvePointCount;
row.referenceElapsed_s = reference.elapsed_s;
row.candidateElapsed_s = candidate.elapsed_s;
row.speedup = reference.elapsed_s / max(candidate.elapsed_s, eps);
row.referenceLastValid_Hz = reference.lastValidFrequency_Hz;
row.candidateLastValid_Hz = candidate.lastValidFrequency_Hz;
row.referenceTerminationApplied = reference.terminationApplied;
row.candidateTerminationApplied = candidate.terminationApplied;
row.referenceTermination_Hz = reference.terminationFrequency_Hz;
row.candidateTermination_Hz = candidate.terminationFrequency_Hz;
row.cutComparisonEligible = metrics.cutComparisonEligible;
row.relativeCutError = metrics.relativeCutError;
row.commonValidCount = metrics.commonValidCount;
row.commonValidFraction = metrics.commonValidFraction;
row.medianRelativeError = metrics.medianRelativeError;
row.p95RelativeError = metrics.p95RelativeError;
row.maxRelativeError = metrics.maxRelativeError;
row.referenceTermination = reference.terminationReason;
row.candidateTermination = candidate.terminationReason;
row.terminationStateMatches = metrics.terminationStateMatches;
row.terminationReasonMatches = metrics.terminationReasonMatches;
row.referenceQuality = reference.qualityReason;
row.candidateQuality = candidate.qualityReason;
end

function summary = summarizeByStep(results)
[G, steps] = findgroups(results.candidateStep_Hz);
summary = table(steps, 'VariableNames', {'candidateStep_Hz'});
summary.caseCount = splitapply(@numel, results.candidateStep_Hz, G);
summary.cutEligibleCount = splitapply(@(x) nnz(x), results.cutComparisonEligible, G);
summary.medianElapsed_s = splitapply(@(x) median(x, 'omitnan'), results.candidateElapsed_s, G);
summary.medianSpeedup = splitapply(@(x) median(x, 'omitnan'), results.speedup, G);
summary.worstMedianRelativeError = splitapply(@finiteMax, results.medianRelativeError, G);
summary.worstP95RelativeError = splitapply(@finiteMax, results.p95RelativeError, G);
summary.worstRelativeCutError = splitapply(@finiteMaxOrNaN, results.relativeCutError, G);
summary.minimumCommonValidFraction = splitapply(@finiteMin, results.commonValidFraction, G);
summary.terminationStateMatchFraction = splitapply(@(x) mean(x), results.terminationStateMatches, G);
summary.terminationReasonMatchFraction = splitapply(@(x) mean(x), results.terminationReasonMatches, G);
summary = sortrows(summary, 'candidateStep_Hz');
end

function selection = selectPresetSteps(results, targets)
names = ["fast"; "balanced"; "robust"];
selection = table(names, 'VariableNames', {'preset'});
selection.selectedStep_Hz = NaN(height(selection), 1);
selection.passes = false(height(selection), 1);
selection.reason = strings(height(selection), 1);

for i = 1:height(selection)
    target = targets.(char(selection.preset(i)));
    steps = sort(unique(results.candidateStep_Hz), 'descend');
    chosen = NaN;
    for step = steps(:).'
        sub = results(results.candidateStep_Hz == step, :);
        eligibleCutErrors = sub.relativeCutError(sub.cutComparisonEligible);
        cutPasses = ~isempty(eligibleCutErrors) && ...
            all(eligibleCutErrors <= target.maxRelativeCutError);
        passes = all(sub.medianRelativeError <= target.maxMedianRelativeError) && ...
            all(sub.p95RelativeError <= target.maxP95RelativeError) && ...
            cutPasses && ...
            all(sub.commonValidFraction >= 0.95) && ...
            mean(sub.terminationStateMatches) >= 0.95 && ...
            mean(sub.terminationReasonMatches) >= 0.95;
        if passes
            chosen = step;
            break;
        end
    end
    selection.selectedStep_Hz(i) = chosen;
    selection.passes(i) = isfinite(chosen);
    if isfinite(chosen)
        selection.reason(i) = "largest candidate satisfying curve, termination-state, and observed-cut targets";
    else
        selection.reason(i) = "no candidate satisfied all applicable matrix targets";
    end
end
end

function consistency = summarizeFmaxConsistency(results)
% Compare candidate quality across requested fmax values. Stable steps should
% not degrade sharply merely because the output range is extended.
key = results(:, {'mu_Pa','etaS_Pas','thickness_m','candidateStep_Hz'});
[G, keys] = findgroups(key);
consistency = keys;
consistency.maxMedianErrorSpread = splitapply(@finiteRange, results.medianRelativeError, G);
consistency.maxCutErrorSpread = splitapply(@finiteRange, results.relativeCutError, G);
consistency.minCommonValidFraction = splitapply(@finiteMin, results.commonValidFraction, G);
consistency.terminationStateMatchFraction = splitapply(@(x) mean(x), results.terminationStateMatches, G);
end

function value = finiteMax(x)
x = x(isfinite(x));
if isempty(x), value = inf; else, value = max(x); end
end

function value = finiteMaxOrNaN(x)
x = x(isfinite(x));
if isempty(x), value = NaN; else, value = max(x); end
end

function value = finiteMin(x)
x = x(isfinite(x));
if isempty(x), value = NaN; else, value = min(x); end
end

function value = finiteRange(x)
x = x(isfinite(x));
if numel(x) < 2, value = 0; else, value = max(x)-min(x); end
end

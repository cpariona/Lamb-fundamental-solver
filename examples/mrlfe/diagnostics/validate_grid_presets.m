%% validate_grid_presets.m
% Validate candidate mRLFE frequency-grid steps against a fine reference.
%
% This diagnostic uses exact internal solve-frequency overrides and does not
% modify public preset definitions. Formal termination is the preferred tail
% metric. When formal termination is unavailable, the last valid frequency is
% used only for accepted solutions whose valid branch ends before fmax.

clear; clc;
addpath(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
startup;

%% Output
launchFolder = pwd;
outDir = fullfile(launchFolder, 'Results', 'mrlfe', 'grid_presets');
if ~exist(outDir, 'dir'), mkdir(outDir); end

%% Validation scope
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
referenceStep_Hz = 10;
candidateSteps_Hz = [20 25 30 40 50 75 100];
outputStep_Hz = referenceStep_Hz;
lowGrid_Hz = [10:10:100, 125:25:250, 300:50:500].';

targets.fast = makeTargets(0.03, 0.08, 0.10);
targets.balanced = makeTargets(0.015, 0.04, 0.05);
targets.robust = makeTargets(0.0075, 0.02, 0.03);

%% Run matrix
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

                fprintf('[%d/%d] mu=%g kPa, etaS=%g Pa.s, h=%g mm, fmax=%g Hz\n', ...
                    caseIndex, totalConditions, mu_Pa/1e3, etaS_Pas, ...
                    thickness_m*1e3, fmax_Hz);

                outputFrequency_Hz = makeUniformGrid(fmin_Hz, fmax_Hz, outputStep_Hz);
                referenceGrid_Hz = makeSolveGrid(fmin_Hz, fmax_Hz, lowGrid_Hz, referenceStep_Hz);
                reference = runCase(outputFrequency_Hz, referenceGrid_Hz, branchName, ...
                    mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m, outputStep_Hz, fmax_Hz);

                for candidateStep_Hz = candidateSteps_Hz
                    candidateGrid_Hz = makeSolveGrid(fmin_Hz, fmax_Hz, lowGrid_Hz, candidateStep_Hz);
                    candidate = runCase(outputFrequency_Hz, candidateGrid_Hz, branchName, ...
                        mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m, outputStep_Hz, fmax_Hz);
                    metrics = compareCandidate(reference, candidate);
                    results = [results; buildResultRow(mu_Pa, etaS_Pas, thickness_m, ...
                        fmin_Hz, fmax_Hz, referenceStep_Hz, candidateStep_Hz, ...
                        reference, candidate, metrics)]; %#ok<AGROW>
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
function target = makeTargets(medianRelative, p95Relative, tailRelative)
target.maxMedianRelativeError = medianRelative;
target.maxP95RelativeError = p95Relative;
target.maxRelativeTailError = tailRelative;
end

function frequency_Hz = makeUniformGrid(fmin_Hz, fmax_Hz, step_Hz)
frequency_Hz = (fmin_Hz:step_Hz:fmax_Hz).';
if frequency_Hz(end) < fmax_Hz, frequency_Hz(end+1,1) = fmax_Hz; end
frequency_Hz = unique(frequency_Hz, 'sorted');
end

function frequency_Hz = makeSolveGrid(fmin_Hz, fmax_Hz, lowGrid_Hz, step_Hz)
low = lowGrid_Hz(lowGrid_Hz >= fmin_Hz & lowGrid_Hz <= min(500, fmax_Hz));
if fmax_Hz > 500
    high = (max(500, fmin_Hz):step_Hz:fmax_Hz).';
else
    high = zeros(0,1);
end
frequency_Hz = unique([fmin_Hz; low(:); high(:); fmax_Hz], 'sorted');
end

function run = runCase(outputFrequency_Hz, solveFrequency_Hz, branchName, ...
    mu_Pa, etaS_Pas, rho_kgm3, nu, thickness_m, outputStep_Hz, fmax_Hz)
request.branch = branchName;
request.frequency_Hz = outputFrequency_Hz;
request.material = struct('mu_Pa', mu_Pa, 'etaS_Pas', etaS_Pas, ...
    'rho_kgm3', rho_kgm3, 'nu', nu);
request.geometry = struct('thickness_m', thickness_m);
request.fluid = struct('density_kgm3', 1000, 'soundSpeed_mps', 1500);
request.numerics = struct('preset', "dense", ...
    'frequencySolveOverride_Hz', solveFrequency_Hz);
request.selection = struct('strategy', "adaptive");
request.termination = struct('policy', "physicalTail");
request.fallback = struct('policy', "none");

t = tic;
result = mrlfeSolve(request);
run.elapsed_s = toc(t);
run.frequency_Hz = result.frequency_Hz(:);
run.Cp_mps = result.phaseVelocity_mps(:);
run.validMask = logical(result.validMask(:));
run.solvePointCount = numel(solveFrequency_Hz);
run.lastValidFrequency_Hz = lastValidFrequency(run.frequency_Hz, run.validMask);
run.terminationApplied = logical(result.termination.applied);
run.terminationFrequency_Hz = NaN;
if run.terminationApplied && isfinite(result.termination.firstRejectedFrequency_Hz)
    run.terminationFrequency_Hz = result.termination.firstRejectedFrequency_Hz;
end
run.terminationReason = string(result.termination.reason);
run.qualityReason = string(result.quality.reason);
run.qualityAccepted = run.qualityReason == "accepted";
run.observedTailEnd = run.qualityAccepted && ...
    isfinite(run.lastValidFrequency_Hz) && ...
    run.lastValidFrequency_Hz <= fmax_Hz - outputStep_Hz;
run.tailMetricEligible = run.terminationApplied || run.observedTailEnd;
if run.terminationApplied && isfinite(run.terminationFrequency_Hz)
    run.tailFrequency_Hz = run.terminationFrequency_Hz;
    run.tailMetricSource = "formalTermination";
elseif run.observedTailEnd
    run.tailFrequency_Hz = run.lastValidFrequency_Hz;
    run.tailMetricSource = "acceptedLastValid";
else
    run.tailFrequency_Hz = NaN;
    run.tailMetricSource = "none";
end
end

function frequency_Hz = lastValidFrequency(frequency, validMask)
if any(validMask)
    frequency_Hz = frequency(find(validMask, 1, 'last'));
else
    frequency_Hz = NaN;
end
end

function metrics = compareCandidate(reference, candidate)
common = reference.validMask & candidate.validMask & ...
    isfinite(reference.Cp_mps) & isfinite(candidate.Cp_mps);
metrics.commonValidCount = nnz(common);
metrics.commonValidFraction = nnz(common) / max(nnz(reference.validMask), 1);
metrics.medianRelativeError = NaN;
metrics.p95RelativeError = NaN;
metrics.maxRelativeError = NaN;
if any(common)
    relativeError = abs(candidate.Cp_mps(common) - reference.Cp_mps(common)) ./ ...
        max(abs(reference.Cp_mps(common)), eps);
    metrics.medianRelativeError = median(relativeError, 'omitnan');
    metrics.p95RelativeError = percentile(relativeError, 95);
    metrics.maxRelativeError = max(relativeError, [], 'omitnan');
end
metrics.tailComparisonEligible = reference.tailMetricEligible && candidate.tailMetricEligible;
metrics.relativeTailError = NaN;
if metrics.tailComparisonEligible
    metrics.relativeTailError = abs(candidate.tailFrequency_Hz - reference.tailFrequency_Hz) / ...
        max(reference.tailFrequency_Hz, eps);
end
metrics.tailStateMatches = reference.tailMetricEligible == candidate.tailMetricEligible;
metrics.terminationStateMatches = reference.terminationApplied == candidate.terminationApplied;
metrics.terminationReasonMatches = reference.terminationReason == candidate.terminationReason;
end

function value = percentile(x, p)
x = sort(x(isfinite(x)));
if isempty(x), value = NaN; return; end
position = 1 + (numel(x)-1) * p/100;
lo = floor(position); hi = ceil(position);
if lo == hi, value = x(lo); else, value = x(lo) + (position-lo)*(x(hi)-x(lo)); end
end

function row = buildResultRow(mu_Pa, etaS_Pas, thickness_m, fmin_Hz, ...
    fmax_Hz, referenceStep_Hz, candidateStep_Hz, reference, candidate, metrics)
row = table(mu_Pa, mu_Pa/1e3, etaS_Pas, thickness_m, thickness_m*1e3, ...
    fmin_Hz, fmax_Hz, referenceStep_Hz, candidateStep_Hz, ...
    reference.solvePointCount, candidate.solvePointCount, ...
    reference.elapsed_s, candidate.elapsed_s, ...
    reference.elapsed_s/max(candidate.elapsed_s, eps), ...
    reference.lastValidFrequency_Hz, candidate.lastValidFrequency_Hz, ...
    reference.terminationApplied, candidate.terminationApplied, ...
    reference.terminationFrequency_Hz, candidate.terminationFrequency_Hz, ...
    reference.observedTailEnd, candidate.observedTailEnd, ...
    reference.tailMetricEligible, candidate.tailMetricEligible, ...
    reference.tailFrequency_Hz, candidate.tailFrequency_Hz, ...
    reference.tailMetricSource, candidate.tailMetricSource, ...
    metrics.tailComparisonEligible, metrics.relativeTailError, ...
    metrics.commonValidCount, metrics.commonValidFraction, ...
    metrics.medianRelativeError, metrics.p95RelativeError, metrics.maxRelativeError, ...
    metrics.tailStateMatches, metrics.terminationStateMatches, ...
    metrics.terminationReasonMatches, reference.terminationReason, ...
    candidate.terminationReason, reference.qualityReason, candidate.qualityReason, ...
    'VariableNames', {'mu_Pa','mu_kPa','etaS_Pas','thickness_m','thickness_mm', ...
    'fmin_Hz','fmax_Hz','referenceStep_Hz','candidateStep_Hz', ...
    'referencePointCount','candidatePointCount','referenceElapsed_s', ...
    'candidateElapsed_s','speedup','referenceLastValid_Hz','candidateLastValid_Hz', ...
    'referenceTerminationApplied','candidateTerminationApplied', ...
    'referenceTermination_Hz','candidateTermination_Hz', ...
    'referenceObservedTailEnd','candidateObservedTailEnd', ...
    'referenceTailEligible','candidateTailEligible', ...
    'referenceTail_Hz','candidateTail_Hz','referenceTailSource', ...
    'candidateTailSource','tailComparisonEligible','relativeTailError', ...
    'commonValidCount','commonValidFraction','medianRelativeError', ...
    'p95RelativeError','maxRelativeError','tailStateMatches', ...
    'terminationStateMatches','terminationReasonMatches', ...
    'referenceTermination','candidateTermination','referenceQuality','candidateQuality'});
end

function summary = summarizeByStep(results)
[G, steps] = findgroups(results.candidateStep_Hz);
summary = table(steps, 'VariableNames', {'candidateStep_Hz'});
summary.caseCount = splitapply(@numel, results.candidateStep_Hz, G);
summary.tailEligibleCount = splitapply(@nnz, results.tailComparisonEligible, G);
summary.medianElapsed_s = splitapply(@(x) median(x, 'omitnan'), results.candidateElapsed_s, G);
summary.medianSpeedup = splitapply(@(x) median(x, 'omitnan'), results.speedup, G);
summary.worstMedianRelativeError = splitapply(@finiteMax, results.medianRelativeError, G);
summary.worstP95RelativeError = splitapply(@finiteMax, results.p95RelativeError, G);
summary.worstRelativeTailError = splitapply(@finiteMaxOrNaN, results.relativeTailError, G);
summary.minimumCommonValidFraction = splitapply(@finiteMin, results.commonValidFraction, G);
summary.tailStateMatchFraction = splitapply(@mean, results.tailStateMatches, G);
summary = sortrows(summary, 'candidateStep_Hz');
end

function selection = selectPresetSteps(results, targets)
names = ["fast"; "balanced"; "robust"];
selection = table(names, 'VariableNames', {'preset'});
selection.selectedStep_Hz = NaN(height(selection),1);
selection.passes = false(height(selection),1);
selection.reason = strings(height(selection),1);
for i = 1:height(selection)
    target = targets.(char(selection.preset(i)));
    for step = sort(unique(results.candidateStep_Hz), 'descend').'
        sub = results(results.candidateStep_Hz == step, :);
        tailErrors = sub.relativeTailError(sub.tailComparisonEligible);
        passes = all(sub.medianRelativeError <= target.maxMedianRelativeError) && ...
            all(sub.p95RelativeError <= target.maxP95RelativeError) && ...
            ~isempty(tailErrors) && all(tailErrors <= target.maxRelativeTailError) && ...
            all(sub.commonValidFraction >= 0.95) && ...
            mean(sub.tailStateMatches) >= 0.95;
        if passes
            selection.selectedStep_Hz(i) = step;
            selection.passes(i) = true;
            selection.reason(i) = "largest candidate satisfying curve, coverage, and accepted-tail targets";
            break;
        end
    end
    if ~selection.passes(i)
        selection.reason(i) = "no candidate satisfied all applicable matrix targets";
    end
end
end

function consistency = summarizeFmaxConsistency(results)
key = results(:, {'mu_Pa','etaS_Pas','thickness_m','candidateStep_Hz'});
[G, keys] = findgroups(key);
consistency = keys;
consistency.maxMedianErrorSpread = splitapply(@finiteRange, results.medianRelativeError, G);
consistency.maxTailErrorSpread = splitapply(@finiteRange, results.relativeTailError, G);
consistency.minCommonValidFraction = splitapply(@finiteMin, results.commonValidFraction, G);
consistency.tailStateMatchFraction = splitapply(@mean, results.tailStateMatches, G);
end

function value = finiteMax(x)
x = x(isfinite(x)); if isempty(x), value = inf; else, value = max(x); end
end
function value = finiteMaxOrNaN(x)
x = x(isfinite(x)); if isempty(x), value = NaN; else, value = max(x); end
end
function value = finiteMin(x)
x = x(isfinite(x)); if isempty(x), value = NaN; else, value = min(x); end
end
function value = finiteRange(x)
x = x(isfinite(x)); if numel(x)<2, value = 0; else, value = max(x)-min(x); end
end

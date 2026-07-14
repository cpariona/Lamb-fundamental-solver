clear; clc;
startup

fprintf('\nRunning targeted mRLFE grid validation...\n');
fprintf('-----------------------------------------\n');

cases = [ ...
    struct('label', "high_error_A0",      'mu_Pa', 10e3, 'etaS_Pas', 0.10, 'thickness_m', 0.8e-3, 'fmax_Hz', 8000)
    struct('label', "quality_flip_A0",    'mu_Pa', 10e3, 'etaS_Pas', 0.05, 'thickness_m', 0.8e-3, 'fmax_Hz', 8000)
    struct('label', "tail_flip_low_mu",   'mu_Pa', 25e3, 'etaS_Pas', 0.10, 'thickness_m', 0.3e-3, 'fmax_Hz', 16000)
    struct('label', "tail_flip_mid_mu",   'mu_Pa', 50e3, 'etaS_Pas', 0.05, 'thickness_m', 0.5e-3, 'fmax_Hz', 16000)
];

referenceStep_Hz = 10;
candidateSteps_Hz = [20 25];
fmin_Hz = 10;
rows = struct([]);
outDir = fullfile('analysis_output', 'mrlfe_targeted_grid_validation');
if ~isfolder(outDir)
    mkdir(outDir);
end

for iCase = 1:numel(cases)
    c = cases(iCase);
    frequencyOutput_Hz = buildCoveredGrid(fmin_Hz, c.fmax_Hz, referenceStep_Hz);

    params = mrlfeDefaultSweepParams();
    params.mu = c.mu_Pa;
    params.etaS = c.etaS_Pas;
    params.thickness = c.thickness_m;
    params.rho = 1070;
    params.nu = 0.4999;

    options = mrlfeDefaultSweepOptions("A0Like", 'EtaS', c.etaS_Pas, ...
        'A0Policy', "physicalTail");
    options.executionProfile = "Fast";
    options.effectiveExecutionProfile = "Fast";
    options.robustness = "Fast";

    referenceRequest = mrlfeBuildFitSolveRequest(params, frequencyOutput_Hz, "A0Like", options);
    referenceRequest.numerics.preset = "fast";
    referenceRequest.numerics.frequencySolveOverride_Hz = ...
        buildCoveredGrid(fmin_Hz, c.fmax_Hz, referenceStep_Hz);
    t = tic;
    reference = mrlfeSolve(referenceRequest);
    referenceElapsed_s = toc(t);

    fig = figure('Visible', 'off');
    plot(reference.frequency_Hz / 1e3, reference.phaseVelocity_mps, '-', ...
        'DisplayName', sprintf('Reference %g Hz', referenceStep_Hz));
    hold on; grid on;

    for candidateStep_Hz = candidateSteps_Hz
        candidateRequest = mrlfeBuildFitSolveRequest(params, frequencyOutput_Hz, "A0Like", options);
        candidateRequest.numerics.preset = "fast";
        candidateRequest.numerics.frequencySolveOverride_Hz = ...
            buildCoveredGrid(fmin_Hz, c.fmax_Hz, candidateStep_Hz);
        t = tic;
        candidate = mrlfeSolve(candidateRequest);
        candidateElapsed_s = toc(t);

        validReference = logical(reference.validMask(:)) & isfinite(reference.phaseVelocity_mps(:));
        validCandidate = logical(candidate.validMask(:)) & isfinite(candidate.phaseVelocity_mps(:));
        commonValid = validReference & validCandidate;
        relativeError = nan(size(commonValid));
        relativeError(commonValid) = abs(candidate.phaseVelocity_mps(commonValid) - ...
            reference.phaseVelocity_mps(commonValid)) ./ ...
            max(abs(reference.phaseVelocity_mps(commonValid)), eps);

        row = struct();
        row.caseLabel = c.label;
        row.mu_kPa = c.mu_Pa / 1e3;
        row.etaS_Pas = c.etaS_Pas;
        row.thickness_mm = c.thickness_m * 1e3;
        row.fmax_Hz = c.fmax_Hz;
        row.referenceStep_Hz = referenceStep_Hz;
        row.candidateStep_Hz = candidateStep_Hz;
        row.referenceElapsed_s = referenceElapsed_s;
        row.candidateElapsed_s = candidateElapsed_s;
        row.speedup = referenceElapsed_s / max(candidateElapsed_s, eps);
        row.commonValidFraction = nnz(commonValid) / max(nnz(validReference), 1);
        row.validMaskDifferences = nnz(validReference ~= validCandidate);
        row.medianRelativeError = median(relativeError, 'omitnan');
        row.p95RelativeError = percentile(relativeError, 95);
        row.maxRelativeError = max(relativeError, [], 'omitnan');
        row.referenceLastValid_Hz = lastValidFrequency(reference);
        row.candidateLastValid_Hz = lastValidFrequency(candidate);
        row.referenceTerminationPolicy = string(reference.termination.policy);
        row.candidateTerminationPolicy = string(candidate.termination.policy);
        row.referenceTerminationApplied = logical(reference.termination.applied);
        row.candidateTerminationApplied = logical(candidate.termination.applied);
        row.referenceQuality = qualityLabel(reference);
        row.candidateQuality = qualityLabel(candidate);
        rows(end + 1) = row; %#ok<SAGROW>

        plot(candidate.frequency_Hz / 1e3, candidate.phaseVelocity_mps, '--', ...
            'DisplayName', sprintf('Candidate %g Hz', candidateStep_Hz));

        fprintf('%-18s | %2g Hz | p95 %.4g | max %.4g | mask diff %d | %s -> %s\n', ...
            c.label, candidateStep_Hz, row.p95RelativeError, row.maxRelativeError, ...
            row.validMaskDifferences, row.referenceQuality, row.candidateQuality);
    end

    xlabel('Frequency [kHz]');
    ylabel('Phase velocity [m/s]');
    title(sprintf('%s: \\mu=%.0f kPa, \\eta_s=%.2f Pa s, h=%.1f mm', ...
        c.label, c.mu_Pa / 1e3, c.etaS_Pas, c.thickness_m * 1e3), ...
        'Interpreter', 'tex');
    legend('Location', 'best');
    exportgraphics(fig, fullfile(outDir, c.label + ".png"), 'Resolution', 160);
    close(fig);
end

results = struct2table(rows);
stamp = string(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
outCsv = fullfile(outDir, "targeted_grid_validation_" + stamp + ".csv");
writetable(results, outCsv);

fprintf('\nSaved: %s\n', outCsv);
fprintf('Targeted mRLFE grid validation completed.\n');

function grid_Hz = buildCoveredGrid(fmin_Hz, fmax_Hz, step_Hz)
grid_Hz = (fmin_Hz:step_Hz:fmax_Hz).';
if isempty(grid_Hz) || grid_Hz(1) ~= fmin_Hz
    grid_Hz = [fmin_Hz; grid_Hz];
end
if grid_Hz(end) < fmax_Hz
    grid_Hz(end + 1, 1) = fmax_Hz;
elseif grid_Hz(end) > fmax_Hz
    grid_Hz(end) = fmax_Hz;
end
grid_Hz = unique(grid_Hz, 'sorted');
end

function value = percentile(x, p)
x = sort(x(isfinite(x)));
if isempty(x)
    value = nan;
    return;
end
index = 1 + (numel(x) - 1) * p / 100;
lo = floor(index);
hi = ceil(index);
if lo == hi
    value = x(lo);
else
    value = x(lo) + (index - lo) * (x(hi) - x(lo));
end
end

function value = lastValidFrequency(result)
valid = logical(result.validMask(:)) & isfinite(result.phaseVelocity_mps(:));
if any(valid)
    value = max(result.frequency_Hz(valid));
else
    value = nan;
end
end

function label = qualityLabel(result)
label = "unknown";
if ~isstruct(result.quality)
    return;
end
candidates = ["status", "label", "classification", "reason"];
for name = candidates
    if isfield(result.quality, name) && ~isempty(result.quality.(name))
        label = string(result.quality.(name));
        return;
    end
end
end
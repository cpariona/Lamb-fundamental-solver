function summary = diagnose_mrlfe_refinement_quantization(varargin)
%DIAGNOSE_MRLFE_REFINEMENT_QUANTIZATION Isolate Fast-grid Cp refinement effects.
%
% This diagnostic keeps the complete Fast mRLFE configuration fixed and changes
% only trackerRefineCandidates. It compares the discrete Fast tracker against
% the same tracker with bounded true-residual refinement enabled.
%
% This is diagnostic-only. It does not change production configuration.

parser = inputParser;
parser.addParameter('Repeats', 3, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

repoRoot = findRepositoryRoot(mfilename('fullpath'));
originalFolder = pwd;
originalPath = path;
cleanup = onCleanup(@() restoreSession(originalFolder, originalPath)); %#ok<NASGU>
cd(repoRoot);
startup;

frequency_Hz = (1000:50:8000).';
etaSValues = [0, 0.05];
rows = repmat(emptyRow(), 0, 1);
curves = struct();

fprintf('\nmRLFE refinement quantization diagnostic\n');
fprintf('========================================\n');
fprintf('Frequency grid: %.0f-%.0f Hz, %d requested points\n', ...
    frequency_Hz(1), frequency_Hz(end), numel(frequency_Hz));
fprintf('Fast preset is held fixed; only candidate refinement changes.\n\n');

for etaS = etaSValues
    caseName = regimeName(etaS);
    request = buildRequest(frequency_Hz, etaS);
    configuration = mrlfeResolveConfiguration(request);
    problem = mrlfeBuildProblem(configuration);
    baseOptions = configuration.internalOptions;
    mrlfeParams = baseOptions.mrlfeParams;
    mrlfeParams.etaS = etaS;
    mrlfeParams.solveComplexK = false;
    mrlfeParams.etaL = 0;
    mrlfeParams.useComplexLambda = false;

    [seed, ~] = mrlfeBuildSeed(problem, configuration);

    policies = ["discrete", "refineAll"];
    branches = struct();
    for policy = policies
        trackerOptions = baseOptions;
        trackerOptions.trackerRefineCandidates = policy == "refineAll";

        % Warm-up outside measured repetitions.
        warm = mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, trackerOptions);
        warm = mrlfeApplyTerminationPolicy(warm, seed, configuration); %#ok<NASGU>

        durations = nan(opt.Repeats, 1);
        branch = struct();
        for r = 1:opt.Repeats
            timer = tic;
            branch = mrlfeTrackBranchRobustStart(problem, seed, configuration, mrlfeParams, trackerOptions);
            branch = mrlfeApplyTerminationPolicy(branch, seed, configuration);
            durations(r) = toc(timer);
        end

        branches.(char(policy)) = branch;
        metrics = branchMetrics(branch);
        row = emptyRow();
        row.Case = caseName;
        row.Policy = policy;
        row.MedianSeconds = median(durations);
        row.MinSeconds = min(durations);
        row.MaxSeconds = max(durations);
        row.ValidFraction = metrics.validFraction;
        row.MaxRelativeJump = metrics.maxRelativeJump;
        row.MaxRelativeSecondDiff = metrics.maxRelativeSecondDiff;
        row.HighFrequencyMaxRelativeSecondDiff = metrics.highFrequencyMaxRelativeSecondDiff;
        row.HighFrequencyMedianRelativeSecondDiff = metrics.highFrequencyMedianRelativeSecondDiff;
        row.MedianApproxScanStep_mps = metrics.medianApproxScanStep_mps;
        row.MaxApproxScanStep_mps = metrics.maxApproxScanStep_mps;
        row.RefineCandidates = trackerOptions.trackerRefineCandidates;
        row.ScanPoints = trackerOptions.trackerCpScanPoints;
        rows(end+1,1) = row; %#ok<AGROW>
    end

    comparison = compareBranches(branches.discrete, branches.refineAll);
    curves.(char(caseName)) = comparison.curveTable;

    idxDiscrete = find([rows.Case] == caseName & [rows.Policy] == "discrete", 1, 'last');
    idxRefined = find([rows.Case] == caseName & [rows.Policy] == "refineAll", 1, 'last');
    rows(idxDiscrete).MaxAbsCpDifferenceBetweenPolicies_mps = comparison.maxAbsCpDifference_mps;
    rows(idxRefined).MaxAbsCpDifferenceBetweenPolicies_mps = comparison.maxAbsCpDifference_mps;
    rows(idxDiscrete).MedianAbsCpDifferenceBetweenPolicies_mps = comparison.medianAbsCpDifference_mps;
    rows(idxRefined).MedianAbsCpDifferenceBetweenPolicies_mps = comparison.medianAbsCpDifference_mps;
    rows(idxDiscrete).MedianDifferenceInApproxScanSteps = comparison.medianDifferenceInApproxScanSteps;
    rows(idxRefined).MedianDifferenceInApproxScanSteps = comparison.medianDifferenceInApproxScanSteps;
    rows(idxDiscrete).CandidateTypeMismatchCount = comparison.candidateTypeMismatchCount;
    rows(idxRefined).CandidateTypeMismatchCount = comparison.candidateTypeMismatchCount;
    rows(idxDiscrete).ValidMaskMismatchCount = comparison.validMaskMismatchCount;
    rows(idxRefined).ValidMaskMismatchCount = comparison.validMaskMismatchCount;
end

summary = struct2table(rows);
for caseName = unique(summary.Case).'
    iDiscrete = find(summary.Case == caseName & summary.Policy == "discrete", 1);
    iRefined = find(summary.Case == caseName & summary.Policy == "refineAll", 1);
    summary.RuntimeRatioVsDiscrete(iDiscrete) = 1;
    summary.RuntimeRatioVsDiscrete(iRefined) = summary.MedianSeconds(iRefined) / summary.MedianSeconds(iDiscrete);
    summary.HighFrequencyCurvatureRatioVsDiscrete(iDiscrete) = 1;
    summary.HighFrequencyCurvatureRatioVsDiscrete(iRefined) = ...
        safeRatio(summary.HighFrequencyMaxRelativeSecondDiff(iRefined), ...
        summary.HighFrequencyMaxRelativeSecondDiff(iDiscrete));
end

printSummary(summary);

if opt.WriteCsv
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'refinement_quantization');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'refinement_quantization_summary.csv'));
    caseNames = fieldnames(curves);
    for i = 1:numel(caseNames)
        writetable(curves.(caseNames{i}), fullfile(outputFolder, caseNames{i} + "_curves.csv"));
    end
    fprintf('\nSaved diagnostic output under Results/mrlfe/diagnostics/refinement_quantization\n');
end
end

function request = buildRequest(frequency_Hz, etaS)
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
request.numerics = struct('preset', "fast");
request.selection = publicOptions.selection;
request.termination = struct('policy', publicOptions.termination.A0Like);
request.fallback = publicOptions.fallback;
end

function metrics = branchMetrics(branch)
frequency = branch.frequency(:);
cp = branch.Cp(:);
valid = logical(branch.validCp(:)) & isfinite(cp) & cp > 0;
metrics = struct();
metrics.validFraction = nnz(valid) / max(1, numel(valid));

[fRun, cpRun] = longestValidRun(frequency, cp, valid);
[metrics.maxRelativeJump, metrics.maxRelativeSecondDiff] = shapeMetrics(cpRun);
if numel(fRun) >= 3
    threshold = fRun(1) + 0.60 * (fRun(end) - fRun(1));
    highCp = cpRun(fRun >= threshold);
    [~, metrics.highFrequencyMaxRelativeSecondDiff] = shapeMetrics(highCp);
    if numel(highCp) >= 3
        second = abs(diff(highCp, 2)) ./ max(abs(highCp(2:end-1)), eps);
        metrics.highFrequencyMedianRelativeSecondDiff = median(second, 'omitnan');
    else
        metrics.highFrequencyMedianRelativeSecondDiff = NaN;
    end
else
    metrics.highFrequencyMaxRelativeSecondDiff = NaN;
    metrics.highFrequencyMedianRelativeSecondDiff = NaN;
end

step = approximateScanStep(branch);
metrics.medianApproxScanStep_mps = median(step(isfinite(step)), 'omitnan');
metrics.maxApproxScanStep_mps = max(step(isfinite(step)), [], 'omitnan');
if isempty(step(isfinite(step)))
    metrics.medianApproxScanStep_mps = NaN;
    metrics.maxApproxScanStep_mps = NaN;
end
end

function step = approximateScanStep(branch)
center = branch.adaptiveCenterCp(:);
window = branch.adaptiveWindowUsed(:);
scanPoints = branch.dpOptions.cpScanPoints;
step = 2 .* abs(center) .* window ./ max(scanPoints - 1, 1);
step(~isfinite(center) | ~isfinite(window) | center <= 0 | window <= 0) = NaN;
end

function comparison = compareBranches(discrete, refined)
frequency = discrete.frequency(:);
if numel(frequency) ~= numel(refined.frequency) || any(frequency ~= refined.frequency(:))
    error('mrlfe:DiagnosticGridMismatch', 'Diagnostic branches must use identical solve grids.');
end
valid = discrete.validCp(:) & refined.validCp(:) & ...
    isfinite(discrete.Cp(:)) & isfinite(refined.Cp(:));
delta = nan(size(frequency));
delta(valid) = refined.Cp(valid) - discrete.Cp(valid);

scanStep = approximateScanStep(discrete);
deltaInSteps = abs(delta) ./ scanStep;
comparison.maxAbsCpDifference_mps = max(abs(delta(valid)), [], 'omitnan');
comparison.medianAbsCpDifference_mps = median(abs(delta(valid)), 'omitnan');
comparison.medianDifferenceInApproxScanSteps = median(deltaInSteps(valid & isfinite(deltaInSteps)), 'omitnan');
comparison.candidateTypeMismatchCount = nnz(string(discrete.candidateType(:)) ~= string(refined.candidateType(:)));
comparison.validMaskMismatchCount = nnz(logical(discrete.validCp(:)) ~= logical(refined.validCp(:)));
comparison.curveTable = table( ...
    frequency, discrete.Cp(:), refined.Cp(:), delta, scanStep, deltaInSteps, ...
    logical(discrete.validCp(:)), logical(refined.validCp(:)), ...
    string(discrete.candidateType(:)), string(refined.candidateType(:)), ...
    'VariableNames', {'Frequency_Hz','CpDiscrete_mps','CpRefinedAll_mps', ...
    'DeltaCp_mps','ApproxScanStep_mps','DeltaInApproxScanSteps', ...
    'ValidDiscrete','ValidRefinedAll','CandidateTypeDiscrete','CandidateTypeRefinedAll'});
end

function [maxJump, maxSecond] = shapeMetrics(cp)
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

function [frequencyRun, cpRun] = longestValidRun(frequency, cp, valid)
idx = find(valid);
if isempty(idx)
    frequencyRun = zeros(0,1);
    cpRun = zeros(0,1);
    return
end
breaks = [0; find(diff(idx) > 1); numel(idx)];
lengths = diff(breaks);
[~, block] = max(lengths);
selected = idx(breaks(block)+1:breaks(block+1));
frequencyRun = frequency(selected);
cpRun = cp(selected);
end

function value = safeRatio(numerator, denominator)
if ~isfinite(numerator) || ~isfinite(denominator) || denominator == 0
    value = NaN;
else
    value = numerator / denominator;
end
end

function printSummary(summary)
columns = {'Case','Policy','MedianSeconds','RuntimeRatioVsDiscrete','ValidFraction', ...
    'HighFrequencyMaxRelativeSecondDiff','HighFrequencyCurvatureRatioVsDiscrete', ...
    'MaxAbsCpDifferenceBetweenPolicies_mps','MedianDifferenceInApproxScanSteps', ...
    'CandidateTypeMismatchCount','ValidMaskMismatchCount'};
disp(summary(:, columns));
fprintf('\nInterpretation:\n');
fprintf('- Curvature ratio << 1 with small Cp shifts supports scan-grid quantization as the waviness source.\n');
fprintf('- Candidate/valid-mask mismatches indicate that refinement also changes branch decisions and needs deeper review.\n');
fprintf('- Runtime ratio measures the cost of refining all candidates; it is not the proposed final architecture.\n');
end

function name = regimeName(etaS)
if etaS == 0
    name = "elastic";
else
    name = "viscoelastic";
end
end

function row = emptyRow()
row = struct( ...
    'Case', "", ...
    'Policy', "", ...
    'MedianSeconds', NaN, ...
    'MinSeconds', NaN, ...
    'MaxSeconds', NaN, ...
    'RuntimeRatioVsDiscrete', NaN, ...
    'ValidFraction', NaN, ...
    'MaxRelativeJump', NaN, ...
    'MaxRelativeSecondDiff', NaN, ...
    'HighFrequencyMaxRelativeSecondDiff', NaN, ...
    'HighFrequencyMedianRelativeSecondDiff', NaN, ...
    'HighFrequencyCurvatureRatioVsDiscrete', NaN, ...
    'MedianApproxScanStep_mps', NaN, ...
    'MaxApproxScanStep_mps', NaN, ...
    'MaxAbsCpDifferenceBetweenPolicies_mps', NaN, ...
    'MedianAbsCpDifferenceBetweenPolicies_mps', NaN, ...
    'MedianDifferenceInApproxScanSteps', NaN, ...
    'CandidateTypeMismatchCount', NaN, ...
    'ValidMaskMismatchCount', NaN, ...
    'RefineCandidates', false, ...
    'ScanPoints', NaN);
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
        error('mrlfe:RepositoryRootNotFound', 'Could not locate repository root.');
    end
    folder = parent;
end
end

function restoreSession(originalFolder, originalPath)
path(originalPath);
cd(originalFolder);
end

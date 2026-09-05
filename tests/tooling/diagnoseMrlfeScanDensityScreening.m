% TEMPORARY_DIAGNOSTIC
function summary = diagnoseMrlfeScanDensityScreening(varargin)
%DIAGNOSEMRLFESCANDENSITYSCREENING Screen Fast mRLFE Cp-scan densities.

parser = inputParser;
parser.addParameter('Repeats', 2, @(x)isnumeric(x) && isscalar(x) && x >= 1 && fix(x) == x);
parser.addParameter('WriteCsv', true, @(x)islogical(x) && isscalar(x));
parser.parse(varargin{:});
opt = parser.Results;

scanValues = [100 140 180 220 260];
cases = screeningCases();
rows = repmat(emptyRow(), 0, 1);

fprintf('\nmRLFE Fast Cp-scan density screening\n');
fprintf('====================================\n');
fprintf('Scan points: %s\n\n', mat2str(scanValues));

for c = 1:height(cases)
    request = buildRequest(cases.Branch(c), cases.Mu_Pa(c), cases.EtaS_Pas(c));
    reference = runCase(request, 260, opt.Repeats);

    for scanPoints = scanValues
        if scanPoints == 260
            current = reference;
        else
            current = runCase(request, scanPoints, opt.Repeats);
        end

        cmp = compareRuns(current, reference);
        row = emptyRow();
        row.Case = cases.Case(c);
        row.Branch = cases.Branch(c);
        row.Mu_Pa = cases.Mu_Pa(c);
        row.EtaS_Pas = cases.EtaS_Pas(c);
        row.ScanPoints = scanPoints;
        row.MedianSeconds = current.medianSeconds;
        row.SpeedupVs260 = reference.medianSeconds / current.medianSeconds;
        row.MaxAbsCpDiffVs260_mps = cmp.maxAbsCp;
        row.MaxRelativeCpDiffVs260 = cmp.maxRelCp;
        row.ValidMaskMismatchCount = cmp.validMaskMismatch;
        row.FiniteMaskMismatchCount = cmp.finiteMaskMismatch;
        row.CandidateTypeMismatchCount = cmp.candidateTypeMismatch;
        row.ValidFraction = nnz(current.result.validMask) / numel(current.result.validMask);
        row.InternalMaxRelativeSecondDiff = current.shape.maxSecond;
        row.InternalHFMaxRelativeSecondDiff = current.shape.hfMaxSecond;
        rows(end+1,1) = row; %#ok<AGROW>

        fprintf('%-16s %3d pts | %.3f s | %5.2fx | dCp %.3g | masks %d | types %d\n', ...
            row.Case, scanPoints, row.MedianSeconds, row.SpeedupVs260, ...
            row.MaxAbsCpDiffVs260_mps, row.ValidMaskMismatchCount, ...
            row.CandidateTypeMismatchCount);
    end
    fprintf('\n');
end

summary = struct2table(rows);
printAggregate(summary, scanValues);

if opt.WriteCsv
    repoRoot = findRepositoryRoot(mfilename('fullpath'));
    outputFolder = fullfile(repoRoot, 'Results', 'mrlfe', 'diagnostics', 'scan_density_screening');
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    writetable(summary, fullfile(outputFolder, 'mrlfe_scan_density_screening.csv'));
    fprintf('Saved Results/mrlfe/diagnostics/scan_density_screening/mrlfe_scan_density_screening.csv\n');
end
end

function cases = screeningCases()
Case = ["A0 soft elastic"; "A0 corner visc"; "A0 default visc"; "A0 stiff visc"; ...
        "S0 soft elastic"; "S0 corner visc"; "S0 default visc"; "S0 stiff visc"];
Branch = [repmat("A0Like",4,1); repmat("S0Like",4,1)];
Mu_Pa = [50e3; 50e3; 75e3; 250e3; 50e3; 50e3; 75e3; 250e3];
EtaS_Pas = [0; 0.10; 0.05; 0.10; 0; 0.10; 0.05; 0.10];
cases = table(Case, Branch, Mu_Pa, EtaS_Pas);
end

function out = runCase(request, scanPoints, repeats)
configuration = mrlfeResolveConfiguration(request);
configuration.internalOptions.trackerCpScanPoints = scanPoints;
problem = mrlfeBuildProblem(configuration);

% Warm-up.
raw = mrlfeSolveBranch(problem, configuration);
mrlfeBuildResult(configuration, raw, 0); %#ok<VUNUS>

times = nan(repeats,1);
for r = 1:repeats
    t = tic;
    raw = mrlfeSolveBranch(problem, configuration);
    times(r) = toc(t);
end
result = mrlfeBuildResult(configuration, raw, median(times));
shape = shapeMetrics(raw.branchSolve);
out = struct('result', result, 'raw', raw, 'medianSeconds', median(times), 'shape', shape);
end

function cmp = compareRuns(a, b)
cpA = a.result.phaseVelocity_mps(:);
cpB = b.result.phaseVelocity_mps(:);
finiteA = isfinite(cpA);
finiteB = isfinite(cpB);
finite = finiteA & finiteB;
if any(finite)
    delta = abs(cpA(finite) - cpB(finite));
    cmp.maxAbsCp = max(delta);
    cmp.maxRelCp = max(delta ./ max(abs(cpB(finite)), eps));
else
    cmp.maxAbsCp = NaN;
    cmp.maxRelCp = NaN;
end
cmp.validMaskMismatch = nnz(a.result.validMask(:) ~= b.result.validMask(:));
cmp.finiteMaskMismatch = nnz(finiteA ~= finiteB);

typeA = string(a.raw.branchSolve.candidateType(:));
typeB = string(b.raw.branchSolve.candidateType(:));
if numel(typeA) == numel(typeB)
    cmp.candidateTypeMismatch = nnz(typeA ~= typeB);
else
    cmp.candidateTypeMismatch = NaN;
end
end

function metrics = shapeMetrics(branch)
f = branch.frequency(:);
cp = branch.Cp(:);
valid = logical(branch.validCp(:)) & isfinite(cp) & cp > 0;
[f, cp] = longestValidRun(f, cp, valid);
metrics.maxSecond = relativeSecond(cp);
if numel(f) >= 3
    threshold = f(1) + 0.60 * (f(end) - f(1));
    metrics.hfMaxSecond = relativeSecond(cp(f >= threshold));
else
    metrics.hfMaxSecond = NaN;
end
end

function value = relativeSecond(cp)
cp = cp(:);
if numel(cp) < 3
    value = NaN;
else
    value = max(abs(diff(cp,2)) ./ max(abs(cp(2:end-1)), eps));
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

function request = buildRequest(branch, mu, etaS)
defaults = mrlfeDefaultParameters();
publicOptions = mrlfeDefaultOptions();
request = struct();
request.branch = branch;
request.frequency_Hz = linspace(1000,12000,20).';
request.material = struct('mu_Pa', mu, 'etaS_Pas', etaS, ...
    'rho_kgm3', defaults.rho_kgm3, 'nu', defaults.nu);
request.geometry = struct('thickness_m', defaults.thickness_m);
request.fluid = struct('density_kgm3', defaults.fluidDensity_kgm3, ...
    'soundSpeed_mps', defaults.fluidSoundSpeed_mps);
request.numerics = struct('preset', "fast");
request.selection = publicOptions.selection;
if branch == "A0Like"
    request.termination = struct('policy', publicOptions.termination.A0Like);
else
    request.termination = struct('policy', publicOptions.termination.S0Like);
end
request.fallback = publicOptions.fallback;
end

function printAggregate(summary, scanValues)
fprintf('Aggregate by scan density\n');
fprintf('-------------------------\n');
for scanPoints = scanValues
    s = summary(summary.ScanPoints == scanPoints,:);
    fprintf('%3d | median speedup %.2fx | max dCp %.6g m/s | mask mismatches %d | type mismatches %d\n', ...
        scanPoints, median(s.SpeedupVs260), max(s.MaxAbsCpDiffVs260_mps), ...
        sum(s.ValidMaskMismatchCount), sum(s.CandidateTypeMismatchCount));
end
end

function row = emptyRow()
row = struct('Case',"", 'Branch',"", 'Mu_Pa',NaN, 'EtaS_Pas',NaN, ...
    'ScanPoints',0, 'MedianSeconds',NaN, 'SpeedupVs260',NaN, ...
    'MaxAbsCpDiffVs260_mps',NaN, 'MaxRelativeCpDiffVs260',NaN, ...
    'ValidMaskMismatchCount',0, 'FiniteMaskMismatchCount',0, ...
    'CandidateTypeMismatchCount',0, 'ValidFraction',NaN, ...
    'InternalMaxRelativeSecondDiff',NaN, 'InternalHFMaxRelativeSecondDiff',NaN);
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
